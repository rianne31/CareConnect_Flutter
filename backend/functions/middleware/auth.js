const { auth } = require("../config/firebase")

// Enable development auth bypass when explicitly configured
const DEV_AUTH_BYPASS = process.env.DEV_AUTH_BYPASS === "true"

/**
 * Verify Firebase ID token
 */
async function verifyToken(req, res, next) {
  try {
    // Development-only bypass: skip Firebase verification and inject a mock user
    if (DEV_AUTH_BYPASS) {
      const devUid = req.headers["x-dev-uid"] || "dev-user"
      const devAdmin = (req.headers["x-dev-admin"] || "false").toLowerCase() === "true"

      req.user = { uid: devUid, admin: devAdmin }
      return next()
    }

    const authHeader = req.headers.authorization

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized - No token provided" })
    }

    const token = authHeader.split("Bearer ")[1]
    const decodedToken = await auth.verifyIdToken(token)

    req.user = decodedToken
    next()
  } catch (error) {
    console.error("Token verification error:", error)
    return res.status(401).json({ error: "Unauthorized - Invalid token" })
  }
}

/**
 * Check if user has admin role
 */
function requireAdmin(req, res, next) {
  if (!req.user || !req.user.admin) {
    return res.status(403).json({ error: "Forbidden - Admin access required" })
  }
  next()
}

/**
 * Check if user is authenticated (donor or admin)
 */
function requireAuth(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ error: "Unauthorized - Authentication required" })
  }
  next()
}

/**
 * Optional auth: attach req.user if token present; otherwise continue as guest
 */
async function optionalAuth(req, res, next) {
  try {
    // Development-only bypass: inject mock user for local testing
    if (DEV_AUTH_BYPASS) {
      const devUid = req.headers["x-dev-uid"] || "dev-user"
      const devAdmin = (req.headers["x-dev-admin"] || "false").toLowerCase() === "true"
      req.user = { uid: devUid, admin: devAdmin }
      return next()
    }

    const authHeader = req.headers.authorization
    if (authHeader && authHeader.startsWith("Bearer ")) {
      const token = authHeader.split("Bearer ")[1]
      if (token) {
        try {
          const decodedToken = await auth.verifyIdToken(token)
          req.user = decodedToken
        } catch (e) {
          console.warn("Optional auth: invalid token, proceeding as guest")
        }
      }
    }
    // Proceed whether user is set or not
    next()
  } catch (error) {
    console.error("Optional auth verification error:", error)
    next()
  }
}

module.exports = {
  verifyToken,
  requireAdmin,
  requireAuth,
  optionalAuth,
}
