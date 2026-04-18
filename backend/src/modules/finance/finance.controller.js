const asyncHandler = require('../../middleware/asyncHandler');
const financeService = require('./finance.service');

const getFinance = asyncHandler(async (req, res) => {
  const records = await financeService.listFinance(req.user._id, req.query);
  return res.status(200).json({ success: true, data: records });
});

const createFinance = asyncHandler(async (req, res) => {
  const { title, amount, category, description, date } = req.body;
  const record = await financeService.createFinance(req.user._id, {
    title,
    amount,
    category,
    description,
    date,
  });

  return res.status(201).json({ success: true, data: record });
});

const updateFinance = asyncHandler(async (req, res) => {
  const updated = await financeService.updateFinance(req.user._id, req.params.id, req.body);
  return res.status(200).json({ success: true, data: updated });
});

const deleteFinance = asyncHandler(async (req, res) => {
  await financeService.deleteFinance(req.user._id, req.params.id);
  return res.status(200).json({ success: true, message: 'Deleted successfully' });
});

const getFinanceStats = asyncHandler(async (req, res) => {
  const stats = await financeService.getFinanceStats(req.user._id, req.user.monthlyBudget);
  return res.status(200).json({ success: true, data: stats });
});

const exportCsv = asyncHandler(async (req, res) => {
  const csv = await financeService.exportFinanceCsv(req.user._id, req.query);
  const now = new Date();
  const fileName = `smartlife-transactions-${now.getFullYear()}-${String(now.getMonth() + 1).padStart(
    2,
    '0'
  )}.csv`;

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
  return res.status(200).send(csv);
});

const getBudget = asyncHandler(async (req, res) => {
  const budget = await financeService.getBudget(req.user._id);
  return res.status(200).json({ success: true, data: budget });
});

const setBudget = asyncHandler(async (req, res) => {
  const budget = await financeService.setBudget(req.user._id, req.body.monthlyBudget);
  return res.status(200).json({ success: true, data: budget, message: 'Budget berhasil diperbarui' });
});

const getSavingsGoals = asyncHandler(async (req, res) => {
  const goals = await financeService.listSavingsGoals(req.user._id);
  return res.status(200).json({ success: true, data: goals });
});

const createSavingsGoal = asyncHandler(async (req, res) => {
  const goal = await financeService.createSavingsGoal(req.user._id, req.body);
  return res.status(201).json({ success: true, data: goal });
});

const updateSavingsGoal = asyncHandler(async (req, res) => {
  const updated = await financeService.updateSavingsGoal(req.user._id, req.params.id, req.body);
  return res.status(200).json({ success: true, data: updated });
});

const deleteSavingsGoal = asyncHandler(async (req, res) => {
  await financeService.deleteSavingsGoal(req.user._id, req.params.id);
  return res.status(200).json({ success: true, message: 'Goal deleted' });
});

const getSubscriptions = asyncHandler(async (req, res) => {
  const subs = await financeService.listSubscriptions(req.user._id);
  return res.status(200).json({ success: true, data: subs });
});

const createSubscription = asyncHandler(async (req, res) => {
  const sub = await financeService.createSubscription(req.user._id, req.body);
  return res.status(201).json({ success: true, data: sub });
});

const updateSubscription = asyncHandler(async (req, res) => {
  const updated = await financeService.updateSubscription(req.user._id, req.params.id, req.body);
  return res.status(200).json({ success: true, data: updated });
});

const deleteSubscription = asyncHandler(async (req, res) => {
  await financeService.deleteSubscription(req.user._id, req.params.id);
  return res.status(200).json({ success: true, message: 'Subscription deleted' });
});

module.exports = {
  getFinance,
  createFinance,
  updateFinance,
  deleteFinance,
  getFinanceStats,
  exportCsv,
  getBudget,
  setBudget,
  getSavingsGoals,
  createSavingsGoal,
  updateSavingsGoal,
  deleteSavingsGoal,
  getSubscriptions,
  createSubscription,
  updateSubscription,
  deleteSubscription,
};
