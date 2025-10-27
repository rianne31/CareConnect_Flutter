const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("DonationContract", () => {
  let donationContract
  let owner, treasury, donor1, donor2

  beforeEach(async () => {
    ;[owner, treasury, donor1, donor2] = await ethers.getSigners()

    const DonationContract = await ethers.getContractFactory("DonationContract")
    donationContract = await DonationContract.deploy(treasury.address)
    await donationContract.waitForDeployment()
  })

  describe("Deployment", () => {
    it("Should set the correct treasury wallet", async () => {
      expect(await donationContract.treasuryWallet()).to.equal(treasury.address)
    })

    it("Should grant admin role to deployer", async () => {
      const ADMIN_ROLE = await donationContract.ADMIN_ROLE()
      expect(await donationContract.hasRole(ADMIN_ROLE, owner.address)).to.be.true
    })
  })

  describe("Crypto Donations", () => {
    it("Should accept crypto donations", async () => {
      const donationAmount = ethers.parseEther("1.0")

      await expect(donationContract.connect(donor1).donate(false, "", { value: donationAmount })).to.emit(
        donationContract,
        "DonationReceived",
      )

      const stats = await donationContract.getStats()
      expect(stats[0]).to.equal(1) // totalDonationsCount
      expect(stats[1]).to.equal(donationAmount) // totalDonationsAmount
    })

    it("Should transfer funds to treasury", async () => {
      const donationAmount = ethers.parseEther("1.0")
      const initialBalance = await ethers.provider.getBalance(treasury.address)

      await donationContract.connect(donor1).donate(false, "", { value: donationAmount })

      const finalBalance = await ethers.provider.getBalance(treasury.address)
      expect(finalBalance - initialBalance).to.equal(donationAmount)
    })

    it("Should track donor donations", async () => {
      const donationAmount = ethers.parseEther("0.5")

      await donationContract.connect(donor1).donate(false, "", { value: donationAmount })

      const donorTotal = await donationContract.getDonorTotal(donor1.address)
      expect(donorTotal).to.equal(donationAmount)
    })

    it("Should reject zero donations", async () => {
      await expect(donationContract.connect(donor1).donate(false, "", { value: 0 })).to.be.revertedWith(
        "Donation amount must be greater than 0",
      )
    })
  })

  describe("Fiat Donations", () => {
    it("Should record fiat donations", async () => {
      const RECORDER_ROLE = await donationContract.RECORDER_ROLE()
      await donationContract.grantRole(RECORDER_ROLE, owner.address)

      await expect(
        donationContract.recordFiatDonation(
          donor1.address,
          100000, // 1000 PHP in cents
          "PHP",
          "PAYMAYA_TX_123",
          "",
          false,
        ),
      ).to.emit(donationContract, "DonationRecorded")

      const stats = await donationContract.getStats()
      expect(stats[0]).to.equal(1)
    })

    it("Should require RECORDER_ROLE", async () => {
      await expect(
        donationContract.connect(donor1).recordFiatDonation(donor1.address, 100000, "PHP", "TX_123", "", false),
      ).to.be.reverted
    })
  })

  describe("Admin Functions", () => {
    it("Should allow admin to update treasury", async () => {
      const newTreasury = donor2.address

      await donationContract.updateTreasuryWallet(newTreasury)

      expect(await donationContract.treasuryWallet()).to.equal(newTreasury)
    })

    it("Should allow admin to pause", async () => {
      await donationContract.pause()

      await expect(
        donationContract.connect(donor1).donate(false, "", { value: ethers.parseEther("1") }),
      ).to.be.revertedWith("Pausable: paused")
    })
  })
})
