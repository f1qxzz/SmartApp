const jwt = require('jsonwebtoken');
const User = require('../modules/auth/user.model');

const AUTH_COOKIE_NAME = 'smartlife_token';

function parseCookies(rawCookieHeader) {
  if (!rawCookieHeader) {
    return {};
  }

  return String(rawCookieHeader)
    .split(';')
    .map((cookie) => cookie.trim())
    .filter(Boolean)
    .reduce((acc, cookie) => {
      const separatorIndex = cookie.indexOf('=');
      if (separatorIndex === -1) {
        return acc;
      }
      const key = cookie.slice(0, separatorIndex).trim();
      const value = decodeURIComponent(cookie.slice(separatorIndex + 1).trim());
      acc[key] = value;
      return acc;
    }, {});
}

async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization || '';
    const bearerToken = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : '';
    const cookies = parseCookies(req.headers.cookie || '');
    const cookieToken = cookies[AUTH_COOKIE_NAME] || '';
    const token = bearerToken || cookieToken;

    if (!token) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.userId).select('-password');

    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    const tokenVersion = Number(payload.tv || 0);
    if (tokenVersion !== Number(user.tokenVersion || 0)) {
      return res.status(401).json({ success: false, message: 'Session expired' });
    }

    req.user = user;
    return next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
}

module.exports = authMiddleware;
