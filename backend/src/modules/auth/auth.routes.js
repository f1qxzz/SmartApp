const express = require('express');
const authController = require('./auth.controller');
const authMiddleware = require('../../middleware/auth.middleware');

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/google', authController.googleLogin);
router.post('/social-login', authController.socialLogin);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);
router.get('/me', authMiddleware, authController.me);
router.put('/profile', authMiddleware, authController.updateProfile);
router.get('/users/:id', authMiddleware, authController.getUserPublicProfile);
router.post('/logout', authMiddleware, authController.logout);

module.exports = router;
