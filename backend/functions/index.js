 const path = require("path")
 require("dotenv").config({ path: path.join(__dirname, ".env") })
const functions = require("firebase-functions")
const admin = require("firebase-admin")
const express = require("express")
const cors = require("cors")

// Initialize Firebase Admin
admin.initializeApp()

// Import route handlers
const donationRoutes = require("./api/donations")
const auctionRoutes = require("./api/auctions")
const patientRoutes = require("./api/patients")
const donorRoutes = require("./api/donors")
const aiRoutes = require("./api/ai")
const analyticsRoutes = require("./api/analytics")
const paymentRoutes = require("./api/payments")

// Import blockchain services
const blockchainService = require("./blockchain/blockchain-service")

// Import scheduled functions
const scheduledFunctions = require("./scheduled")

// Create Express app
const app = express()

// Middleware
app.use(cors({ origin: true }))
app.use(express.json())

// Routes
app.use("/donations", donationRoutes)
app.use("/auctions", auctionRoutes)
app.use("/patients", patientRoutes)
app.use("/donors", donorRoutes)
app.use("/ai", aiRoutes)
app.use("/analytics", analyticsRoutes)
app.use("/payments", paymentRoutes)

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() })
})

// Export API
exports.api = functions.https.onRequest(app)

// Export scheduled functions
exports.finalizeExpiredAuctions = scheduledFunctions.finalizeExpiredAuctions
exports.updateDonorTiers = scheduledFunctions.updateDonorTiers
exports.calculateDonorRetention = scheduledFunctions.calculateDonorRetention
exports.sendDonorEngagementReminders = scheduledFunctions.sendDonorEngagementReminders

// Export trigger functions
exports.onDonationCreated = require("./triggers/on-donation-created")
exports.onPatientCreated = require("./triggers/on-patient-created")
exports.onAuctionFinalized = require("./triggers/on-auction-finalized")
