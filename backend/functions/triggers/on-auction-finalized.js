const { onDocumentUpdated } = require("firebase-functions/v2/firestore")
const { db, messaging, admin } = require("../config/firebase")

/**
 * Notify winner when auction is finalized
 */
module.exports = onDocumentUpdated({ document: "auctions/{auctionId}", region: "us-central1", serviceAccount: "careconn-79a46@appspot.gserviceaccount.com" }, async (event) => {
  try {
    const before = event.data.before.data()
    const after = event.data.after.data()

    // Check if auction was just finalized
    if (before.status !== "finalized" && after.status === "finalized") {
      const auctionId = event.params.auctionId

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
