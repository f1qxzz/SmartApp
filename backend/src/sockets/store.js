let ioRef = null;
const onlineUsers = new Map();

function setIO(io) {
  ioRef = io;
}

function getIO() {
  return ioRef;
}

function addUserSocket(userId, socketId) {
  const current = onlineUsers.get(userId) || new Set();
  current.add(socketId);
  onlineUsers.set(userId, current);
}

function removeUserSocket(userId, socketId) {
  const current = onlineUsers.get(userId);
  if (!current) return;

  current.delete(socketId);
  if (current.size === 0) {
    onlineUsers.delete(userId);
    return;
  }

  onlineUsers.set(userId, current);
}

function getSocketsByUser(userId) {
  return Array.from(onlineUsers.get(userId) || []);
}

function isUserOnline(userId) {
  return onlineUsers.has(userId);
}

module.exports = {
  setIO,
  getIO,
  addUserSocket,
  removeUserSocket,
  getSocketsByUser,
  isUserOnline,
  onlineUsers,
};
