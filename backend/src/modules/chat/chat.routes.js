const express = require('express');
const chatController = require('./chat.controller');
const authMiddleware = require('../../middleware/auth.middleware');

const router = express.Router();

router.get('/users/search', authMiddleware, chatController.searchUsers);
router.get('/chats', authMiddleware, chatController.getChats);
router.get('/messages/:chatId', authMiddleware, chatController.getMessages);
router.post('/messages/send', authMiddleware, chatController.sendMessage);
router.delete('/messages/:id', authMiddleware, chatController.deleteMessage);
router.delete('/conversations/:id', authMiddleware, chatController.deleteConversation);

// Backward compatibility with older mobile routes
router.get('/api/chat/users', authMiddleware, chatController.searchUsers);
router.get('/api/chat', authMiddleware, chatController.getChats);
router.get('/api/chat/messages/:chatId', authMiddleware, chatController.getMessages);
router.post('/api/chat', authMiddleware, chatController.sendMessage);
router.delete('/api/chat/message/:id', authMiddleware, chatController.deleteMessage);
router.delete('/api/chat/conversation/:id', authMiddleware, chatController.deleteConversation);

module.exports = router;
