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
router.post('/', financeController.createFinance);
router.put('/:id', financeController.updateFinance);
router.delete('/:id', financeController.deleteFinance);

module.exports = router;
