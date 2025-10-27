const path = require("path")
// Load local .env if present (index.js already does this, but keep safe)
try {
  require("dotenv").config({ path: path.join(__dirname, "../.env") })
} catch (_) {}

const { Web3 } = require("web3")

let web3 = null
let account = null
let donationContract = null
let auctionContract = null
let achievementNFT = null

try {
  const rpcUrl = process.env.POLYGON_RPC_URL || process.env.BLOCKCHAIN_RPC_URL || process.env.CHAIN_RPC_URL
  if (rpcUrl) {
    // Initialize Web3
    web3 = new Web3(rpcUrl)

    // Configure signer account from private key, if provided
    const rawPk = process.env.POLYGON_PRIVATE_KEY || process.env.BLOCKCHAIN_PRIVATE_KEY || process.env.CHAIN_PRIVATE_KEY
    if (rawPk) {
      const pk = rawPk.startsWith("0x") ? rawPk : `0x${rawPk}`
      account = web3.eth.accounts.privateKeyToAccount(pk)
      web3.eth.accounts.wallet.add(account)
      web3.eth.defaultAccount = account.address
    }

    // Load ABIs from smart-contracts artifacts
    let donationAbi, auctionAbi, achievementAbi
    try {
      donationAbi = require("../../../smart-contracts/artifacts/contracts/DonationContract.sol/DonationContract.json").abi
    } catch (e) {
      console.warn("DonationContract ABI not found; donation features disabled")
    }
    try {
      auctionAbi = require("../../../smart-contracts/artifacts/contracts/AuctionContract.sol/AuctionContract.json").abi
    } catch (e) {
      console.warn("AuctionContract ABI not found; auction features disabled")
    }
    try {
      achievementAbi = require("../../../smart-contracts/artifacts/contracts/AchievementNFT.sol/AchievementNFT.json").abi
    } catch (e) {
      console.warn("AchievementNFT ABI not found; achievement features disabled")
    }

    // Create contract instances if addresses provided
    const donationAddress = process.env.DONATION_CONTRACT_ADDRESS
    const auctionAddress = process.env.AUCTION_CONTRACT_ADDRESS
    const achievementAddress = process.env.ACHIEVEMENT_NFT_ADDRESS

    if (donationAbi && donationAddress) {
      donationContract = new web3.eth.Contract(donationAbi, donationAddress)
    }
    if (auctionAbi && auctionAddress) {
      auctionContract = new web3.eth.Contract(auctionAbi, auctionAddress)
    }
    if (achievementAbi && achievementAddress) {
      achievementNFT = new web3.eth.Contract(achievementAbi, achievementAddress)
    }
  } else {
    console.warn("POLYGON_RPC_URL/BLOCKCHAIN_RPC_URL not set; web3 disabled")
  }
} catch (error) {
  console.error("Web3 initialization error:", error)
}

module.exports = {
  web3,
  account,
  donationContract,
  auctionContract,
  achievementNFT,
}
