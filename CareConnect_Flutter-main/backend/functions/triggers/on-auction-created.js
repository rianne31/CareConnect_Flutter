const { onDocumentCreated } = require("firebase-functions/v2/firestore")
const { db, admin } = require("../config/firebase")
const blockchainService = require("../blockchain/blockchain-service")
const { web3, account } = require("../config/web3")

/**
 * When an auction doc is created, also create it on-chain
 * then persist `blockchainAuctionId` and `blockchainTxHash` back to Firestore.
 * Requires web3 to be configured in environment.
 */
module.exports = onDocumentCreated({ document: "auctions/{auctionId}", region: "us-central1", serviceAccount: "careconn-79a46@appspot.gserviceaccount.com" }, async (event) => {
  try {
    const auction = event.data.data()
    const auctionDocRef = event.data.ref

    // Skip if already linked to blockchain
    if (auction.blockchainAuctionId || auction.blockchainTxHash) {
      return
    }

    // Prepare inputs for blockchain auction creation
    let seller = auction.sellerId || ""
    try {
      if (!seller || !web3 || !web3.utils.isAddress(seller)) {
        seller = (account && account.address) || seller || ""
      }
    } catch (_) {
      seller = (account && account.address) || seller || ""
    }
    const startingBid = Number(auction.startingBid || 0)

    // Derive duration (seconds) from Firestore start/end timestamps
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

      await auctionDocRef.update({
        blockchainAuctionId: result.auctionId,
        blockchainTxHash: result.txHash,
        tokenId: null,
        // Capture creation time server-side for consistency
        createdAt: auction.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      })
    } catch (error) {
      console.error("Failed to create auction on-chain:", error)
      // Leave Firestore doc as-is; optionally write error for observability
      await auctionDocRef.update({
        blockchainError: String(error.message || error),
      })
    }
  } catch (e) {
    console.error("Auction creation trigger error:", e)
  }
})