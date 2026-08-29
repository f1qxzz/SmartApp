const rateLimitStore = new Map();

// Lightweight in-memory sliding-window rate limiter. Good for a single
// instance; swap the store for Redis if the API runs behind multiple nodes.
function rateLimit({ windowMs = 15 * 60 * 1000, max = 10, keyGenerator } = {}) {
  return (req, res, next) => {
    const key = keyGenerator ? keyGenerator(req) : (req.ip || req.headers['x-forwarded-for'] || 'unknown');
    const now = Date.now();
    const entry = rateLimitStore.get(key);

    if (!entry || now > entry.resetAt) {
      rateLimitStore.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }

    entry.count += 1;
    if (entry.count > max) {
      const retryAfter = Math.ceil((entry.resetAt - now) / 1000);
      res.set('Retry-After', String(retryAfter));
      return res.status(429).json({
        success: false,
        message: 'Terlalu banyak permintaan. Coba lagi dalam beberapa menit.',
      });
    }

    return next();
  };
}

// Drop expired buckets so the Map does not grow unbounded.
const cleanup = setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of rateLimitStore) {
    if (now > entry.resetAt) {
      rateLimitStore.delete(key);
    }
  }
}, 5 * 60 * 1000);
cleanup.unref?.();

module.exports = rateLimit;
module.exports.rateLimit = rateLimit;
