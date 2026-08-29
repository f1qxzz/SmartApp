const express = require('express');
const authController = require('./auth.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const rateLimit = require('../../middleware/rateLimit.middleware');

const router = express.Router();

const strictIp = rateLimit({ windowMs: 15 * 60 * 1000, max: 10 });
const perEmail = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  keyGenerator: (req) => `fp:${String(req.body.email || '').toLowerCase()}`,
});
const resetIp = rateLimit({ windowMs: 60 * 60 * 1000, max: 10 });

router.post('/register', strictIp, authController.register);
router.post('/login', strictIp, authController.login);
router.post('/google', rateLimit({ windowMs: 15 * 60 * 1000, max: 20 }), authController.googleLogin);
router.post('/social-login', rateLimit({ windowMs: 15 * 60 * 1000, max: 20 }), authController.socialLogin);
router.post('/forgot-password', perEmail, authController.forgotPassword);
router.post('/reset-password', resetIp, authController.resetPassword);
router.get('/verify-email', authController.verifyEmail);
router.get('/me', authMiddleware, authController.me);
router.put('/profile', authMiddleware, authController.updateProfile);
router.get('/users/:id', authMiddleware, authController.getUserPublicProfile);
router.post('/logout', authMiddleware, authController.logout);

module.exports = router;
