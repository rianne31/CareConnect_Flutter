const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("AuctionContract", () => {
  let auctionContract
  let owner, treasury, seller, bidder1, bidder2

  beforeEach(async () => {
    ;[owner, treasury, seller, bidder1, bidder2] = await ethers.getSigners()

    const AuctionContract = await ethers.getContractFactory("AuctionContract")
    auctionContract = await AuctionContract.deploy(treasury.address)
    await auctionContract.waitForDeployment()
  })

  describe("Deployment", () => {
    it("Should set the correct treasury wallet", async () => {
      expect(await auctionContract.treasuryWallet()).to.equal(treasury.address)
    })

    it("Should grant auctioneer role to deployer", async () => {
      const AUCTIONEER_ROLE = await auctionContract.AUCTIONEER_ROLE()
      expect(await auctionContract.hasRole(AUCTIONEER_ROLE, owner.address)).to.be.true
    })
  })

  describe("Auction Creation", () => {
    it("Should create auction with NFT", async () => {
      const startingBid = ethers.parseEther("0.1")
      const duration = 86400 // 1 day

      await expect(
        auctionContract.createAuction(
          seller.address,
          startingBid,
          duration,
          "Vintage Watch",
          "Beautiful vintage watch from 1950s",
          "https://example.com/watch.jpg",
          "ipfs://metadata",
        ),
      ).to.emit(auctionContract, "AuctionCreated")

      const auction = await auctionContract.getAuction(0)
      expect(auction.itemName).to.equal("Vintage Watch")
      expect(auction.active).to.be.true
    })

    it("Should require AUCTIONEER_ROLE", async () => {
      await expect(
        auctionContract
          .connect(seller)
          .createAuction(seller.address, ethers.parseEther("0.1"), 86400, "Item", "Description", "url", "uri"),
      ).to.be.reverted
    })
  })

  describe("Bidding", () => {
    beforeEach(async () => {
      await auctionContract.createAuction(
        seller.address,
        ethers.parseEther("0.1"),
        86400,
        "Test Item",
        "Description",
        "url",
        "uri",
      )
    })

    it("Should accept valid bids", async () => {
      const bidAmount = ethers.parseEther("0.2")

      await expect(auctionContract.connect(bidder1).placeBid(0, { value: bidAmount })).to.emit(
        auctionContract,
        "BidPlaced",
      )

      const auction = await auctionContract.getAuction(0)
      expect(auction.currentBid).to.equal(bidAmount)
      expect(auction.currentBidder).to.equal(bidder1.address)
    })

    it("Should refund previous bidder", async () => {
      const bid1 = ethers.parseEther("0.2")
      const bid2 = ethers.parseEther("0.3")

      await auctionContract.connect(bidder1).placeBid(0, { value: bid1 })

      const balanceBefore = await ethers.provider.getBalance(bidder1.address)
      await auctionContract.connect(bidder2).placeBid(0, { value: bid2 })
      const balanceAfter = await ethers.provider.getBalance(bidder1.address)

      expect(balanceAfter - balanceBefore).to.equal(bid1)
    })

    it("Should reject bids below current bid", async () => {
      await auctionContract.connect(bidder1).placeBid(0, { value: ethers.parseEther("0.2") })

      await expect(
        auctionContract.connect(bidder2).placeBid(0, { value: ethers.parseEther("0.15") }),
      ).to.be.revertedWith("Bid must be higher than current bid")
    })
  })

  describe("Auction Finalization", () => {
    beforeEach(async () => {
      await auctionContract.createAuction(
        seller.address,
        ethers.parseEther("0.1"),
        3600, // 1 hour duration for testing
        "Test Item",
        "Description",
        "url",
        "uri",
      )
    })

    it("Should finalize auction and transfer funds to treasury", async () => {
      const bidAmount = ethers.parseEther("0.5")
      await auctionContract.connect(bidder1).placeBid(0, { value: bidAmount })

      // Wait for auction to end
      await ethers.provider.send("evm_increaseTime", [3601])
      await ethers.provider.send("evm_mine")

      const treasuryBalanceBefore = await ethers.provider.getBalance(treasury.address)

      await auctionContract.finalizeAuction(0)

      const treasuryBalanceAfter = await ethers.provider.getBalance(treasury.address)
      expect(treasuryBalanceAfter - treasuryBalanceBefore).to.equal(bidAmount)
    })

    it("Should transfer NFT to winner", async () => {
      await auctionContract.connect(bidder1).placeBid(0, { value: ethers.parseEther("0.5") })

      await ethers.provider.send("evm_increaseTime", [3601])
      await ethers.provider.send("evm_mine")

      await auctionContract.finalizeAuction(0)

      const auction = await auctionContract.getAuction(0)
      expect(await auctionContract.ownerOf(auction.tokenId)).to.equal(bidder1.address)
    })
  })
})
