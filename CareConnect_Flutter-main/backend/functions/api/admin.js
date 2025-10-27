const express = require("express")
const router = express.Router()
const { auth, db, FieldValue } = require("../config/firebase")
const { verifyToken, optionalAuth } = require("../middleware/auth")

// Secure admin elevation using a one-time setup key
// Requires: Authorization Bearer ID token and header x-setup-key
router.post("/elevate", verifyToken, async (req, res) => {
  try {
    const setupKey = req.headers["x-setup-key"]
    if (!setupKey) {
      return res.status(400).json({ error: "Missing x-setup-key" })
    }

    const expected = process.env.ADMIN_SETUP_KEY
    if (!expected || setupKey !== expected) {
      return res.status(403).json({ error: "Invalid setup key" })
    }

    const uid = req.user && req.user.uid
    if (!uid) {
      return res.status(401).json({ error: "Unauthorized" })
    }

    await auth.setCustomUserClaims(uid, { admin: true })

    // Force token refresh on client after elevation
    res.json({ ok: true, message: "Admin claim set. Please re-login." })
  } catch (error) {
    console.error("Admin elevation error:", error)
    res.status(500).json({ error: "Internal error" })
  }
})

// Provision a new admin user using setup key only (no token yet)
router.post("/provision", async (req, res) => {
  try {
    const setupKey = req.headers["x-setup-key"]
    if (!setupKey) {
      return res.status(400).json({ error: "Missing x-setup-key" })
    }

    const expected = process.env.ADMIN_SETUP_KEY
    if (!expected || setupKey !== expected) {
      return res.status(403).json({ error: "Invalid setup key" })
    }

    const { email, password } = req.body || {}
    if (!email) {
      return res.status(400).json({ error: "Missing email" })
    }

    let userRecord
    try {
      userRecord = await auth.getUserByEmail(email)
    } catch (e) {
      if (e.code === "auth/user-not-found") {
        userRecord = null
      } else {
        throw e
      }
    }

    let created = false
    let finalPassword = password
    if (!userRecord) {
      // Generate a temporary password if not provided
      if (!finalPassword) {
        finalPassword = `CareConnect!Admin${Math.floor(100000 + Math.random() * 900000)}`
      }
      userRecord = await auth.createUser({
        email,
        password: finalPassword,
        displayName: "Administrator",
        emailVerified: false,
        disabled: false,
      })
      created = true
    } else if (finalPassword) {
      // Optionally reset password if provided
      await auth.updateUser(userRecord.uid, { password: finalPassword })
    }

    // Set custom claim admin: true
    await auth.setCustomUserClaims(userRecord.uid, { admin: true })

    res.json({
      ok: true,
      created,
      uid: userRecord.uid,
      email,
      password: finalPassword || null,
      message: created
        ? "Admin user created. Sign in and refresh token to use admin features."
        : "User exists. Admin claim ensured. Sign in and refresh token to use admin features.",
    })
  } catch (error) {
    console.error("Admin provision error:", error)
    res.status(500).json({ error: "Internal error" })
  }
})

// Seed mock data: patients and auctions
router.post("/seed", optionalAuth, async (req, res) => {
  try {
    const setupKey = req.headers["x-setup-key"]
    const expected = process.env.ADMIN_SETUP_KEY
    const isSetupKeyValid = expected && setupKey === expected
    const isAdmin = req.user && req.user.admin

    if (!isSetupKeyValid && !isAdmin) {
      return res.status(403).json({ error: "Forbidden - Admin or valid setup key required" })
    }

    const { patients = 5, auctions = 3 } = req.body || {}

    // Create mock patients
    const patientTemplates = [
      {
        name: "Juan D.",
        age: 12,
        diagnosis: "Acute Lymphoblastic Leukemia",
        fundingGoal: 250000,
        currentFunding: 50000,
        priority: 9,
        impactStory: "Juan is bravely fighting ALL and needs help for chemo.",
      },
      {
        name: "Maria S.",
        age: 35,
        diagnosis: "Breast Cancer",
        fundingGoal: 300000,
        currentFunding: 120000,
        priority: 8,
        impactStory: "Maria is a mother of two undergoing treatment.",
      },
      {
        name: "Ramon P.",
        age: 47,
        diagnosis: "Liver Cancer",
        fundingGoal: 500000,
        currentFunding: 220000,
        priority: 7,
        impactStory: "Ramon seeks support for targeted therapy.",
      },
      {
        name: "Aly M.",
        age: 28,
        diagnosis: "Ovarian Cancer",
        fundingGoal: 350000,
        currentFunding: 150000,
        priority: 8,
        impactStory: "Aly is responding well; continued treatment is vital.",
      },
      {
        name: "Leo T.",
        age: 63,
        diagnosis: "Prostate Cancer",
        fundingGoal: 200000,
        currentFunding: 80000,
        priority: 6,
        impactStory: "Leo needs assistance for radiation therapy.",
      },
    ]

    const createdPatients = []
    for (let i = 0; i < patients; i++) {
      const tpl = patientTemplates[i % patientTemplates.length]
      const doc = {
        ...tpl,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }
      const ref = await db.collection("patients").add(doc)
      createdPatients.push(ref.id)

      // Also write de-identified version to public_patients for donor visibility
      const publicPatient = {
        anonymousId: `Patient #${ref.id.substring(0, 8).toUpperCase()}`,
        age: tpl.age,
        generalDiagnosis: tpl.diagnosis.split(" ")[0],
        fundingGoal: tpl.fundingGoal,
        currentFunding: tpl.currentFunding || 0,
        fundingProgress: ((tpl.currentFunding || 0) / tpl.fundingGoal) * 100,
        priority: tpl.priority || 5,
        impactStory: tpl.impactStory || "",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }
      await db.collection("public_patients").doc(ref.id).set(publicPatient)
    }

    // Create mock auctions
    const auctionTemplates = [
      {
        itemName: "Signed Jersey",
        itemDescription: "Basketball jersey signed by local star.",
        itemImageUrl: "",
        imageUrl: "",
        description: "Basketball jersey signed by local star.",
        startingBid: 2000,
        currentBid: 2000,
        targetBid: 20000,
        minBidIncrement: 0.1,
        status: "active",
      },
      {
        itemName: "Art Print",
        itemDescription: "Limited edition cancer awareness art print.",
        itemImageUrl: "",
        imageUrl: "",
        description: "Limited edition cancer awareness art print.",
        startingBid: 1500,
        currentBid: 1500,
        targetBid: 15000,
        minBidIncrement: 0.1,
        status: "active",
      },
      {
        itemName: "Gala Ticket",
        itemDescription: "VIP ticket to charity gala dinner.",
        itemImageUrl: "",
        imageUrl: "",
        description: "VIP ticket to charity gala dinner.",
        startingBid: 5000,
        currentBid: 5000,
        targetBid: 50000,
        minBidIncrement: 0.1,
        status: "active",
      },
    ]

    const createdAuctions = []
    for (let i = 0; i < auctions; i++) {
      const tpl = auctionTemplates[i % auctionTemplates.length]
      // Ensure fields match Flutter app expectations
      const start = new Date()
      const end = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) // +3 days
      const doc = {
        sellerId: "admin",
        itemName: tpl.itemName,
        itemDescription: tpl.itemDescription || tpl.description || tpl.itemName,
        itemImageUrl: tpl.itemImageUrl || "",
        imageUrl: tpl.imageUrl || tpl.itemImageUrl || "",
        description: tpl.description || tpl.itemDescription || tpl.itemName,
        bidCount: 0,
        targetBid: tpl.targetBid || (tpl.startingBid * 10),
        startingBid: tpl.startingBid,
        currentBid: tpl.currentBid,
        currentBidderId: null,
        startTime: start,
        endTime: end,
        status: tpl.status || "active",
        blockchainAuctionId: null,
        blockchainTxHash: null,
        createdAt: start,
        minBidIncrement: tpl.minBidIncrement || 0.1,
        tokenId: null,
      }
      const ref = await db.collection("auctions").add(doc)
      createdAuctions.push(ref.id)
    }

    res.json({
      ok: true,
      patientsCreated: createdPatients.length,
      patientIds: createdPatients,
      auctionsCreated: createdAuctions.length,
      auctionIds: createdAuctions,
    })
  } catch (error) {
    console.error("Admin seed error:", error)
    res.status(500).json({ error: "Internal error" })
  }
})

module.exports = router

/**
 * Backfill blockchain fields for existing auctions by creating them on-chain
 */
router.post("/auctions/backfill-blockchain", optionalAuth, async (req, res) => {
  try {
    const setupKey = req.headers["x-setup-key"]
    const expected = process.env.ADMIN_SETUP_KEY
    const isSetupKeyValid = expected && setupKey === expected
    const isAdmin = req.user && req.user.admin

    if (!isSetupKeyValid && !isAdmin) {
      return res.status(403).json({ error: "Forbidden - Admin or valid setup key required" })
    }

    const blockchainService = require("../blockchain/blockchain-service")
    const { web3, account } = require("../config/web3")

    const snapshot = await db.collection("auctions").where("blockchainAuctionId", "==", null).get()
    const updated = []
    for (const doc of snapshot.docs) {
      const auction = doc.data()

      let seller = auction.sellerId || ""
      try {
        if (!seller || !web3 || !web3.utils.isAddress(seller)) {
          seller = (account && account.address) || seller || ""
        }
      } catch (_) {
        seller = (account && account.address) || seller || ""
      }
      const startingBid = Number(auction.startingBid || 0)

      let startMs = Date.now()
      let endMs = startMs + 3 * 24 * 60 * 60 * 1000
      try {
        if (auction.startTime && typeof auction.startTime.toDate === "function") {
          startMs = auction.startTime.toDate().getTime()
        } else if (typeof auction.startTime === "number") {
          startMs = auction.startTime
        }
        if (auction.endTime && typeof auction.endTime.toDate === "function") {
          endMs = auction.endTime.toDate().getTime()
        } else if (typeof auction.endTime === "number") {
          endMs = auction.endTime
        }
      } catch (_) {}
      const durationSec = Math.max(0, Math.floor((endMs - startMs) / 1000))

      const itemName = auction.itemName || auction.description || ""
      const itemDescription = auction.itemDescription || auction.description || ""
      const itemImageUrl = auction.itemImageUrl || auction.imageUrl || ""
      const tokenURI = auction.tokenURI || ""

      try {
        const result = await blockchainService.createAuction(
          seller,
          startingBid,
          durationSec,
          itemName,
          itemDescription,
          itemImageUrl,
          tokenURI,
        )

        await doc.ref.update({
          blockchainAuctionId: result.auctionId,
          blockchainTxHash: result.txHash,
        })
        updated.push(doc.id)
      } catch (error) {
        console.error(`Backfill failed for auction ${doc.id}:`, error)
        await doc.ref.update({ blockchainError: String(error.message || error) })
      }
    }

    res.json({ ok: true, updatedCount: updated.length, updated })
  } catch (error) {
    console.error("Backfill blockchain error:", error)
    res.status(500).json({ error: "Internal error" })
  }
})