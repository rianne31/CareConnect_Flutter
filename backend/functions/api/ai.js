const express = require("express")
const router = express.Router()
const { GoogleGenerativeAI } = require("@google/generative-ai")
const { verifyToken, requireAuth, requireAdmin } = require("../middleware/auth")
const { db, admin } = require("../config/firebase")
require("dotenv").config()

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY)

/**
 * AI Chatbot for donor support
 */
router.post("/chat", verifyToken, requireAuth, async (req, res) => {
  try {
    const { message, conversationHistory } = req.body
    const userId = req.user.uid

    if (!message) {
      return res.status(400).json({ error: "Message is required" })
    }

    // Get user context
    const userDoc = await db.collection("donors").doc(userId).get()
    const userData = userDoc.exists ? userDoc.data() : {}

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
- Encourage continued support for pediatric cancer patients`

    const model = genAI.getGenerativeModel({ model: "gemini-pro" })

    // Build conversation
    const chat = model.startChat({
      history: conversationHistory || [],
      generationConfig: {
        maxOutputTokens: 500,
        temperature: 0.7,
      },
    })

    const result = await chat.sendMessage(context + "\n\nUser: " + message)
    const response = result.response.text()

    // Save to chat history
    await db.collection("chat_history").doc(userId).collection("messages").add({
      message: message,
      response: response,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    })

    res.json({ response })
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

    const model = genAI.getGenerativeModel({ model: "gemini-pro" })
    const result = await model.generateContent(prompt)
    const response = result.response.text()

    // Parse JSON response
    const analysis = JSON.parse(response.replace(/```json\n?|\n?```/g, ""))

    // Save analysis
    await db.collection("patients").doc(patientId).update({
      aiPriorityAnalysis: analysis,
      aiAnalyzedAt: admin.firestore.FieldValue.serverTimestamp(),
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

    const model = genAI.getGenerativeModel({ model: "gemini-pro" })
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
