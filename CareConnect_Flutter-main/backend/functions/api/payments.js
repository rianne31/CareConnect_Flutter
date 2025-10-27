const express = require("express")
const router = express.Router()
const axios = require("axios")
const { verifyToken, requireAuth } = require("../middleware/auth")
require("dotenv").config()
const admin = require("firebase-admin")
const db = admin.firestore()

/**
 * Create PayMaya payment
 */
router.post("/paymaya/create", verifyToken, requireAuth, async (req, res) => {
  try {
    const { amount, description, patientId } = req.body

    if (!amount || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" })
    }

    const paymentData = {
      totalAmount: {
        value: amount,
        currency: "PHP",
      },
      buyer: {
        firstName: req.user.name || "Donor",
        email: req.user.email,
      },
      items: [
        {
          name: description || "Donation to Cancer Warrior Foundation",
          quantity: 1,
          totalAmount: {
            value: amount,
            currency: "PHP",
          },
        },
      ],
      redirectUrl: {
        success: `${process.env.FRONTEND_URL}/donation/success`,
        failure: `${process.env.FRONTEND_URL}/donation/failed`,
        cancel: `${process.env.FRONTEND_URL}/donation/cancelled`,
      },
      requestReferenceNumber: `DON-${Date.now()}-${req.user.uid.substring(0, 8)}`,
      metadata: {
        userId: req.user.uid,
        patientId: patientId || null,
      },
    }

    const response = await axios.post(`${process.env.PAYMAYA_BASE_URL}/v1/checkouts`, paymentData, {
      headers: {
        Authorization: `Basic ${Buffer.from(process.env.PAYMAYA_PUBLIC_KEY + ":").toString("base64")}`,
        "Content-Type": "application/json",
      },
    })

    res.json({
      checkoutId: response.data.checkoutId,
      redirectUrl: response.data.redirectUrl,
    })
  } catch (error) {
    console.error("PayMaya payment creation error:", error.response?.data || error)
    res.status(500).json({ error: "Failed to create payment" })
  }
})

/**
 * PayMaya webhook
 */
router.post("/paymaya/webhook", async (req, res) => {
  try {
    const { id, status, totalAmount, requestReferenceNumber, metadata } = req.body

    if (status === "PAYMENT_SUCCESS") {
      // Record donation
      const donationData = {
        userId: metadata.userId,
        amount: totalAmount.value,
        currency: totalAmount.currency,
        paymentMethod: "paymaya",
        externalTxId: id,
        patientId: metadata.patientId,
        isAnonymous: false,
        status: "confirmed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }

      await db.collection("donations").add(donationData)

      // Trigger blockchain recording via Cloud Function
    }

    res.json({ success: true })
  } catch (error) {
    console.error("PayMaya webhook error:", error)
    res.status(500).json({ error: "Webhook processing failed" })
  }
})

/**
 * Create GCash payment
 */
router.post("/gcash/create", verifyToken, requireAuth, async (req, res) => {
  try {
    const { amount, description, patientId } = req.body

    if (!amount || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" })
    }

    // GCash payment implementation
    // This is a placeholder - actual implementation depends on GCash API

    const paymentData = {
      amount: amount,
      currency: "PHP",
      description: description || "Donation to Cancer Warrior Foundation",
      merchantId: process.env.GCASH_MERCHANT_ID,
      referenceNumber: `DON-${Date.now()}-${req.user.uid.substring(0, 8)}`,
      metadata: {
        userId: req.user.uid,
        patientId: patientId || null,
      },
    }

    // Make API call to GCash
    // const response = await axios.post(...)

    res.json({
      paymentId: "GCASH_" + Date.now(),
      redirectUrl: `${process.env.GCASH_BASE_URL}/checkout`,
    })
  } catch (error) {
    console.error("GCash payment creation error:", error)
    res.status(500).json({ error: "Failed to create payment" })
  }
})

module.exports = router
