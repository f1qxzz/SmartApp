const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../modules/auth/user.model');
const chatService = require('../modules/chat/chat.service');
const {
  setIO,
  addUserSocket,
  removeUserSocket,
  getSocketsByUser,
  getUserLastSeen,
} = require('./store');
const { emitReceiveMessage, emitTyping, broadcastOnlineStatus } = require('./events');

function resolveToken(socket) {
  const authToken = socket.handshake.auth?.token;
  const queryToken = socket.handshake.query?.token;
  return String(authToken || queryToken || '').trim();
}

function toUserId(value) {
  return String(value || '');
}

function initSocketServer(server) {
  const io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  setIO(io);

  io.use(async (socket, next) => {
    try {
      const token = resolveToken(socket);
      if (!token) {
        return next(new Error('Unauthorized'));
      }

      const payload = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(payload.userId).select('_id username avatar isSystem');

      if (!user || user.isSystem) {
        return next(new Error('Unauthorized'));
      }

      if (Number(payload.tv || 0) !== Number(user.tokenVersion || 0)) {
        return next(new Error('Unauthorized'));
      }

      socket.user = user;
      return next();
    } catch (error) {
      return next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    const userId = toUserId(socket.user?._id);
    addUserSocket(userId, socket.id);
    socket.join(userId);

    if (getSocketsByUser(userId).length === 1) {
      broadcastOnlineStatus(userId, true, null);
    }

    const handleSendMessage = async (payload = {}) => {
      try {
        const message = await chatService.sendMessage({
          senderId: userId,
          receiverId: payload.receiverId,
          chatId: payload.chatId,
          text: payload.text,
        });

        emitReceiveMessage(message);
      } catch (error) {
        socket.emit('chat_error', {
          message: error.message || 'Gagal mengirim pesan',
        });
      }
    };

    socket.on('send_message', handleSendMessage);

    // Backward compatibility
    socket.on('chat:send', handleSendMessage);

    socket.on('typing', ({ toUserId, isTyping }) => {
      if (!toUserId) return;
      emitTyping({
        fromUserId: userId,
        toUserId,
        isTyping,
      });
    });

    socket.on('chat:typing', ({ toUserId, isTyping }) => {
      if (!toUserId) return;
      emitTyping({
        fromUserId: userId,
        toUserId,
        isTyping,
      });
    });

    socket.on('disconnect', () => {
      const disconnectedAt = removeUserSocket(userId, socket.id);
      if (getSocketsByUser(userId).length === 0) {
        broadcastOnlineStatus(userId, false, disconnectedAt || getUserLastSeen(userId));
      }
    });
  });

  return io;
}

module.exports = {
  initSocketServer,
};
