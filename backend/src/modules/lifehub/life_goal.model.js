const mongoose = require('mongoose');

const lifeGoalSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: { type: String, required: true, trim: true },
    progress: { type: Number, default: 0, min: 0, max: 1 },
    deadline: { type: String, default: '' },
    category: { type: String, default: 'General' },
    isCompleted: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('LifeGoal', lifeGoalSchema);
