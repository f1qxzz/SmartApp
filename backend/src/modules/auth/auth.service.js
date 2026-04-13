const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const { OAuth2Client } = require('google-auth-library');
const User = require('./user.model');

const googleClient = new OAuth2Client();
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const isProduction = process.env.NODE_ENV === 'production';

let cachedTransporter = null;

function createHttpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function authLog(event, payload) {
  if (isProduction) {
    return;
  }

  if (payload) {
    // eslint-disable-next-line no-console
    console.log(`[AUTH] ${event}`, payload);
    return;
  }

  // eslint-disable-next-line no-console
  console.log(`[AUTH] ${event}`);
}

function isPlaceholder(value) {
  const normalized = String(value || '').trim().toLowerCase();
  return normalized === '' || normalized.startsWith('your_') || normalized === 'changeme';
}

function normalizeEmail(email) {
  return (email || '').toLowerCase().trim();
}

function ensureValidEmail(email) {
  if (!email || !emailRegex.test(email)) {
    throw createHttpError(400, 'Format email tidak valid');
  }
}

function isDuplicateKeyError(error) {
  return Boolean(error && error.code === 11000);
}

function getGoogleAudiences() {
  const rawList = [
    process.env.GOOGLE_WEB_CLIENT_ID,
    process.env.GOOGLE_ANDROID_CLIENT_ID,
    ...(process.env.GOOGLE_ALLOWED_CLIENT_IDS || '').split(','),
  ];

  return [...new Set(rawList.map((value) => String(value || '').trim()).filter(Boolean))];
}

function isSmtpEnabled() {
  const raw = String(process.env.SMTP_ENABLED || '').trim().toLowerCase();
  if (raw === 'false') {
    return false;
  }

  if (raw === 'true') {
    return true;
  }

  return true;
}

function hasValidSmtpConfig() {
  if (!isSmtpEnabled()) {
    return false;
  }

  const smtpHost = process.env.SMTP_HOST;
  const smtpPort = Number(process.env.SMTP_PORT || 0);
  const smtpUser = process.env.SMTP_USER;
  const smtpPass = process.env.SMTP_PASS;

  return (
    !isPlaceholder(smtpHost) &&
    Number.isFinite(smtpPort) &&
    smtpPort > 0 &&
    !isPlaceholder(smtpUser) &&
    !isPlaceholder(smtpPass)
  );
}

function generateToken(userId) {
  const jwtSecret = String(process.env.JWT_SECRET || '').trim();
  if (!jwtSecret) {
    throw createHttpError(500, 'JWT_SECRET belum dikonfigurasi di backend environment.');
  }

  return jwt.sign({ userId }, jwtSecret, { expiresIn: '7d' });
}

function buildAuthResponse(user) {
  return {
    token: generateToken(user._id.toString()),
    user: {
      id: user._id,
      name: user.name,
      email: user.email,
      avatar: user.avatar,
    },
  };
}

function getMailTransporter() {
  if (cachedTransporter) {
    return cachedTransporter;
  }

  if (hasValidSmtpConfig()) {
    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = Number(process.env.SMTP_PORT || 0);
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;
    const secure =
      String(process.env.SMTP_SECURE || '').toLowerCase() === 'true' || smtpPort === 465;

    cachedTransporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure,
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
    });

    return cachedTransporter;
  }

  cachedTransporter = nodemailer.createTransport({ jsonTransport: true });
  return cachedTransporter;
}

function buildResetPasswordLink({ email, rawToken }) {
  const base =
    process.env.CLIENT_RESET_PASSWORD_URL ||
    `${process.env.CLIENT_URL || 'http://localhost:3000'}/reset-password`;
  const separator = base.includes('?') ? '&' : '?';

  return `${base}${separator}token=${encodeURIComponent(rawToken)}&email=${encodeURIComponent(
    email
  )}`;
}

async function sendResetPasswordEmail({ to, name, resetLink }) {
  const usingMockTransport = !hasValidSmtpConfig();
  const from = process.env.SMTP_FROM || process.env.SMTP_USER || 'no-reply@smartlife.local';
  const transporter = getMailTransporter();

  await transporter.sendMail({
    from,
    to,
    subject: 'SmartLife - Reset Password',
    text: [
      `Halo ${name || 'SmartLife User'},`,
      '',
      'Kami menerima permintaan reset password akun Anda.',
      `Klik tautan berikut untuk reset password: ${resetLink}`,
      '',
      'Tautan berlaku selama 15 menit.',
      'Jika Anda tidak meminta reset password, abaikan email ini.',
    ].join('\n'),
    html: [
      `<p>Halo ${name || 'SmartLife User'},</p>`,
      '<p>Kami menerima permintaan reset password akun Anda.</p>',
      `<p><a href="${resetLink}">Klik di sini untuk reset password</a></p>`,
      '<p>Tautan berlaku selama 15 menit.</p>',
      '<p>Jika Anda tidak meminta reset password, abaikan email ini.</p>',
    ].join(''),
  });

  if (usingMockTransport) {
    authLog('forgot-password.dev-link', { to, resetLink });
  }

  return { usingMockTransport };
}

function ensureSocialAccountCompatible(user, provider) {
  if (user.authProvider === 'local' && user.password) {
    throw createHttpError(
      409,
      'Email ini sudah terdaftar dengan password. Silakan login dengan email & password.'
    );
  }

  if (user.authProvider !== provider && user.authProvider !== 'local') {
    throw createHttpError(
      409,
      'Email ini terhubung ke provider social lain. Gunakan metode login yang sesuai.'
    );
  }
}

async function register(payload) {
  const { name, email, password } = payload;
  const normalizedEmail = normalizeEmail(email);
  const normalizedName = String(name || '').trim();

  ensureValidEmail(normalizedEmail);

  if (normalizedName.length < 2) {
    throw createHttpError(400, 'Nama minimal 2 karakter');
  }

  if (!password || String(password).length < 6) {
    throw createHttpError(400, 'Password minimal 6 karakter');
  }

  const existingUser = await User.findOne({ email: normalizedEmail });
  if (existingUser) {
    throw createHttpError(409, 'Email sudah terdaftar');
  }

  const hashedPassword = await bcrypt.hash(String(password), 10);

  let user;
  try {
    user = await User.create({
      name: normalizedName,
      email: normalizedEmail,
      password: hashedPassword,
      authProvider: 'local',
    });
  } catch (error) {
    if (isDuplicateKeyError(error)) {
      throw createHttpError(409, 'Email sudah terdaftar');
    }
    throw error;
  }

  authLog('register.success', { email: normalizedEmail });
  return buildAuthResponse(user);
}

async function login(payload) {
  const { email, password } = payload;
  const normalizedEmail = normalizeEmail(email);

  ensureValidEmail(normalizedEmail);

  if (!password || String(password).trim().length === 0) {
    throw createHttpError(400, 'Password wajib diisi');
  }

  const user = await User.findOne({ email: normalizedEmail });

  if (!user) {
    authLog('login.failed.user-not-found', { email: normalizedEmail });
    throw createHttpError(401, 'Email atau password salah');
  }

  if (!user.password) {
    throw createHttpError(
      401,
      'Akun ini terdaftar melalui Google. Silakan masuk dengan Google.'
    );
  }

  const isPasswordMatch = await bcrypt.compare(String(password), user.password);
  if (!isPasswordMatch) {
    authLog('login.failed.wrong-password', { email: normalizedEmail });
    throw createHttpError(401, 'Email atau password salah');
  }

  authLog('login.success', { email: normalizedEmail });
  return buildAuthResponse(user);
}

async function verifyGoogleLogin(idToken) {
  if (!idToken) {
    throw createHttpError(400, 'Google idToken wajib diisi');
  }

  const audiences = getGoogleAudiences();
  if (audiences.length === 0) {
    throw createHttpError(
      500,
      'Google OAuth client ID belum dikonfigurasi di backend environment.'
    );
  }

  authLog('google.verify.start', { configuredAudiences: audiences.length });

  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: audiences,
    });
    const profile = ticket.getPayload();

    if (!profile || !profile.email || !profile.sub) {
      throw createHttpError(401, 'Token Google tidak memiliki payload yang valid');
    }

    if (profile.email_verified === false) {
      throw createHttpError(401, 'Email Google belum terverifikasi');
    }

    return {
      email: normalizeEmail(profile.email),
      name: String(profile.name || '').trim(),
      avatar: String(profile.picture || ''),
      providerId: String(profile.sub),
      audience: String(profile.aud || ''),
    };
  } catch (error) {
    authLog('google.verify.failed', { reason: error && error.message ? error.message : error });
    throw createHttpError(401, 'Token Google tidak valid. Silakan login ulang.');
  }
}

async function loginWithGoogle(payload) {
  const googleProfile = await verifyGoogleLogin(payload.idToken);
  authLog('google.login.request', {
    email: googleProfile.email,
    audience: googleProfile.audience || 'unknown',
  });

  let user = await User.findOne({ email: googleProfile.email });

  if (!user) {
    try {
      user = await User.create({
        name: googleProfile.name || googleProfile.email.split('@')[0] || 'Google User',
        email: googleProfile.email,
        avatar: googleProfile.avatar,
        authProvider: 'google',
        providerId: googleProfile.providerId,
        password: undefined,
      });
      authLog('google.login.user-created', { email: googleProfile.email });
    } catch (error) {
      if (!isDuplicateKeyError(error)) {
        throw error;
      }

      user = await User.findOne({ email: googleProfile.email });
      if (!user) {
        throw createHttpError(500, 'Gagal membuat akun Google. Silakan coba lagi.');
      }
    }
  }

  ensureSocialAccountCompatible(user, 'google');

  user.name = googleProfile.name || user.name;
  user.avatar = googleProfile.avatar || user.avatar;
  user.providerId = googleProfile.providerId;
  user.authProvider = 'google';
  await user.save();

  authLog('google.login.success', { email: googleProfile.email });
  return buildAuthResponse(user);
}

async function socialLogin(payload) {
  const provider = (payload.provider || '').toLowerCase().trim();

  if (provider !== 'google') {
    throw createHttpError(400, 'Provider social login tidak didukung. Gunakan Google.');
  }

  return loginWithGoogle(payload);
}

async function forgotPassword(payload) {
  const email = normalizeEmail(payload.email);
  ensureValidEmail(email);

  const user = await User.findOne({ email });
  if (!user) {
    authLog('forgot-password.user-not-found', { email });
    return {
      message: 'Jika email terdaftar, tautan reset password sudah dikirim.',
      data: null,
    };
  }

  const rawToken = crypto.randomBytes(32).toString('hex');
  const hashedToken = crypto.createHash('sha256').update(rawToken).digest('hex');
  const tokenExpiry = new Date(Date.now() + 15 * 60 * 1000);

  user.resetPasswordToken = hashedToken;
  user.resetPasswordExpires = tokenExpiry;
  await user.save();

  const resetLink = buildResetPasswordLink({ email, rawToken });
  const { usingMockTransport } = await sendResetPasswordEmail({
    to: user.email,
    name: user.name,
    resetLink,
  });

  const data = {};
  if (!isProduction && usingMockTransport) {
    data.devResetLink = resetLink;
  }

  authLog('forgot-password.success', { email, usingMockTransport });

  return {
    message: 'Jika email terdaftar, tautan reset password sudah dikirim.',
    data: Object.keys(data).length > 0 ? data : null,
  };
}

async function resetPassword(payload) {
  const email = normalizeEmail(payload.email);
  const token = String(payload.token || '').trim();
  const newPassword = String(payload.newPassword || '');

  ensureValidEmail(email);

  if (!token) {
    throw createHttpError(400, 'Token reset password wajib diisi');
  }

  if (newPassword.length < 6) {
    throw createHttpError(400, 'Password baru minimal 6 karakter');
  }

  const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

  const user = await User.findOne({
    email,
    resetPasswordToken: hashedToken,
    resetPasswordExpires: { $gt: new Date() },
  });

  if (!user) {
    throw createHttpError(400, 'Token reset password tidak valid atau sudah kadaluarsa');
  }

  user.password = await bcrypt.hash(newPassword, 10);
  user.authProvider = 'local';
  user.resetPasswordToken = '';
  user.resetPasswordExpires = null;
  await user.save();

  authLog('reset-password.success', { email });

  return { message: 'Password berhasil diperbarui. Silakan login kembali.' };
}

module.exports = {
  register,
  login,
  loginWithGoogle,
  socialLogin,
  forgotPassword,
  resetPassword,
};
