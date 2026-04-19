const lifeHubService = require('./lifehub.service');

class LifeHubController {
  // Habit Handlers
  async getHabits(req, res, next) {
    try {
      const habits = await lifeHubService.getHabits(req.user.id);
      res.status(200).json({ success: true, data: habits });
    } catch (error) {
      next(error);
    }
  }

  async createHabit(req, res, next) {
    try {
      const habit = await lifeHubService.createHabit(req.user.id, req.body);
      res.status(201).json({ success: true, data: habit });
    } catch (error) {
      next(error);
    }
  }

  async updateHabit(req, res, next) {
    try {
      const habit = await lifeHubService.updateHabit(req.params.id, req.user.id, req.body);
      if (!habit) {
        return res.status(404).json({ success: false, message: 'Habit not found' });
      }
      res.status(200).json({ success: true, data: habit });
    } catch (error) {
      next(error);
    }
  }

  async deleteHabit(req, res, next) {
    try {
      const habit = await lifeHubService.deleteHabit(req.params.id, req.user.id);
      if (!habit) {
        return res.status(404).json({ success: false, message: 'Habit not found' });
      }
      res.status(200).json({ success: true, message: 'Habit deleted' });
    } catch (error) {
      next(error);
    }
  }

  async toggleHabit(req, res, next) {
    try {
      const habit = await lifeHubService.toggleHabit(req.params.id, req.user.id);
      if (!habit) {
        return res.status(404).json({ success: false, message: 'Habit not found' });
      }
      res.status(200).json({ success: true, data: habit });
    } catch (error) {
      next(error);
    }
  }

  // Goal Handlers
  async getGoals(req, res, next) {
    try {
      const goals = await lifeHubService.getGoals(req.user.id);
      res.status(200).json({ success: true, data: goals });
    } catch (error) {
      next(error);
    }
  }

  async createGoal(req, res, next) {
    try {
      const goal = await lifeHubService.createGoal(req.user.id, req.body);
      res.status(201).json({ success: true, data: goal });
    } catch (error) {
      next(error);
    }
  }

  async updateGoal(req, res, next) {
    try {
      const goal = await lifeHubService.updateGoal(req.params.id, req.user.id, req.body);
      if (!goal) {
        return res.status(404).json({ success: false, message: 'Goal not found' });
      }
      res.status(200).json({ success: true, data: goal });
    } catch (error) {
      next(error);
    }
  }

  async deleteGoal(req, res, next) {
    try {
      const goal = await lifeHubService.deleteGoal(req.params.id, req.user.id);
      if (!goal) {
        return res.status(404).json({ success: false, message: 'Goal not found' });
      }
      res.status(200).json({ success: true, message: 'Goal deleted' });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new LifeHubController();
