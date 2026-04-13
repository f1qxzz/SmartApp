const { getIO } = require('./store');

function emitToUser(userId, event, payload) {
  const io = getIO();
  if (!io) return;

  io.to(String(userId)).emit(event, payload);
}

function broadcastOnlineStatus(userId, online) {
  const io = getIO();
  if (!io) return;
  io.emit('presence:update', { userId: String(userId), online });
}

function emitReceiveMessage(message) {
  const senderId = String(message.senderId._id || message.senderId || '');
  const receiverId = String(message.receiverId || '');

  if (senderId) {
    emitToUser(senderId, 'receive_message', message);
    emitToUser(senderId, 'chat:new', message);
  }

  if (receiverId && receiverId !== senderId) {
    emitToUser(receiverId, 'receive_message', message);
    emitToUser(receiverId, 'chat:new', message);
  }
}

function emitTyping({ fromUserId, toUserId, isTyping }) {
  emitToUser(toUserId, 'typing_status', {
    fromUserId: String(fromUserId),
    isTyping: Boolean(isTyping),
  });
  emitToUser(toUserId, 'chat:typing', {
    fromUserId: String(fromUserId),
    isTyping: Boolean(isTyping),
  });
}

function emitConversationRead({ userId, withUserId }) {
  emitToUser(withUserId, 'chat:read', {
    byUserId: String(userId),
    withUserId: String(withUserId),
  });
}

module.exports = {
  emitToUser,
  emitReceiveMessage,
  emitTyping,
  emitConversationRead,
  broadcastOnlineStatus,
};
