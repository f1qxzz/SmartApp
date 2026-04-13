const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, trim: true, default: '' },
    username: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      minlength: 3,
      maxlength: 30,
      index: true,
    },
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
    isSystem: { type: Boolean, default: false, index: true },
    monthlyBudget: { type: Number, default: 5000000, min: 0 },
    tokenVersion: { type: Number, default: 0, min: 0 },
    resetPasswordToken: { type: String, default: '', trim: true, index: true },
    resetPasswordExpires: { type: Date, default: null, index: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
