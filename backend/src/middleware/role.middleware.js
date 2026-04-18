const asyncHandler = require('./asyncHandler');

const requireRole = (...roles) => {
  return asyncHandler(async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Tidak ada sesi yang aktif. Silakan login terlebih dahulu.',
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak. Anda tidak memiliki izin untuk halaman ini.',
      });
    }

    next();
  });
};

module.exports = requireRole;
