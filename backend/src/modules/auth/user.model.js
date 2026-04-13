const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, minlength: 2 },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    password: { type: String, minlength: 6 },
    avatar: { type: String, default: '' },
    authProvider: {
      type: String,
      enum: ['local', 'google'],
      default: 'local',
      index: true,
    },
    providerId: { type: String, default: '', trim: true, index: true },
    resetPasswordToken: { type: String, default: '', trim: true, index: true },
    resetPasswordExpires: { type: Date, default: null, index: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
