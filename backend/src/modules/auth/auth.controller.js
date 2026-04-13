const asyncHandler = require('../../middleware/asyncHandler');
const authService = require('./auth.service');

function sendError(res, statusCode, message) {
  return res.status(statusCode).json({
    success: false,
    message,
  });
}

function sendAuthSuccess(res, statusCode, message, authPayload) {
  return res.status(statusCode).json({
    success: true,
    message,
    token: authPayload.token,
    user: authPayload.user,
  });
}

const register = asyncHandler(async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return sendError(res, 400, 'Nama, email, dan password wajib diisi');
  }

  const data = await authService.register({ name, email, password });
  return sendAuthSuccess(res, 201, 'Register berhasil', data);
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return sendError(res, 400, 'Email dan password wajib diisi');
  }

  const data = await authService.login({ email, password });
  return sendAuthSuccess(res, 200, 'Login berhasil', data);
});

const socialLogin = asyncHandler(async (req, res) => {
  const { provider, providerId, email, name, avatar, idToken } = req.body;

  if (!provider || !idToken) {
    return sendError(res, 400, 'Provider dan idToken wajib diisi');
  }

  const data = await authService.socialLogin({
    provider,
    providerId,
    email,
    name,
    avatar,
    idToken,
  });

  return sendAuthSuccess(res, 200, 'Login social berhasil', data);
});

const googleLogin = asyncHandler(async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return sendError(res, 400, 'idToken wajib diisi');
  }

  const data = await authService.loginWithGoogle({ idToken });
  return sendAuthSuccess(res, 200, 'Login Google berhasil', data);
});

const forgotPassword = asyncHandler(async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return sendError(res, 400, 'Email wajib diisi');
  }

  const result = await authService.forgotPassword({ email });

  return res.status(200).json({
    success: true,
    message: result.message || 'Jika email terdaftar, tautan reset password sudah dikirim.',
    data: result.data || null,
  });
});

const resetPassword = asyncHandler(async (req, res) => {
  const { email, token, newPassword } = req.body;

  if (!email || !token || !newPassword) {
    return sendError(res, 400, 'Email, token, dan password baru wajib diisi');
  }

  const result = await authService.resetPassword({ email, token, newPassword });
  return res.status(200).json({
    success: true,
    message: result.message || 'Password berhasil diperbarui',
  });
});

const me = asyncHandler(async (req, res) => {
  return res.status(200).json({
    success: true,
    message: 'Profil berhasil diambil',
    user: req.user,
  });
});

module.exports = {
  register,
  login,
  googleLogin,
  socialLogin,
  forgotPassword,
  resetPassword,
  me,
};
