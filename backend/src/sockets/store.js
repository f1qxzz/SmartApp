let ioRef = null;
const onlineUsers = new Map();
const lastSeenUsers = new Map();

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
  lastSeenUsers.delete(userId);
}

function removeUserSocket(userId, socketId) {
  const current = onlineUsers.get(userId);
  if (!current) {
    return null;
  }

  current.delete(socketId);
  if (current.size === 0) {
    onlineUsers.delete(userId);
    const seenAt = new Date();
    lastSeenUsers.set(userId, seenAt);
    return seenAt;
  }

  onlineUsers.set(userId, current);
  return null;
}

function getSocketsByUser(userId) {
  return Array.from(onlineUsers.get(userId) || []);
}

function isUserOnline(userId) {
  return onlineUsers.has(userId);
}

function getUserLastSeen(userId) {
  return lastSeenUsers.get(userId) || null;
}

module.exports = {
  setIO,
  getIO,
  addUserSocket,
  removeUserSocket,
  getSocketsByUser,
  isUserOnline,
  getUserLastSeen,
  onlineUsers,
  lastSeenUsers,
};
