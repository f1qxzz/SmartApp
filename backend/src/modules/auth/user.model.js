const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, trim: true, default: '' },
    bio: { type: String, trim: true, default: '', maxlength: 200 },
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
    gender: {
      type: String,
      enum: ['', 'male', 'female', 'other'],
      default: '',
      lowercase: true,
      trim: true,
    },
    authProvider: {
      type: String,
      enum: ['local', 'google'],
      default: 'local',
      index: true,
    },
    providerId: { type: String, default: '', trim: true, index: true },
    isSystem: { type: Boolean, default: false, index: true },
    role: {
      type: String,
      enum: ['owner', 'developer', 'staff', 'vanguard', 'ace_tester', 'user'],
      default: 'user',
      index: true,
    },
    monthlyBudget: { type: Number, default: 5000000, min: 0 },
    dateOfBirth: { type: Date, default: null },
    socialGithub: { type: String, default: '', trim: true },
    socialInstagram: { type: String, default: '', trim: true },
    socialDiscord: { type: String, default: '', trim: true },
    socialTelegram: { type: String, default: '', trim: true },
    socialSpotify: { type: String, default: '', trim: true },
    socialTikTok: { type: String, default: '', trim: true },
    tokenVersion: { type: Number, default: 0, min: 0 },
    resetPasswordToken: { type: String, default: '', trim: true, index: true },
    resetPasswordExpires: { type: Date, default: null, index: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
