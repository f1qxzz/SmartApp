const asyncHandler = require('../../middleware/asyncHandler');
const chatService = require('./chat.service');
const { emitNewMessage, emitConversationRead } = require('../../sockets/events');

const getChat = asyncHandler(async (req, res) => {
  const withUserId = req.query.with;

  if (withUserId) {
    const messages = await chatService.listMessagesBetweenUsers(req.user._id, withUserId);
    return res.status(200).json({ success: true, data: messages });
  }

  const conversations = await chatService.listConversations(req.user._id);
  return res.status(200).json({ success: true, data: conversations });
});

const getContacts = asyncHandler(async (req, res) => {
  const contacts = await chatService.listContacts(req.user._id);
  return res.status(200).json({ success: true, data: contacts });
});

const postChat = asyncHandler(async (req, res) => {
  const { receiverId, text, image } = req.body;

  if (!receiverId || (!text && !image)) {
    return res.status(400).json({
      success: false,
      message: 'receiverId and text/image are required',
    });
  }

  const message = await chatService.sendMessage({
    senderId: req.user._id,
    receiverId,
    text,
    image,
  });

  emitNewMessage(message);

  return res.status(201).json({ success: true, data: message });
});

const markRead = asyncHandler(async (req, res) => {
  const withUserId = req.params.withUserId;
  await chatService.markConversationAsRead(req.user._id, withUserId);
  emitConversationRead({ userId: String(req.user._id), withUserId });

  return res.status(200).json({ success: true, message: 'Conversation marked as read' });
});

module.exports = {
  getChat,
  getContacts,
  postChat,
  markRead,
};
