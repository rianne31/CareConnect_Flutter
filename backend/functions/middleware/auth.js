const { auth } = require("../config/firebase")

/**
 * Verify Firebase ID token
 */
async function verifyToken(req, res, next) {
  try {
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

module.exports = {
  verifyToken,
  requireAdmin,
  requireAuth,
}
