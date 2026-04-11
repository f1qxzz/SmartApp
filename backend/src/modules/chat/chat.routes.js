const express = require('express');
const chatController = require('./chat.controller');
const authMiddleware = require('../../middleware/auth.middleware');

const router = express.Router();

router.use(authMiddleware);

router.get('/users', chatController.getContacts);
router.get('/', chatController.getChat);
router.post('/', chatController.postChat);
router.patch('/read/:withUserId', chatController.markRead);

module.exports = router;
