const functions = require("firebase-functions")
const { db, messaging } = require("../config/firebase")
const blockchainService = require("../blockchain/blockchain-service")

/**
 * Trigger when donation is created
 */
module.exports = functions.firestore.document("donations/{donationId}").onCreate(async (snap, context) => {
  try {
    const donation = snap.data()
    const donationId = context.params.donationId

    // Update donor profile
    const donorRef = db.collection("donors").doc(donation.userId)
    const donorDoc = await donorRef.get()

    if (donorDoc.exists) {
      const currentTotal = donorDoc.data().totalDonated || 0
      const currentCount = donorDoc.data().donationCount || 0

      await donorRef.update({
        totalDonated: currentTotal + donation.amount,
        donationCount: currentCount + 1,
        lastDonationAt: donation.createdAt,
      })
    } else {
      await donorRef.set({
        totalDonated: donation.amount,
        donationCount: 1,
        tier: "Bronze",
        lastDonationAt: donation.createdAt,
        createdAt: donation.createdAt,
      })
    }

    // Check for achievement milestones
    const updatedDonor = await donorRef.get()
    const donorData = updatedDonor.data()

    // First donation badge
    if (donorData.donationCount === 1) {
      // Mint "First Donation" achievement NFT
      console.log(`Minting first donation badge for ${donation.userId}`)
    }

    // Send thank you notification
    // await messaging.send({
    //   token: userFCMToken,
    //   notification: {
    //     title: "Thank you for your donation!",
    //     body: `Your ₱${donation.amount} donation has been received.`
    //   }
    // })

    console.log(`Processed donation ${donationId}`)
  } catch (error) {
    console.error("Donation trigger error:", error)
  }
})
