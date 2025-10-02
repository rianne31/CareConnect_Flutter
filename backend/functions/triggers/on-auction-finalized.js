const functions = require("firebase-functions")
const { db, messaging, admin } = require("../config/firebase")

/**
 * Notify winner when auction is finalized
 */
module.exports = functions.firestore.document("auctions/{auctionId}").onUpdate(async (change, context) => {
  try {
    const before = change.before.data()
    const after = change.after.data()

    // Check if auction was just finalized
    if (before.status !== "finalized" && after.status === "finalized") {
      const auctionId = context.params.auctionId

      if (after.winnerId) {
        // Send notification to winner
        console.log(`Notifying winner ${after.winnerId} of auction ${auctionId}`)

        // await messaging.send({
        //   token: winnerFCMToken,
        //   notification: {
        //     title: "Congratulations! You won the auction!",
        //     body: `You won "${after.itemName}" for ₱${after.finalBid}`
        //   }
        // })

        // Create delivery coordination record
        await db.collection("auction_deliveries").add({
          auctionId: auctionId,
          winnerId: after.winnerId,
          itemName: after.itemName,
          status: "pending_coordination",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        })
      }

      console.log(`Processed auction finalization ${auctionId}`)
    }
  } catch (error) {
    console.error("Auction finalization trigger error:", error)
  }
})
