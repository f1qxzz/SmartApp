const mongoose = require('mongoose');
const Chat = require('./chat.model');
const Message = require('./message.model');
const User = require('../auth/user.model');
const { isUserOnline, getUserLastSeen } = require('../../sockets/store');

function createHttpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function toObjectId(value) {
  if (value instanceof mongoose.Types.ObjectId) {
    return value;
  }
  return new mongoose.Types.ObjectId(value);
}

function normalizeKeyword(value) {
  return String(value || '').trim();
}

function toChatUser(user) {
  const lastSeen = getUserLastSeen(String(user._id));
  return {
    id: String(user._id),
    username: user.username,
    avatar: user.avatar || '',
    isOnline: isUserOnline(String(user._id)),
    lastSeen: lastSeen ? lastSeen.toISOString() : null,
  };
}

function toConversation(chat, currentUserId) {
  const otherUser = (chat.participants || []).find(
    (participant) => String(participant._id) !== String(currentUserId)
  );

  return {
    chatId: String(chat._id),
    otherUser: otherUser ? toChatUser(otherUser) : null,
    lastMessage: chat.lastMessage || '',
    updatedAt: chat.updatedAt,
    unreadCount: 0,
  };
}

function toMessagePayload(message, receiverId) {
  return {
    _id: String(message._id),
    chatId: String(message.chatId),
    senderId: {
      _id: String(message.senderId._id || message.senderId),
      username: message.senderId.username || '',
      avatar: message.senderId.avatar || '',
    },
    receiverId: String(receiverId),
    text: message.text || '',
    messageType: message.messageType || 'text',
    attachmentUrl: message.attachmentUrl || '',
    createdAt: message.createdAt,
  };
}

function buildLastMessagePreview(messageType, text) {
  const normalizedText = String(text || '').trim();
  const type = String(messageType || 'text').toLowerCase().trim();

  if (type === 'text') {
    return normalizedText;
  }

  if (type === 'image') {
    return normalizedText ? `Gambar: ${normalizedText}` : 'Gambar';
  }

  if (type === 'audio' || type === 'voice') {
    return 'Voice note';
  }

  if (type === 'file') {
    return normalizedText ? `File: ${normalizedText}` : 'File';
  }

  return normalizedText || `[${type}]`;
}

async function findUserOrThrow(userId) {
  const user = await User.findOne({
    _id: userId,
    isSystem: { $ne: true },
    username: { $exists: true, $ne: '' },
  }).select('_id username avatar');

  if (!user) {
    throw createHttpError(404, 'User tidak ditemukan');
  }

  return user;
}

async function searchUsers(currentUserId, keyword) {
  const normalizedKeyword = normalizeKeyword(keyword);

  const query = {
    _id: { $ne: toObjectId(currentUserId) },
    isSystem: { $ne: true },
    username: { $exists: true, $ne: '' },
  };

  if (normalizedKeyword) {
    query.username = { $regex: normalizedKeyword, $options: 'i' };
  }

  const users = await User.find(query)
    .select('_id username avatar')
    .sort({ username: 1 })
    .limit(20);

  return users.map((user) => toChatUser(user));
}

async function getChats(currentUserId) {
  const chats = await Chat.find({
    participants: toObjectId(currentUserId),
  })
    .populate({
      path: 'participants',
      select: '_id username avatar isSystem',
      match: {
        isSystem: { $ne: true },
        username: { $exists: true, $ne: '' },
      },
    })
    .sort({ updatedAt: -1 });

  return chats
    .map((chat) => toConversation(chat, currentUserId))
    .filter((chat) => chat.otherUser);
}

async function ensureChatBetweenUsers(userId, otherUserId) {
  if (String(userId) === String(otherUserId)) {
    throw createHttpError(400, 'Tidak bisa chat dengan akun sendiri');
  }

  await findUserOrThrow(otherUserId);

  const participants = [toObjectId(userId), toObjectId(otherUserId)];

  let chat = await Chat.findOne({
    participants: { $all: participants },
    $expr: { $eq: [{ $size: '$participants' }, 2] },
  });

  if (!chat) {
    chat = await Chat.create({
      participants,
      lastMessage: '',
    });
  }

  return chat;
}

async function getChatById(currentUserId, chatId) {
  if (!mongoose.Types.ObjectId.isValid(chatId)) {
    throw createHttpError(400, 'chatId tidak valid');
  }

  const chat = await Chat.findOne({
    _id: toObjectId(chatId),
    participants: toObjectId(currentUserId),
  });

  if (!chat) {
    throw createHttpError(404, 'Chat tidak ditemukan atau tidak memiliki akses');
  }

  return chat;
}

async function getMessages(currentUserId, chatId) {
  await getChatById(currentUserId, chatId);

  const messages = await Message.find({ chatId: toObjectId(chatId) })
    .populate('senderId', '_id username avatar')
    .sort({ createdAt: 1 });

  return messages.map((message) => ({
    _id: String(message._id),
    chatId: String(message.chatId),
    senderId: {
      _id: String(message.senderId._id || ''),
      username: message.senderId.username || '',
      avatar: message.senderId.avatar || '',
    },
    text: message.text || '',
    messageType: message.messageType,
    attachmentUrl: message.attachmentUrl,
    createdAt: message.createdAt,
  }));
}

async function sendMessage({
  senderId,
  receiverId,
  chatId,
  text,
  messageType = 'text',
  attachmentUrl = '',
}) {
  const normalizedText = String(text || '').trim();

  let chat = null;
  let targetUserId = receiverId ? String(receiverId) : '';

  if (chatId) {
    chat = await getChatById(senderId, chatId);
    const participants = chat.participants.map((participant) => String(participant));
    targetUserId =
      participants.find((participantId) => participantId !== String(senderId)) || '';
  } else if (receiverId) {
    chat = await ensureChatBetweenUsers(senderId, receiverId);
  } else {
    throw createHttpError(400, 'chatId atau receiverId wajib diisi');
  }

  if (!targetUserId) {
    throw createHttpError(400, 'Target user chat tidak ditemukan');
  }

  const createdMessage = await Message.create({
    chatId: chat._id,
    senderId: toObjectId(senderId),
    text: normalizedText,
    messageType,
    attachmentUrl,
  });

  chat.lastMessage = buildLastMessagePreview(messageType, normalizedText);
  chat.updatedAt = createdMessage.createdAt;
  await chat.save();

  const message = await Message.findById(createdMessage._id).populate(
    'senderId',
    '_id username avatar'
  );

  return toMessagePayload(message, targetUserId);
}

async function deleteMessage(currentUserId, messageId) {
  const message = await Message.findById(messageId);
  if (!message) {
    throw createHttpError(404, 'Pesan tidak ditemukan');
  }

  if (String(message.senderId) !== String(currentUserId)) {
    throw createHttpError(403, 'Tidak diizinkan menghapus pesan orang lain');
  }

  await Message.deleteOne({ _id: messageId });
  return { success: true };
}

async function deleteConversation(currentUserId, chatId) {
  const chat = await getChatById(currentUserId, chatId);

  // In this simple implementation, we delete all messages and the chat object.
  // In a production app, we might want to just hide it for this user.
  await Message.deleteMany({ chatId: chat._id });
  await Chat.deleteOne({ _id: chat._id });

  return { success: true };
}

module.exports = {
  searchUsers,
  getChats,
  getMessages,
  sendMessage,
  deleteMessage,
  deleteConversation,
};
