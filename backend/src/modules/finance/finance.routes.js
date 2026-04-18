const express = require('express');
const financeController = require('./finance.controller');
const authMiddleware = require('../../middleware/auth.middleware');

const router = express.Router();

router.use(authMiddleware);

router.get('/', financeController.getFinance);
router.get('/stats', financeController.getFinanceStats);
router.get('/export/csv', financeController.exportCsv);
router.get('/budget', financeController.getBudget);
router.put('/budget', financeController.setBudget);

// Savings Goals
router.get('/goals', financeController.getSavingsGoals);
router.post('/goals', financeController.createSavingsGoal);
router.put('/goals/:id', financeController.updateSavingsGoal);
router.delete('/goals/:id', financeController.deleteSavingsGoal);

// Subscriptions
router.get('/subscriptions', financeController.getSubscriptions);
router.post('/subscriptions', financeController.createSubscription);
router.put('/subscriptions/:id', financeController.updateSubscription);
router.delete('/subscriptions/:id', financeController.deleteSubscription);

router.post('/', financeController.createFinance);
router.put('/:id', financeController.updateFinance);
router.delete('/:id', financeController.deleteFinance);

module.exports = router;
