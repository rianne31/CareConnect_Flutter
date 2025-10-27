const express = require("express")
const router = express.Router()
const { GoogleGenerativeAI } = require("@google/generative-ai")
const { defineSecret } = require("firebase-functions/params")
const { verifyToken, requireAuth, requireAdmin, optionalAuth } = require("../middleware/auth")
const { db, admin, FieldValue } = require("../config/firebase")
require("dotenv").config()
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY")

/**
 * AI service health/status
 */
router.get("/health", async (req, res) => {
  try {
    let secretKey = null
    try {
      secretKey = await GEMINI_API_KEY.value()
    } catch (e) {
      secretKey = null
    }
    const envKey = process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY_LOCAL || null
    const key = secretKey || envKey

    const status = {
      hasSecret: !!secretKey,
      hasEnvKey: !!envKey,
      hasResolvedKey: !!key,
      keySource: secretKey ? "secret" : (process.env.GEMINI_API_KEY ? "env" : (process.env.GEMINI_API_KEY_LOCAL ? "env_local" : "none")),
      sdkInitOk: false,
      restPingOk: false,
      sdkError: null,
      restError: null,
      listModelsOk: false,
      listModelsCount: 0,
      listModelsSample: [],
      listError: null,
    }

    if (key) {
      try {
        const genAI = new GoogleGenerativeAI(key)
        const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" })
        // Tiny generation to validate SDK; avoid heavy tokens
        const result = await model.generateContent({ contents: [{ role: "user", parts: [{ text: "ping" }] }] })
        status.sdkInitOk = !!result?.response?.text()
      } catch (e) {
        status.sdkInitOk = false
        status.sdkError = e?.message || String(e)
      }

      try {
        const axios = require("axios")
        const url = `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${key}`
        const body = { contents: [{ role: "user", parts: [{ text: "ping" }] }] }
        const { data } = await axios.post(url, body)
        status.restPingOk = !!(data?.candidates?.length)
      } catch (e) {
        status.restPingOk = false
        status.restError = e?.response?.data || e?.message || String(e)
      }

      // Try listing models to see which are available for this key
      try {
        const axios = require("axios")
        let listUrl = `https://generativelanguage.googleapis.com/v1/models?key=${key}`
        let { data: listData } = await axios.get(listUrl)
        if (!listData?.models?.length) {
          // Fallback to v1beta
          listUrl = `https://generativelanguage.googleapis.com/v1beta/models?key=${key}`
          const resp = await axios.get(listUrl)
          listData = resp.data
        }
        status.listModelsOk = !!(listData?.models?.length)
        status.listModelsCount = listData?.models?.length || 0
        status.listModelsSample = (listData?.models || []).slice(0, 5).map(m => m.name)
      } catch (e) {
        status.listModelsOk = false
        status.listError = e?.response?.data || e?.message || String(e)
      }
    }

    res.json({ status })
  } catch (error) {
    res.status(500).json({ error: "Failed to report AI health" })
  }
})

/**
 * AI Chatbot for donor support
 */
router.post("/chat", optionalAuth, async (req, res) => {
  try {
    const { message, conversationId } = req.body
    const userId = req.user?.uid || null

    if (!message) {
      return res.status(400).json({ error: "Message is required" })
    }

    // Get user context (guarded so failures don't break chat)
    let userData = {}
    try {
      if (userId) {
        const userDoc = await db.collection("donors").doc(userId).get()
        userData = userDoc.exists ? userDoc.data() : {}
      }
    } catch (e) {
      console.warn("Failed to fetch user context; proceeding without it")
    }

    // Get conversation history if conversationId is provided
    let conversationHistory = []
    let currentConversationId = conversationId

    if (conversationId) {
      try {
        const historySnapshot = await db
          .collection("chat_conversations")
          .doc(conversationId)
          .collection("messages")
          .orderBy("timestamp", "asc")
          .limit(10) // Limit to last 10 messages for context
          .get()

        conversationHistory = historySnapshot.docs.map(doc => {
          const data = doc.data()
          return [
            { role: "user", parts: [{ text: data.message }] },
            { role: "model", parts: [{ text: data.response }] }
          ]
        }).flat()
      } catch (error) {
        console.log("No existing conversation found, starting new one")
      }
    }

    // Create new conversation ID if not provided
    if (!currentConversationId) {
      currentConversationId = db.collection("chat_conversations").doc().id
    }

    // Build context for AI
    const context = `You are a helpful assistant for CareConnect, a blockchain-powered donation platform for Cancer Warrior Foundation supporting pediatric cancer patients.

User context:
- Donor tier: ${userData.tier || "Bronze"}
- Total donated: ₱${userData.totalDonated || 0}
- Donation count: ${userData.donationCount || 0}

Your role:
- Answer questions about donations, auctions, and the platform
- Provide guidance on blockchain transactions and wallet setup
- Explain the donor loyalty program and benefits
- Offer personalized donation suggestions based on user history
- Be empathetic and supportive

Guidelines:
- Keep responses concise and helpful
- Use Philippine Peso (₱) for currency
- Mention blockchain transparency when relevant
- Encourage continued support for pediatric cancer patients
- Provide helpful suggestions for follow-up questions when appropriate`

    // Resolve Gemini API key at request time (secrets or env)
    // Resolve Gemini API key from Secret Manager at request time, with local fallback
    let secretKey = null
    try {
      secretKey = await GEMINI_API_KEY.value()
    } catch (e) {
      // In dev or if secret unavailable, we'll use local fallback
      secretKey = null
    }
    let key = secretKey || process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY_LOCAL

    const hasGeminiKey = !!key
    const genAI = hasGeminiKey ? new GoogleGenerativeAI(key) : null

    let aiResponse
    const buildFallback = (msg) => {
      const lower = msg.toLowerCase()
      if (lower.includes("donate") || lower.includes("payment")) {
        return `To donate, choose a payment method (GCash, PayMaya, or crypto like MATIC/USDC). You can select a patient to support and track impact transparently on-chain.`
      }
      if (lower.includes("auction") || lower.includes("nft")) {
        return `Auctions feature donated items and NFTs. You can bid, and winners are recorded on-chain for transparency. Ask to see current auctions.`
      }
      if (lower.includes("wallet") || lower.includes("blockchain")) {
        return `You can use a wallet (e.g., MetaMask) to donate crypto. Blockchain ensures transparent tracking of funds to patient cases.`
      }
      if (lower.includes("tier") || lower.includes("reward")) {
        return `Donor tiers (Bronze, Silver, Gold, etc.) unlock recognition and benefits. Tiers update based on your total support.`
      }
      if (lower.includes("patient")) {
        return `Patients are de-identified for privacy. You can browse cases, see funding goals, and donate directly to a patient.`
      }
      return `CareConnect helps pediatric cancer patients through transparent donations and auctions. Ask about donating, auctions, or donor tiers to get started.`
    }

    if (genAI) {
      try {
        const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" })

        // Build conversation
        const chat = model.startChat({
          history: conversationHistory,
          generationConfig: {
            maxOutputTokens: 500,
            temperature: 0.7,
          },
        })

        const result = await chat.sendMessage(context + "\n\nUser: " + message)
        aiResponse = result.response.text()
      } catch (modelError) {
        console.error("Gemini SDK error; attempting REST v1 fallback:", modelError)
        try {
          const axios = require("axios")
          const url = `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${key}`
          const body = {
            contents: [
              { role: "user", parts: [{ text: context + "\n\nUser: " + message }] }
            ],
          }
          const { data } = await axios.post(url, body)
          aiResponse = data?.candidates?.[0]?.content?.parts?.[0]?.text || JSON.stringify(data).slice(0, 500)
        } catch (restErr) {
          console.error("Gemini REST v1 error; using local fallback:", restErr?.response?.data || restErr)
          aiResponse = `Thanks for your message! (Local/dev fallback)\n\nYou said: "${message}".\n\n${buildFallback(message)}\n\nEnable GEMINI_API_KEY to get richer AI guidance.`
        }
      }
    } else {
      // Fallback response for local/dev when GEMINI_API_KEY is not set
      aiResponse = `Thanks for your message! (Local dev mode without AI)\n\nYou said: "${message}".\n\n${buildFallback(message)}\n\nIf you enable GEMINI_API_KEY, I’ll provide richer AI-powered guidance tailored to you.`
    }

    // Generate suggestions based on the response
    const suggestions = []
    if (message.toLowerCase().includes('donate') || message.toLowerCase().includes('help')) {
      suggestions.push("Show me patients who need help", "How do I make a donation?", "What payment methods do you accept?")
    } else if (message.toLowerCase().includes('auction') || message.toLowerCase().includes('nft')) {
      suggestions.push("Show me current auctions", "How do NFT auctions work?", "What items are available?")
    } else if (message.toLowerCase().includes('blockchain') || message.toLowerCase().includes('wallet')) {
      suggestions.push("How do I set up a wallet?", "What is blockchain transparency?", "How are transactions secured?")
    } else {
      suggestions.push("Tell me about CareConnect", "How can I help patients?", "Show me my donation history")
    }

    // Save to conversation history
    if (currentConversationId) {
      try {
        await db
          .collection("chat_conversations")
          .doc(currentConversationId)
          .collection("messages")
          .add({
            message: message,
            response: aiResponse,
            timestamp: FieldValue.serverTimestamp(),
            userId: userId,
          })
      } catch (writeErr) {
        console.warn("Failed to write chat message to Firestore; continuing", writeErr)
      }
    }

    // Update conversation metadata
    try {
      await db
        .collection("chat_conversations")
        .doc(currentConversationId)
        .set({
          userId: userId,
          lastMessage: message,
          lastResponse: aiResponse,
          lastUpdated: FieldValue.serverTimestamp(),
        }, { merge: true })
    } catch (metaErr) {
      console.warn("Failed to update conversation metadata; continuing", metaErr)
    }

    res.json({ 
      message: aiResponse,
      conversationId: currentConversationId,
      suggestions: suggestions.slice(0, 3) // Limit to 3 suggestions
    })
  } catch (error) {
    console.error("AI chat error:", error)
    res.status(500).json({ error: "Failed to process chat message" })
  }
})

/**
 * AI-powered patient priority analysis (admin only)
 */
router.post("/analyze-priority", verifyToken, requireAdmin, async (req, res) => {
  try {
    const { patientId } = req.body

    const patientDoc = await db.collection("patients").doc(patientId).get()

    if (!patientDoc.exists) {
      return res.status(404).json({ error: "Patient not found" })
    }

    const patient = patientDoc.data()

    const prompt = `Analyze the priority level for this pediatric cancer patient case:

Patient Information:
- Age: ${patient.age}
- Diagnosis: ${patient.diagnosis}
- Treatment stage: ${patient.treatmentStage}
- Funding goal: ₱${patient.fundingGoal}
- Current funding: ₱${patient.currentFunding || 0}
- Medical urgency: ${patient.medicalUrgency || "Not specified"}
- Family situation: ${patient.familySituation || "Not specified"}

Provide:
1. Priority score (1-10, where 10 is most urgent)
2. Brief justification (2-3 sentences)
3. Recommended actions

Format as JSON:
{
  "priorityScore": number,
  "justification": "string",
  "recommendedActions": ["action1", "action2"]
}`

    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" })
    const result = await model.generateContent(prompt)
    const response = result.response.text()

    // Parse JSON response
    const analysis = JSON.parse(response.replace(/```json\n?|\n?```/g, ""))

    // Save analysis
    await db.collection("patients").doc(patientId).update({
      aiPriorityAnalysis: analysis,
      aiAnalyzedAt: FieldValue.serverTimestamp(),
    })

    res.json({ analysis })
  } catch (error) {
    console.error("AI priority analysis error:", error)
    res.status(500).json({ error: "Failed to analyze priority" })
  }
})

/**
 * Personalized donation recommendations
 */
router.get("/donation-recommendations", verifyToken, requireAuth, async (req, res) => {
  try {
    const userId = req.user.uid

    // Get user donation history
    const donationsSnapshot = await db
      .collection("donations")
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(10)
      .get()

    const donations = []
    donationsSnapshot.forEach((doc) => donations.push(doc.data()))

    // Get user profile
    const userDoc = await db.collection("donors").doc(userId).get()
    const userData = userDoc.data() || {}

    const prompt = `Based on this donor's history, provide personalized donation recommendations:

Donor Profile:
- Total donated: ₱${userData.totalDonated || 0}
- Donation count: ${donations.length}
- Current tier: ${userData.tier || "Bronze"}
- Last donation: ${donations[0]?.createdAt || "Never"}
- Average donation: ₱${userData.totalDonated / donations.length || 0}

Provide 3 personalized recommendations with:
1. Suggested amount
2. Reason/motivation
3. Potential impact

Format as JSON array.`

    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" })
    const result = await model.generateContent(prompt)
    const response = result.response.text()

    const recommendations = JSON.parse(response.replace(/```json\n?|\n?```/g, ""))

    res.json({ recommendations })
  } catch (error) {
    console.error("Recommendation error:", error)
    res.status(500).json({ error: "Failed to generate recommendations" })
  }
})

module.exports = router
