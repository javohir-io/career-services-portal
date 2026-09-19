/// Simple shared-secret admin check, NOT a full admin-user/role system.
/// Good enough for an MVP where you (the developer) are the only admin.
/// Send the key as a header: `x-admin-key: <ADMIN_API_KEY>`.
function adminMiddleware(req, res, next) {
  const key = req.headers['x-admin-key'];
  if (!key || key !== process.env.ADMIN_API_KEY) {
    return res.status(403).json({ error: 'Invalid or missing admin key' });
  }
  next();
}

module.exports = { adminMiddleware };
