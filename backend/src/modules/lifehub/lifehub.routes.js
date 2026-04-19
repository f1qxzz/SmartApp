const express = require('express');
const lifeHubController = require('./lifehub.controller');
const authMiddleware = require('../../middleware/auth.middleware');

const router = express.Router();

router.use(authMiddleware);

// Habits
router.get('/habits', lifeHubController.getHabits);
router.post('/habits', lifeHubController.createHabit);
router.put('/habits/:id', lifeHubController.updateHabit);
router.delete('/habits/:id', lifeHubController.deleteHabit);
router.patch('/habits/:id/toggle', lifeHubController.toggleHabit);

// Goals
router.get('/goals', lifeHubController.getGoals);
router.post('/goals', lifeHubController.createGoal);
router.put('/goals/:id', lifeHubController.updateGoal);
router.delete('/goals/:id', lifeHubController.deleteGoal);

module.exports = router;
