const mongoose = require('mongoose');

const savingsGoalSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: { type: String, required: true, trim: true },
    targetAmount: { type: Number, required: true, min: 0.01 },
    currentAmount: { type: Number, default: 0, min: 0 },
    deadline: { type: Date, default: null },
    color: { type: String, default: '#6366F1' }, // Hex code
    icon: { type: String, default: 'wallet_rounded' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('SavingsGoal', savingsGoalSchema);
