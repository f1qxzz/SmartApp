const express = require('express');
const aiController = require('./ai.controller');
const authMiddleware = require('../../middleware/auth.middleware');

const router = express.Router();

router.use(authMiddleware);
router.post('/chat', aiController.chatWithAI);

module.exports = router;
