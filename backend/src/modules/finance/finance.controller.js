const asyncHandler = require('../../middleware/asyncHandler');
const financeService = require('./finance.service');

const getFinance = asyncHandler(async (req, res) => {
  const records = await financeService.listFinance(req.user._id, req.query);
  return res.status(200).json({ success: true, data: records });
});

const createFinance = asyncHandler(async (req, res) => {
  const { amount, category, description, date } = req.body;
  if (amount === undefined || !category) {
    return res.status(400).json({
      success: false,
      message: 'amount and category are required',
    });
  }

  const record = await financeService.createFinance(req.user._id, {
    amount,
    category,
    description,
    date,
  });

  return res.status(201).json({ success: true, data: record });
});

const updateFinance = asyncHandler(async (req, res) => {
  const updated = await financeService.updateFinance(
    req.user._id,
    req.params.id,
    req.body
  );

  return res.status(200).json({ success: true, data: updated });
});

const deleteFinance = asyncHandler(async (req, res) => {
  await financeService.deleteFinance(req.user._id, req.params.id);
  return res.status(200).json({ success: true, message: 'Deleted successfully' });
});

const getFinanceStats = asyncHandler(async (req, res) => {
  const stats = await financeService.getFinanceStats(req.user._id);
  return res.status(200).json({ success: true, data: stats });
});

module.exports = {
  getFinance,
  createFinance,
  updateFinance,
  deleteFinance,
  getFinanceStats,
};
