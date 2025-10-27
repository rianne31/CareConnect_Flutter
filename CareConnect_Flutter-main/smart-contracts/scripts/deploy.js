const hre = require("hardhat")

async function main() {
  console.log("Starting deployment to", hre.network.name)

  const [deployer] = await hre.ethers.getSigners()
  console.log("Deploying contracts with account:", deployer.address)

  const balance = await hre.ethers.provider.getBalance(deployer.address)
  console.log("Account balance:", hre.ethers.formatEther(balance), "MATIC")

  // Treasury wallet address (replace with actual multi-sig wallet)
  const TREASURY_WALLET = process.env.TREASURY_WALLET_ADDRESS || deployer.address
  console.log("Treasury wallet:", TREASURY_WALLET)

  // Deploy DonationContract
  console.log("\n1. Deploying DonationContract...")
  const DonationContract = await hre.ethers.getContractFactory("DonationContract")
  const donationContract = await DonationContract.deploy(TREASURY_WALLET)
  await donationContract.waitForDeployment()
  const donationAddress = await donationContract.getAddress()
  console.log("✓ DonationContract deployed to:", donationAddress)

  // Deploy AuctionContract
  console.log("\n2. Deploying AuctionContract...")
  const AuctionContract = await hre.ethers.getContractFactory("AuctionContract")
  const auctionContract = await AuctionContract.deploy(TREASURY_WALLET)
  await auctionContract.waitForDeployment()
  const auctionAddress = await auctionContract.getAddress()
  console.log("✓ AuctionContract deployed to:", auctionAddress)

  // Deploy AchievementNFT
  console.log("\n3. Deploying AchievementNFT...")
  const AchievementNFT = await hre.ethers.getContractFactory("AchievementNFT")
  const achievementNFT = await AchievementNFT.deploy()
  await achievementNFT.waitForDeployment()
  const achievementAddress = await achievementNFT.getAddress()
  console.log("✓ AchievementNFT deployed to:", achievementAddress)

  // Grant roles
  console.log("\n4. Setting up roles...")

  // DonationContract - Grant RECORDER_ROLE to deployer (backend will use this)
  const RECORDER_ROLE = await donationContract.RECORDER_ROLE()
  await donationContract.grantRole(RECORDER_ROLE, deployer.address)
  console.log("✓ Granted RECORDER_ROLE to deployer")

  // AuctionContract - Grant AUCTIONEER_ROLE to deployer
  const AUCTIONEER_ROLE = await auctionContract.AUCTIONEER_ROLE()
  await auctionContract.grantRole(AUCTIONEER_ROLE, deployer.address)
  console.log("✓ Granted AUCTIONEER_ROLE to deployer")

  // AchievementNFT - Grant MINTER_ROLE to deployer
  const MINTER_ROLE = await achievementNFT.MINTER_ROLE()
  await achievementNFT.grantRole(MINTER_ROLE, deployer.address)
  console.log("✓ Granted MINTER_ROLE to deployer")

  // Verify deployment
  console.log("\n5. Verifying deployments...")
  const donationStats = await donationContract.getStats()
  console.log("✓ DonationContract initialized - Total donations:", donationStats[0].toString())

  const auctionCount = await auctionContract.totalAuctionsCount()
  console.log("✓ AuctionContract initialized - Total auctions:", auctionCount.toString())

  // Summary
  console.log("\n" + "=".repeat(60))
  console.log("DEPLOYMENT SUMMARY")
  console.log("=".repeat(60))
  console.log("Network:", hre.network.name)
  console.log("Deployer:", deployer.address)
  console.log("Treasury Wallet:", TREASURY_WALLET)
  console.log("\nContract Addresses:")
  console.log("-------------------")
  console.log("DonationContract:", donationAddress)
  console.log("AuctionContract:", auctionAddress)
  console.log("AchievementNFT:", achievementAddress)
  console.log("\n" + "=".repeat(60))
  console.log("\nIMPORTANT: Save these addresses to your .env files!")
  console.log("\nBackend .env:")
  console.log(`DONATION_CONTRACT_ADDRESS=${donationAddress}`)
  console.log(`AUCTION_CONTRACT_ADDRESS=${auctionAddress}`)
  console.log(`ACHIEVEMENT_NFT_ADDRESS=${achievementAddress}`)
  console.log("\nFlutter .env:")
  console.log(`DONATION_CONTRACT_ADDRESS=${donationAddress}`)
  console.log(`AUCTION_CONTRACT_ADDRESS=${auctionAddress}`)
  console.log(`ACHIEVEMENT_NFT_ADDRESS=${achievementAddress}`)
  console.log("\n" + "=".repeat(60))

  // Verification instructions
  if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
    console.log("\nTo verify contracts on Polygonscan, run:")
    console.log(`npx hardhat verify --network ${hre.network.name} ${donationAddress} ${TREASURY_WALLET}`)
    console.log(`npx hardhat verify --network ${hre.network.name} ${auctionAddress} ${TREASURY_WALLET}`)
    console.log(`npx hardhat verify --network ${hre.network.name} ${achievementAddress}`)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
