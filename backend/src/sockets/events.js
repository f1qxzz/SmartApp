const { getIO, getSocketsByUser } = require('./store');

function emitToUser(userId, event, payload) {
  const io = getIO();
  if (!io) return;

  const sockets = getSocketsByUser(String(userId));
  sockets.forEach((socketId) => {
    io.to(socketId).emit(event, payload);
  });
}

function broadcastOnlineStatus(userId, online) {
  const io = getIO();
  if (!io) return;
  io.emit('presence:update', { userId: String(userId), online });
}

function emitNewMessage(message) {
  emitToUser(message.senderId._id || message.senderId, 'chat:new', message);
  emitToUser(message.receiverId._id || message.receiverId, 'chat:new', message);
}

function emitTyping({ fromUserId, toUserId, isTyping }) {
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
  emitNewMessage,
  emitTyping,
  emitConversationRead,
  broadcastOnlineStatus,
};
