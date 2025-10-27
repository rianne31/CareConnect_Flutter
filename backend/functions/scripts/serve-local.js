const path = require("path")
require("dotenv").config({ path: path.join(__dirname, "..", ".env") })
const express = require("express")
const cors = require("cors")
const admin = require("firebase-admin")

// Ensure we point Admin SDK to Firestore emulator if available
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8099"
}
if (!process.env.GCLOUD_PROJECT) {
  process.env.GCLOUD_PROJECT = "careconn-79a46"
}

// Initialize Firebase Admin
try {
  admin.app()
} catch (e) {
  admin.initializeApp()
}

// Create Express app mirroring functions/index.js
const app = express()
app.use(
  cors({
    origin: true,
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "x-dev-uid", "x-dev-admin", "x-setup-key"],
    optionsSuccessStatus: 204,
  })
)
app.options("*", cors())
app.use(express.json())

// Mount existing routes
app.use("/donations", require("../api/donations"))
app.use("/ai", require("../api/ai"))
app.use("/payments", require("../api/payments"))
app.use("/admin", require("../api/admin"))

// Health
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString(), usingEmulator: !!process.env.FIRESTORE_EMULATOR_HOST })
})

const PORT = Number(process.env.LOCAL_FUNCTIONS_PORT || 5019)
const HOST = process.env.LOCAL_FUNCTIONS_HOST || "127.0.0.1"

app.listen(PORT, HOST, () => {
  console.log(`Local functions server listening at http://${HOST}:${PORT}`)
  console.log(`FIRESTORE_EMULATOR_HOST=${process.env.FIRESTORE_EMULATOR_HOST}`)
  console.log(`GCLOUD_PROJECT=${process.env.GCLOUD_PROJECT}`)
})