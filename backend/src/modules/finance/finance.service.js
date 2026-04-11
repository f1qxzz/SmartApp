const mongoose = require('mongoose');
const Finance = require('./finance.model');

function buildQuery(userId, filters) {
  const query = { userId: new mongoose.Types.ObjectId(userId) };

  if (filters.category) {
    query.category = filters.category;
  }

  if (filters.search) {
    query.description = { $regex: filters.search, $options: 'i' };
  }

  if (filters.from || filters.to) {
    query.date = {};
    if (filters.from) query.date.$gte = new Date(filters.from);
    if (filters.to) query.date.$lte = new Date(filters.to);
  }

  return query;
}

async function listFinance(userId, filters = {}) {
  const query = buildQuery(userId, filters);
  return Finance.find(query).sort({ date: -1, createdAt: -1 });
}

async function createFinance(userId, payload) {
  return Finance.create({
    userId,
    amount: payload.amount,
    category: payload.category,
    description: payload.description || '',
    date: payload.date ? new Date(payload.date) : new Date(),
  });
}

async function updateFinance(userId, financeId, payload) {
  const finance = await Finance.findOne({ _id: financeId, userId });
  if (!finance) {
    const error = new Error('Finance record not found');
    error.statusCode = 404;
    throw error;
  }

  if (payload.amount !== undefined) finance.amount = payload.amount;
  if (payload.category !== undefined) finance.category = payload.category;
  if (payload.description !== undefined) finance.description = payload.description;
  if (payload.date !== undefined) finance.date = new Date(payload.date);

  await finance.save();
  return finance;
}

async function deleteFinance(userId, financeId) {
  const finance = await Finance.findOneAndDelete({ _id: financeId, userId });
  if (!finance) {
    const error = new Error('Finance record not found');
    error.statusCode = 404;
    throw error;
  }
}

async function getFinanceStats(userId) {
  const now = new Date();
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfWeek = new Date(startOfDay);
  startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay());
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const [daily, weekly, monthly, categoryBreakdown] = await Promise.all([
    Finance.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId), date: { $gte: startOfDay } } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]),
    Finance.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId), date: { $gte: startOfWeek } } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]),
    Finance.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId), date: { $gte: startOfMonth } } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]),
    Finance.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId), date: { $gte: startOfMonth } } },
      { $group: { _id: '$category', total: { $sum: '$amount' } } },
      { $sort: { total: -1 } },
    ]),
  ]);

  return {
    daily: daily[0]?.total || 0,
    weekly: weekly[0]?.total || 0,
    monthly: monthly[0]?.total || 0,
    categoryBreakdown,
  };
}

module.exports = {
  listFinance,
  createFinance,
  updateFinance,
  deleteFinance,
  getFinanceStats,
};
