const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    chatId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Chat',
      required: true,
      index: true,
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    text: {
      type: String,
      required: false,
      trim: true,
      maxlength: 2000,
    },
    messageType: {
      type: String,
      enum: ['text', 'image', 'audio', 'voice', 'document'],
      default: 'text',
    },
    attachmentUrl: {
      type: String,
      default: '',
    },
  },
  { timestamps: true }
);

messageSchema.index({ chatId: 1, createdAt: 1 });

module.exports = mongoose.model('Message', messageSchema);
