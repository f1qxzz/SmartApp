const express = require('express');
const userController = require('./user.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const requireRole = require('../../middleware/role.middleware');

const router = express.Router();

// Only owner, developer, staff, or admin can manage roles (with hierarchy restrictions in controller)
router.get('/', authMiddleware, requireRole('owner', 'developer', 'staff', 'admin', 'ace_tester'), userController.getAllUsers);
router.put('/:id/role', authMiddleware, requireRole('owner', 'developer', 'staff', 'admin', 'ace_tester'), userController.updateUserRole);

module.exports = router;
