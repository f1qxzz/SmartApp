const mongoose = require('mongoose');

const habitSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: { type: String, required: true, trim: true },
    icon: { type: String, default: 'water_drop' },
    streak: { type: Number, default: 0 },
    isCompletedToday: { type: Boolean, default: false },
    lastCompletedAt: { type: Date },
    frequency: { type: String, enum: ['daily', 'weekly'], default: 'daily' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Habit', habitSchema);
