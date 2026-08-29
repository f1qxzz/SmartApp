const asyncHandler = require('../../middleware/asyncHandler');
const authService = require('./auth.service');

const AUTH_COOKIE_NAME = 'smartlife_token';
const COOKIE_MAX_AGE_MS = 30 * 24 * 60 * 60 * 1000;

function sendError(res, statusCode, message) {
  return res.status(statusCode).json({
    success: false,
    message,
  });
}

function setAuthCookie(res, token, rememberMe) {
  const shouldRemember = rememberMe === true;
  res.cookie(AUTH_COOKIE_NAME, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    ...(shouldRemember ? { maxAge: COOKIE_MAX_AGE_MS } : {}),
  });
}

function clearAuthCookie(res) {
  res.clearCookie(AUTH_COOKIE_NAME, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
  });
}

function sendAuthSuccess(res, statusCode, message, authPayload, rememberMe = false) {
  setAuthCookie(res, authPayload.token, rememberMe);
  return res.status(statusCode).json({
    success: true,
    message,
    token: authPayload.token,
    user: authPayload.user,
  });
}

const register = asyncHandler(async (req, res) => {
  const { username, name, email, password, gender, dateOfBirth, rememberMe } = req.body;

  if ((!username && !name) || !email || !password) {
    return sendError(res, 400, 'Nama lengkap, email, dan password wajib diisi');
  }

  const data = await authService.register({ username, name, email, password, gender, dateOfBirth });

  if (data.requiresVerification) {
    return res.status(201).json({
      success: true,
      message: 'Registrasi berhasil. Silakan cek email untuk verifikasi akun.',
      requiresVerification: true,
      token: null,
      user: data.user,
    });
  }

  return sendAuthSuccess(res, 201, 'Register berhasil', data, rememberMe === true);
});

const login = asyncHandler(async (req, res) => {
  const { identifier, username, password, rememberMe } = req.body;
  const loginIdentifier = identifier || username;

  if (!loginIdentifier || !password) {
    return sendError(res, 400, 'Username/email dan password wajib diisi');
  }

  const data = await authService.login({ identifier: loginIdentifier, password });
  return sendAuthSuccess(res, 200, 'Login berhasil', data, rememberMe === true);
});

const socialLogin = asyncHandler(async (req, res) => {
  const { provider, providerId, email, name, avatar, idToken, rememberMe } = req.body;

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

  return sendAuthSuccess(res, 200, 'Login social berhasil', data, rememberMe === true);
});

const googleLogin = asyncHandler(async (req, res) => {
  const { idToken, rememberMe } = req.body;

  if (!idToken) {
    return sendError(res, 400, 'idToken wajib diisi');
  }

  const data = await authService.loginWithGoogle({ idToken });
  return sendAuthSuccess(res, 200, 'Login Google berhasil', data, rememberMe === true);
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
  const data = await authService.issueSession(req.user._id);
  return sendAuthSuccess(res, 200, 'Profil berhasil diambil', data, false);
});

const updateProfile = asyncHandler(async (req, res) => {
  const {
    username, email, gender, avatar, dateOfBirth, monthlyBudget, name,
    socialGithub, socialInstagram, socialDiscord, socialTelegram, socialSpotify, socialTikTok,
    bio,
  } = req.body;
  
  const user = await authService.updateProfile(req.user._id, {
    username,
    email,
    name,
    gender,
    avatar,
    dateOfBirth,
    monthlyBudget,
    socialGithub,
    socialInstagram,
    socialDiscord,
    socialTelegram,
    socialSpotify,
    socialTikTok,
    bio,
  });

  return res.status(200).json({
    success: true,
    message: 'Profil berhasil diperbarui',
    data: { user },
  });
});

const logout = asyncHandler(async (req, res) => {
  await authService.logout(req.user._id);
  clearAuthCookie(res);

  return res.status(200).json({
    success: true,
    message: 'Logout berhasil',
  });
});

const getUserPublicProfile = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (!id) {
    return sendError(res, 400, 'User ID wajib diisi');
  }

  const profile = await authService.getPublicProfile(id);
  return res.status(200).json({
    success: true,
    data: { user: profile },
  });
});

function renderVerifyPage({ success, message }) {
  const color = success ? '#1a7f37' : '#cf222e';
  return `<!doctype html>
<html lang="id">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>SmartLife - Verifikasi Email</title></head>
<body style="font-family: sans-serif; background: #f6f8fa; margin: 0; padding: 40px 16px;">
  <div style="max-width: 480px; margin: 0 auto; background: #fff; border: 1px solid #e1e4e8; border-radius: 12px; padding: 32px; text-align: center; color: #24292e;">
    <h2 style="color: #4B67D1; margin-top: 0;">SmartLife</h2>
    <p style="font-size: 16px; color: ${color}; font-weight: bold;">${message}</p>
    <p style="font-size: 14px; color: #57606a;">Kamu bisa menutup halaman ini dan membuka aplikasi SmartLife.</p>
  </div>
</body>
</html>`;
}

const verifyEmail = asyncHandler(async (req, res) => {
  try {
    const result = await authService.verifyEmail({ token: req.query.token, email: req.query.email });
    return res.status(200).send(renderVerifyPage({ success: true, message: result.message }));
  } catch (error) {
    return res.status(400).send(renderVerifyPage({ success: false, message: error.message || 'Verifikasi gagal' }));
  }
});

module.exports = {
  register,
  login,
  googleLogin,
  socialLogin,
  forgotPassword,
  resetPassword,
  verifyEmail,
  me,
  updateProfile,
  getUserPublicProfile,
  logout,
};
