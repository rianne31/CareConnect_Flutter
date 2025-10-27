/**
 * Provision an admin user in Firebase Auth and set custom claims.
 * Usage: node scripts/provision-admin.js <email> <password>
 */
const admin = require("firebase-admin")
// Initialize if not already initialized
try {
  admin.app()
} catch (e) {
  admin.initializeApp()
}

async function provisionAdmin(email, password) {
  if (!email || !password) {
    console.error("Usage: node scripts/provision-admin.js <email> <password>")
    process.exit(1)
  }

  const auth = admin.auth()

  let user
  try {
    user = await auth.getUserByEmail(email)
    console.log(`User already exists: ${user.uid}`)
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      console.log("Creating new admin user...")
      user = await auth.createUser({
        email,
        password,
        emailVerified: false,
        displayName: "Administrator",
        disabled: false,
      })
      console.log(`Created user: ${user.uid}`)
    } else {
      throw error
    }
  }

  // Set custom claim admin: true
  await auth.setCustomUserClaims(user.uid, { admin: true })
  console.log(`Set admin claim for ${user.uid}`)

  console.log("Done. You can now sign in and will have admin access after token refresh.")
}

const [email, password] = process.argv.slice(2)
provisionAdmin(email, password).catch((err) => {
  console.error("Failed to provision admin:", err)
  process.exit(1)
})