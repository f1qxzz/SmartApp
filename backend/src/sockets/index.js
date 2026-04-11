const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../modules/auth/user.model');
const chatService = require('../modules/chat/chat.service');
const {
  setIO,
  addUserSocket,
  removeUserSocket,
  getSocketsByUser,
} = require('./store');
const {
  emitNewMessage,
  emitTyping,
  broadcastOnlineStatus,
} = require('./events');

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
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;
      if (!token) {
        return next(new Error('Unauthorized'));
      }

      const payload = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(payload.userId).select('_id name email avatar');
      if (!user) {
        return next(new Error('Unauthorized'));
      }

      socket.user = user;
      return next();
    } catch (error) {
      return next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    const userId = String(socket.user._id);
    addUserSocket(userId, socket.id);

    if (getSocketsByUser(userId).length === 1) {
      broadcastOnlineStatus(userId, true);
    }

    socket.on('chat:typing', ({ toUserId, isTyping }) => {
      if (!toUserId) return;
      emitTyping({
        fromUserId: userId,
        toUserId,
        isTyping,
      });
    });

    socket.on('chat:send', async ({ receiverId, text, image }) => {
      if (!receiverId || (!text && !image)) return;

      const message = await chatService.sendMessage({
        senderId: userId,
        receiverId,
        text,
        image,
      });

      emitNewMessage(message);
    });

    socket.on('disconnect', () => {
      removeUserSocket(userId, socket.id);
      if (getSocketsByUser(userId).length === 0) {
        broadcastOnlineStatus(userId, false);
      }
    });
  });

  return io;
}

module.exports = {
  initSocketServer,
};
