const { web3, donationContract, auctionContract, achievementNFT, account } = require("../config/web3")

class BlockchainService {
  /**
   * Record fiat donation on blockchain
   */
  async recordFiatDonation(donorAddress, amount, currency, externalTxId, patientId, isAnonymous) {
    try {
      const tx = donationContract.methods.recordFiatDonation(
        donorAddress,
        amount,
        currency,
        externalTxId,
        patientId,
        isAnonymous,
      )

      const gas = await tx.estimateGas({ from: account.address })
      const gasPrice = await web3.eth.getGasPrice()

      const receipt = await tx.send({
        from: account.address,
        gas: gas,
        gasPrice: gasPrice,
      })

      return receipt.transactionHash
    } catch (error) {
      console.error("Blockchain recording error:", error)
      throw error
    }
  }

  /**
   * Verify donation on blockchain
   */
  async verifyDonation(txHash) {
    try {
      const receipt = await web3.eth.getTransactionReceipt(txHash)
      const transaction = await web3.eth.getTransaction(txHash)
      const block = await web3.eth.getBlock(receipt.blockNumber)

      return {
        success: receipt.status,
        transaction: transaction,
        blockNumber: receipt.blockNumber,
        timestamp: block.timestamp,
      }
    } catch (error) {
      console.error("Verification error:", error)
      throw error
    }
  }

  /**
   * Get donor's total donations from blockchain
   */
  async getDonorTotal(donorAddress) {
    try {
      const total = await donationContract.methods.getDonorTotal(donorAddress).call()
      return total
    } catch (error) {
      console.error("Error fetching donor total:", error)
      throw error
    }
  }

  /**
   * Get donation statistics from blockchain
   */
  async getDonationStats() {
    try {
      const stats = await donationContract.methods.getStats().call()
      return {
        totalDonations: stats[0],
        totalAmount: stats[1],
        contractBalance: stats[2],
      }
    } catch (error) {
      console.error("Error fetching stats:", error)
      throw error
    }
  }

  /**
   * Create auction on blockchain
   */
  async createAuction(seller, startingBid, duration, itemName, itemDescription, itemImageUrl, tokenURI) {
    try {
      const tx = auctionContract.methods.createAuction(
        seller,
        startingBid,
        duration,
        itemName,
        itemDescription,
        itemImageUrl,
        tokenURI,
      )

      const gas = await tx.estimateGas({ from: account.address })
      const gasPrice = await web3.eth.getGasPrice()

      const receipt = await tx.send({
        from: account.address,
        gas: gas,
        gasPrice: gasPrice,
      })

      // Extract auction ID from events
      const auctionId = receipt.events.AuctionCreated.returnValues.auctionId

      return {
        auctionId: auctionId,
        txHash: receipt.transactionHash,
      }
    } catch (error) {
      console.error("Auction creation error:", error)
      throw error
    }
  }

  /**
   * Finalize auction on blockchain
   */
  async finalizeAuction(auctionId) {
    try {
      const tx = auctionContract.methods.finalizeAuction(auctionId)

      const gas = await tx.estimateGas({ from: account.address })
      const gasPrice = await web3.eth.getGasPrice()

      const receipt = await tx.send({
        from: account.address,
        gas: gas,
        gasPrice: gasPrice,
      })

      return receipt.transactionHash
    } catch (error) {
      console.error("Auction finalization error:", error)
      throw error
    }
  }

  /**
   * Get auction details from blockchain
   */
  async getAuction(auctionId) {
    try {
      const auction = await auctionContract.methods.getAuction(auctionId).call()
      return {
        tokenId: auction[0],
        seller: auction[1],
        startingBid: auction[2],
        currentBid: auction[3],
        currentBidder: auction[4],
        startTime: auction[5],
        endTime: auction[6],
        active: auction[7],
        finalized: auction[8],
        itemName: auction[9],
        itemDescription: auction[10],
        itemImageUrl: auction[11],
      }
    } catch (error) {
      console.error("Error fetching auction:", error)
      throw error
    }
  }

  /**
   * Mint achievement NFT badge
   */
  async mintAchievementBadge(recipient, achievementType, tier, value, tokenURI) {
    try {
      const tx = achievementNFT.methods.mintAchievement(recipient, achievementType, tier, value, tokenURI)

      const gas = await tx.estimateGas({ from: account.address })
      const gasPrice = await web3.eth.getGasPrice()

      const receipt = await tx.send({
        from: account.address,
        gas: gas,
        gasPrice: gasPrice,
      })

      const tokenId = receipt.events.AchievementMinted.returnValues.tokenId

      return {
        tokenId: tokenId,
        txHash: receipt.transactionHash,
      }
    } catch (error) {
      console.error("Achievement minting error:", error)
      throw error
    }
  }

  /**
   * Get user's achievement badges
   */
  async getUserAchievements(userAddress) {
    try {
      const achievements = await achievementNFT.methods.getUserAchievements(userAddress).call()
      return achievements
    } catch (error) {
      console.error("Error fetching achievements:", error)
      throw error
    }
  }
}

module.exports = new BlockchainService()
