const express = require('express');
const userController = require('./user.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const requireRole = require('../../middleware/role.middleware');

const router = express.Router();

// Only owner or developer can manage roles
router.get('/', authMiddleware, requireRole('owner', 'developer'), userController.getAllUsers);
router.put('/:id/role', authMiddleware, requireRole('owner', 'developer'), userController.updateUserRole);

module.exports = router;
