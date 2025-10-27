const path = require("path")
 require("dotenv").config({ path: path.join(__dirname, ".env") })
const functions = require("firebase-functions")
const { defineSecret } = require("firebase-functions/params")
const { onRequest } = require("firebase-functions/v2/https")
const admin = require("firebase-admin")
const express = require("express")
const cors = require("cors")

// Initialize Firebase Admin
admin.initializeApp()

// Define secrets for production (Cloud Functions v2)
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY")

// Import route handlers (only existing modules)
const donationRoutes = require("./api/donations")
const aiRoutes = require("./api/ai")
const paymentRoutes = require("./api/payments")
const adminRoutes = require("./api/admin")

// Control whether to load non-API exports (scheduled/triggers) at init time
const ENABLE_ALL_FUNCTIONS = process.env.ENABLE_ALL_FUNCTIONS !== "false"

// Create Express app
const app = express()

// Middleware
// Strengthen CORS to support Authorization header and preflight requests
app.use(
  cors({
    origin: true,
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "x-dev-uid", "x-dev-admin", "x-setup-key"],
    optionsSuccessStatus: 204,
  })
)
// Explicitly handle preflight across all routes
app.options("*", cors())
app.use(express.json())

// Routes
app.use("/donations", donationRoutes)
app.use("/ai", aiRoutes)
app.use("/payments", paymentRoutes)
app.use("/admin", adminRoutes)

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() })
})

// Export API using v2 with explicit service account
exports.api = onRequest({
  region: "us-central1",
  serviceAccount: "careconn-79a46@appspot.gserviceaccount.com",
  secrets: [GEMINI_API_KEY],
}, app)

// Optionally export scheduled and trigger functions to avoid heavy imports during API-only deploys
if (ENABLE_ALL_FUNCTIONS) {
  const scheduledFunctions = require("./scheduled")
  // Export scheduled functions (v2) under new names to avoid 1st Gen conflicts
  exports.finalizeExpiredAuctionsV2 = scheduledFunctions.finalizeExpiredAuctions
  exports.updateDonorTiersV2 = scheduledFunctions.updateDonorTiers
  exports.calculateDonorRetentionV2 = scheduledFunctions.calculateDonorRetention
  exports.sendDonorEngagementRemindersV2 = scheduledFunctions.sendDonorEngagementReminders

  // Export trigger functions (v2) under new names to avoid 1st Gen conflicts
  exports.onDonationCreatedV2 = require("./triggers/on-donation-created")
  exports.onPatientCreatedV2 = require("./triggers/on-patient-created")
  exports.onAuctionFinalizedV2 = require("./triggers/on-auction-finalized")
  exports.onAuctionCreatedV2 = require("./triggers/on-auction-created")
}
