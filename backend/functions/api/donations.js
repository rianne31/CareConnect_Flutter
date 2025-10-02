const express = require("express")
const router = express.Router()
const { db, admin } = require("../config/firebase")
const { verifyToken, requireAuth, requireAdmin } = require("../middleware/auth")
const blockchainService = require("../blockchain/blockchain-service")

/**
 * Record fiat donation and write to blockchain
 */
router.post("/record-fiat", verifyToken, requireAuth, async (req, res) => {
  try {
    const { amount, currency, paymentMethod, externalTxId, patientId, isAnonymous } = req.body

    if (!amount || !currency || !externalTxId) {
      return res.status(400).json({ error: "Missing required fields" })
    }

    const userId = req.user.uid

    // Create donation record in Firestore
    const donationRef = await db.collection("donations").add({
      userId,
      amount,
      currency,
      paymentMethod,
      externalTxId,
      patientId: patientId || null,
      isAnonymous: isAnonymous || false,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      blockchainTxHash: null,
    })

    // Record on blockchain
    try {
      const txHash = await blockchainService.recordFiatDonation(
        userId,
        amount,
        currency,
        externalTxId,
        patientId || "",
        isAnonymous || false,
      )

      // Update with blockchain transaction hash
      await donationRef.update({
        status: "confirmed",
        blockchainTxHash: txHash,
        confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      })

      res.json({
        success: true,
        donationId: donationRef.id,
        blockchainTxHash: txHash,
      })
    } catch (blockchainError) {
      console.error("Blockchain recording error:", blockchainError)

      // Mark as failed but keep Firestore record
      await donationRef.update({
        status: "blockchain_failed",
        error: blockchainError.message,
      })

      res.status(500).json({
        error: "Donation recorded but blockchain transaction failed",
        donationId: donationRef.id,
      })
    }
  } catch (error) {
    console.error("Donation recording error:", error)
    res.status(500).json({ error: "Failed to record donation" })
  }
})

/**
 * Get user's donation history
 */
router.get("/history", verifyToken, requireAuth, async (req, res) => {
  try {
    const userId = req.user.uid

    const donationsSnapshot = await db
      .collection("donations")
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(100)
      .get()

    const donations = []
    donationsSnapshot.forEach((doc) => {
      donations.push({ id: doc.id, ...doc.data() })
    })

    res.json({ donations })
  } catch (error) {
    console.error("Error fetching donation history:", error)
    res.status(500).json({ error: "Failed to fetch donation history" })
  }
})

/**
 * Get donation by ID
 */
router.get("/:donationId", verifyToken, requireAuth, async (req, res) => {
  try {
    const { donationId } = req.params
    const userId = req.user.uid
    const isAdmin = req.user.admin || false

    const donationDoc = await db.collection("donations").doc(donationId).get()

    if (!donationDoc.exists) {
      return res.status(404).json({ error: "Donation not found" })
    }

    const donation = donationDoc.data()

    // Check authorization (owner or admin)
    if (donation.userId !== userId && !isAdmin) {
      return res.status(403).json({ error: "Forbidden" })
    }

    res.json({ id: donationDoc.id, ...donation })
  } catch (error) {
    console.error("Error fetching donation:", error)
    res.status(500).json({ error: "Failed to fetch donation" })
  }
})

/**
 * Get all donations (admin only)
 */
router.get("/", verifyToken, requireAdmin, async (req, res) => {
  try {
    const { limit = 50, status, startAfter } = req.query

    let query = db.collection("donations").orderBy("createdAt", "desc")

    if (status) {
      query = query.where("status", "==", status)
    }

    if (startAfter) {
      const startDoc = await db.collection("donations").doc(startAfter).get()
      query = query.startAfter(startDoc)
    }

    query = query.limit(Number.parseInt(limit))

    const snapshot = await query.get()
    const donations = []

    snapshot.forEach((doc) => {
      donations.push({ id: doc.id, ...doc.data() })
    })

    res.json({ donations, hasMore: donations.length === Number.parseInt(limit) })
  } catch (error) {
    console.error("Error fetching donations:", error)
    res.status(500).json({ error: "Failed to fetch donations" })
  }
})

/**
 * Verify blockchain transaction
 */
router.get("/:donationId/verify", verifyToken, requireAuth, async (req, res) => {
  try {
    const { donationId } = req.params

    const donationDoc = await db.collection("donations").doc(donationId).get()

    if (!donationDoc.exists) {
      return res.status(404).json({ error: "Donation not found" })
    }

    const donation = donationDoc.data()

    if (!donation.blockchainTxHash) {
      return res.status(400).json({ error: "No blockchain transaction found" })
    }

    // Verify on blockchain
    const verification = await blockchainService.verifyDonation(donation.blockchainTxHash)

    res.json({
      verified: verification.success,
      transaction: verification.transaction,
      blockNumber: verification.blockNumber,
      timestamp: verification.timestamp,
    })
  } catch (error) {
    console.error("Verification error:", error)
    res.status(500).json({ error: "Failed to verify donation" })
  }
})

module.exports = router
