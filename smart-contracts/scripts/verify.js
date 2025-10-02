const hre = require("hardhat")

async function main() {
  console.log("Verifying contracts on Polygonscan...")

  const TREASURY_WALLET = process.env.TREASURY_WALLET_ADDRESS
  const DONATION_CONTRACT = process.env.DONATION_CONTRACT_ADDRESS
  const AUCTION_CONTRACT = process.env.AUCTION_CONTRACT_ADDRESS
  const ACHIEVEMENT_NFT = process.env.ACHIEVEMENT_NFT_ADDRESS

  if (!TREASURY_WALLET || !DONATION_CONTRACT || !AUCTION_CONTRACT || !ACHIEVEMENT_NFT) {
    console.error("Error: Missing contract addresses in .env file")
    process.exit(1)
  }

  try {
    // Verify DonationContract
    console.log("\n1. Verifying DonationContract...")
    await hre.run("verify:verify", {
      address: DONATION_CONTRACT,
      constructorArguments: [TREASURY_WALLET],
    })
    console.log("✓ DonationContract verified")

    // Verify AuctionContract
    console.log("\n2. Verifying AuctionContract...")
    await hre.run("verify:verify", {
      address: AUCTION_CONTRACT,
      constructorArguments: [TREASURY_WALLET],
    })
    console.log("✓ AuctionContract verified")

    // Verify AchievementNFT
    console.log("\n3. Verifying AchievementNFT...")
    await hre.run("verify:verify", {
      address: ACHIEVEMENT_NFT,
      constructorArguments: [],
    })
    console.log("✓ AchievementNFT verified")

    console.log("\n✓ All contracts verified successfully!")
  } catch (error) {
    console.error("Verification error:", error)
    process.exit(1)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
