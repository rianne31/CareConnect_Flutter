const { Web3 } = require("web3")
require("dotenv").config()

// Initialize Web3 with Polygon RPC
const web3 = new Web3(process.env.POLYGON_RPC_URL || "https://polygon-rpc.com")

// Load contract ABIs
const DonationContractABI =
  require("../../../smart-contracts/artifacts/contracts/DonationContract.sol/DonationContract.json").abi
const AuctionContractABI =
  require("../../../smart-contracts/artifacts/contracts/AuctionContract.sol/AuctionContract.json").abi
const AchievementNFTABI =
  require("../../../smart-contracts/artifacts/contracts/AchievementNFT.sol/AchievementNFT.json").abi

// Create contract instances
const donationContract = new web3.eth.Contract(DonationContractABI, process.env.DONATION_CONTRACT_ADDRESS)

const auctionContract = new web3.eth.Contract(AuctionContractABI, process.env.AUCTION_CONTRACT_ADDRESS)

const achievementNFT = new web3.eth.Contract(AchievementNFTABI, process.env.ACHIEVEMENT_NFT_ADDRESS)

// Account for signing transactions
const account = web3.eth.accounts.privateKeyToAccount(process.env.POLYGON_PRIVATE_KEY)
web3.eth.accounts.wallet.add(account)

module.exports = {
  web3,
  donationContract,
  auctionContract,
  achievementNFT,
  account,
}
