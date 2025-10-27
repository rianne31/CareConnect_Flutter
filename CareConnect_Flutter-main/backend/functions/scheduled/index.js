const { onSchedule } = require("firebase-functions/v2/scheduler")
const { db, admin } = require("../config/firebase")
const blockchainService = require("../blockchain/blockchain-service")

/**
 * Finalize expired auctions every hour
 */
exports.finalizeExpiredAuctions = onSchedule({ schedule: "every 1 hours", region: "us-central1", serviceAccount: "careconn-79a46@appspot.gserviceaccount.com" }, async (context) => {
  try {
    const now = Date.now()

    const expiredAuctions = await db
      .collection("auctions")
      .where("status", "==", "active")
      .where("endTime", "<=", now)
      .get()

    console.log(`Found ${expiredAuctions.size} expired auctions`)

    for (const doc of expiredAuctions.docs) {
      const auction = doc.data()

      try {
        // Finalize on blockchain
        const txHash = await blockchainService.finalizeAuction(auction.blockchainAuctionId)

        // Update Firestore
        await doc.ref.update({
          status: "finalized",
          finalizedAt: admin.firestore.FieldValue.serverTimestamp(),
          finalizationTxHash: txHash,
        })

        console.log(`Finalized auction ${doc.id}`)
      } catch (error) {
        console.error(`Failed to finalize auction ${doc.id}:`, error)
      }
    }

    return null
  } catch (error) {
    console.error("Scheduled function error:", error)
    return null
  }
})

/**
 * Update donor tiers daily
 */
exports.updateDonorTiers = onSchedule({ schedule: "every 24 hours", region: "us-central1", serviceAccount: "careconn-79a46@appspot.gserviceaccount.com" }, async (context) => {
  try {
    const donors = await db.collection("donors").get()

    for (const doc of donors.docs) {
      const donor = doc.data()
      const totalDonated = donor.totalDonated || 0

      let newTier = "Bronze"
      if (totalDonated >= 50000) newTier = "Platinum"
      else if (totalDonated >= 20000) newTier = "Gold"
      else if (totalDonated >= 5000) newTier = "Silver"

      if (newTier !== donor.tier) {
        await doc.ref.update({
          tier: newTier,
          tierUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        })

        // Mint achievement badge for tier upgrade
        // await blockchainService.mintAchievementBadge(...)

        console.log(`Updated ${doc.id} to ${newTier} tier`)
      }
    }

    return null
  } catch (error) {
    console.error("Tier update error:", error)
    return null
  }
})

/**
 * Calculate donor retention metrics weekly
 */
exports.calculateDonorRetention = onSchedule({ schedule: "every sunday 00:00", region: "us-central1", serviceAccount: "careconn-79a46@appspot.gserviceaccount.com" }, async (context) => {
  try {
    const thirtyDaysAgo = Date.now() - 30 * 24 * 60 * 60 * 1000
    const sixtyDaysAgo = Date.now() - 60 * 24 * 60 * 60 * 1000

    // Active donors (donated in last 30 days)
    const activeDonors = await db.collection("donations").where("createdAt", ">=", thirtyDaysAgo).get()

    // At-risk donors (no donation in 30-60 days)
    const atRiskDonors = await db
      .collection("donations")
      .where("createdAt", ">=", sixtyDaysAgo)
      .where("createdAt", "<", thirtyDaysAgo)
      .get()

    const metrics = {
      activeDonors: new Set(activeDonors.docs.map((d) => d.data().userId)).size,
      atRiskDonors: new Set(atRiskDonors.docs.map((d) => d.data().userId)).size,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }

    await db.collection("analytics").doc("donor_retention").set(metrics)

    console.log("Retention metrics calculated:", metrics)

    return null
  } catch (error) {
    console.error("Retention calculation error:", error)
    return null
  }
})

/**
 * Send engagement reminders to inactive donors
 */
exports.sendDonorEngagementReminders = onSchedule({ schedule: "every monday 09:00", region: "us-central1", serviceAccount: "careconn-79a46@appspot.gserviceaccount.com" }, async (context) => {
  try {
    const thirtyDaysAgo = Date.now() - 30 * 24 * 60 * 60 * 1000

    // Find donors who haven't donated in 30 days
    const recentDonations = await db.collection("donations").where("createdAt", ">=", thirtyDaysAgo).get()

    const recentDonorIds = new Set(recentDonations.docs.map((d) => d.data().userId))

    const allDonors = await db.collection("donors").get()

    for (const doc of allDonors.docs) {
      if (!recentDonorIds.has(doc.id)) {
        // Send notification (implement FCM)
        console.log(`Would send reminder to ${doc.id}`)
      }
    }

    return null
  } catch (error) {
    console.error("Engagement reminder error:", error)
    return null
  }
})
