const asyncHandler = require('../../middleware/asyncHandler');
const chatService = require('./chat.service');
const { emitReceiveMessage } = require('../../sockets/events');

const searchUsers = asyncHandler(async (req, res) => {
  const keyword = req.query.username || '';
  const users = await chatService.searchUsers(req.user._id, keyword);
  return res.status(200).json({
    success: true,
    data: users,
  });
});

const getChats = asyncHandler(async (req, res) => {
  const chats = await chatService.getChats(req.user._id);
  return res.status(200).json({
    success: true,
    data: chats,
  });
});

const getMessages = asyncHandler(async (req, res) => {
  const messages = await chatService.getMessages(req.user._id, req.params.chatId);
  return res.status(200).json({
    success: true,
    data: messages,
  });
});

const sendMessage = asyncHandler(async (req, res) => {
  const { receiverId, chatId, text } = req.body;

  const message = await chatService.sendMessage({
    senderId: req.user._id,
    receiverId,
    chatId,
    text,
  });

  emitReceiveMessage(message);

  return res.status(201).json({
    success: true,
    data: message,
  });
});

module.exports = {
  searchUsers,
  getChats,
  getMessages,
  sendMessage,
};
