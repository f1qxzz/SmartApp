const mongoose = require('mongoose');
const Message = require('./message.model');
const User = require('../auth/user.model');
const { isUserOnline } = require('../../sockets/store');

async function listContacts(userId) {
  const users = await User.find({ _id: { $ne: userId } }).select('name email avatar').sort({ name: 1 });
  return users.map((user) => ({
    _id: user._id,
    name: user.name,
    email: user.email,
    avatar: user.avatar,
    isOnline: isUserOnline(String(user._id)),
  }));
}

async function listMessagesBetweenUsers(userId, receiverId) {
  return Message.find({
    $or: [
      { senderId: userId, receiverId },
      { senderId: receiverId, receiverId: userId },
    ],
  })
    .sort({ timestamp: 1 })
    .populate('senderId', 'name email avatar')
    .populate('receiverId', 'name email avatar');
}

async function listConversations(userId) {
  const objectId = new mongoose.Types.ObjectId(userId);

  const conversations = await Message.aggregate([
    {
      $match: {
        $or: [{ senderId: objectId }, { receiverId: objectId }],
      },
    },
    {
      $project: {
        senderId: 1,
        receiverId: 1,
        text: 1,
        image: 1,
        readStatus: 1,
        timestamp: 1,
        contactId: {
          $cond: [{ $eq: ['$senderId', objectId] }, '$receiverId', '$senderId'],
        },
      },
    },
    { $sort: { timestamp: -1 } },
    {
      $group: {
        _id: '$contactId',
        lastMessage: { $first: '$text' },
        lastImage: { $first: '$image' },
        lastTimestamp: { $first: '$timestamp' },
      },
    },
    {
      $lookup: {
        from: 'messages',
        let: { contactId: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$senderId', '$$contactId'] },
                  { $eq: ['$receiverId', objectId] },
                  { $eq: ['$readStatus', false] },
                ],
              },
            },
          },
          { $count: 'count' },
        ],
        as: 'unreadMeta',
      },
    },
    {
      $lookup: {
        from: 'users',
        localField: '_id',
        foreignField: '_id',
        as: 'contact',
      },
    },
    { $unwind: '$contact' },
    {
      $project: {
        _id: 0,
        contact: {
          id: '$contact._id',
          name: '$contact.name',
          email: '$contact.email',
          avatar: '$contact.avatar',
        },
        lastMessage: {
          $cond: [{ $gt: [{ $strLenCP: '$lastMessage' }, 0] }, '$lastMessage', '[Image]'],
        },
        lastTimestamp: '$lastTimestamp',
        unreadCount: {
          $ifNull: [{ $arrayElemAt: ['$unreadMeta.count', 0] }, 0],
        },
      },
    },
    { $sort: { lastTimestamp: -1 } },
  ]);

  return conversations.map((item) => ({
    ...item,
    contact: {
      ...item.contact,
      isOnline: isUserOnline(String(item.contact.id)),
    },
  }));
}

async function sendMessage(payload) {
  const message = await Message.create({
    senderId: payload.senderId,
    receiverId: payload.receiverId,
    text: payload.text || '',
    image: payload.image || '',
    timestamp: payload.timestamp || new Date(),
  });

  return Message.findById(message._id)
    .populate('senderId', 'name email avatar')
    .populate('receiverId', 'name email avatar');
}

async function markConversationAsRead(userId, withUserId) {
  await Message.updateMany(
    {
      senderId: withUserId,
      receiverId: userId,
      readStatus: false,
    },
    { $set: { readStatus: true } }
  );
}

module.exports = {
  listContacts,
  listMessagesBetweenUsers,
  listConversations,
  sendMessage,
  markConversationAsRead,
};
