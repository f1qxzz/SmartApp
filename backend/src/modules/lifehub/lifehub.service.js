const Habit = require('./habit.model');
const LifeGoal = require('./life_goal.model');

class LifeHubService {
  // Habit Methods
  async getHabits(userId) {
    const habits = await Habit.find({ userId }).sort({ createdAt: -1 });
    const processedHabits = [];

    for (let habit of habits) {
      const updated = await this._processHabitStreak(habit);
      processedHabits.push(updated);
    }

    return processedHabits;
  }

  async _processHabitStreak(habit) {
    const now = new Date();
    const today = now.toDateString();

    if (!habit.lastCompletedAt) {
      if (habit.isCompletedToday) {
        habit.isCompletedToday = false;
        habit.streak = 0;
        await habit.save();
      }
      return habit;
    }

    const last = new Date(habit.lastCompletedAt);
    const lastDay = last.toDateString();

    // If it's a new day, reset isCompletedToday
    if (today !== lastDay) {
      habit.isCompletedToday = false;

      // Check if missed yesterday
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayDay = yesterday.toDateString();

      // If last completed date was not yesterday, reset streak
      if (lastDay !== yesterdayDay) {
        habit.streak = 0;
      }

      await habit.save();
    }

    return habit;
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
    let habit = await Habit.findOne({ _id: id, userId });
    if (!habit) return null;

    // First, process the current state (in case they open app after midnight)
    habit = await this._processHabitStreak(habit);

    const isNowCompleting = !habit.isCompletedToday;
    const now = new Date();

    if (isNowCompleting) {
      // Logic for incrementing streak
      const last = habit.lastCompletedAt ? new Date(habit.lastCompletedAt) : null;
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);

      if (!last || last.toDateString() === yesterday.toDateString()) {
        habit.streak += 1;
      } else {
        // Break in streak, reset to 1
        habit.streak = 1;
      }
      habit.isCompletedToday = true;
      habit.lastCompletedAt = now;
    } else {
      // Unchecking today - revert streak
      habit.streak = Math.max(0, habit.streak - 1);
      habit.isCompletedToday = false;
      // We don't necessarily reset lastCompletedAt here to keep the history 
      // of when they *last* did it, but it might interfere with logic.
      // Actually, if they uncheck, lastCompletedAt should probably revert too 
      // but we don't have historical data. 
      // For simplicity, let's just clear completion for today.
    }

    return await habit.save();
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
