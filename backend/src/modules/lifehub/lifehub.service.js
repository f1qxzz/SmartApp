const Habit = require('./habit.model');
const LifeGoal = require('./life_goal.model');

class LifeHubService {
  // Habit Methods
  async getHabits(userId) {
    return await Habit.find({ userId }).sort({ createdAt: -1 });
  }

  async createHabit(userId, data) {
    return await Habit.create({ ...data, userId });
  }

  async updateHabit(id, userId, data) {
    return await Habit.findOneAndUpdate({ _id: id, userId }, data, { new: true });
  }

  async deleteHabit(id, userId) {
    return await Habit.findOneAndDelete({ _id: id, userId });
  }

  async toggleHabit(id, userId) {
    const habit = await Habit.findOne({ _id: id, userId });
    if (!habit) return null;

    const nextStatus = !habit.isCompletedToday;
    const nextStreak = nextStatus ? habit.streak + 1 : Math.max(0, habit.streak - 1);

    return await Habit.findOneAndUpdate(
      { _id: id, userId },
      { isCompletedToday: nextStatus, streak: nextStreak },
      { new: true }
    );
  }

  // Goal Methods
  async getGoals(userId) {
    return await LifeGoal.find({ userId }).sort({ createdAt: -1 });
  }

  async createGoal(userId, data) {
    return await LifeGoal.create({ ...data, userId });
  }

  async updateGoal(id, userId, data) {
    if (data.progress !== undefined) {
      data.isCompleted = data.progress >= 1;
    }
    return await LifeGoal.findOneAndUpdate({ _id: id, userId }, data, { new: true });
  }

  async deleteGoal(id, userId) {
    return await LifeGoal.findOneAndDelete({ _id: id, userId });
  }
}

module.exports = new LifeHubService();
