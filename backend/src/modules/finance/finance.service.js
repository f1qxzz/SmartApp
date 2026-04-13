const mongoose = require('mongoose');
const Finance = require('./finance.model');
const User = require('../auth/user.model');

function createHttpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function normalizeTitle(value) {
  return String(value || '').trim();
}

function normalizeCategory(value) {
  return String(value || '').trim();
}

function normalizeDescription(value) {
  return String(value || '').trim();
}

function normalizeAmount(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount)) {
    return NaN;
  }
  return amount;
}

function normalizeDate(value) {
  if (!value) {
    return new Date();
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  return date;
}

function ensureValidPayload(payload, { partial = false } = {}) {
  const validated = {};

  if (!partial || payload.title !== undefined) {
    const title = normalizeTitle(payload.title);
    if (!title) {
      throw createHttpError(400, 'Title wajib diisi');
    }
    validated.title = title;
  }

  if (!partial || payload.amount !== undefined) {
    const amount = normalizeAmount(payload.amount);
    if (!Number.isFinite(amount) || amount <= 0) {
      throw createHttpError(400, 'Amount harus lebih besar dari 0');
    }
    validated.amount = amount;
  }

  if (!partial || payload.category !== undefined) {
    const category = normalizeCategory(payload.category);
    if (!category) {
      throw createHttpError(400, 'Category wajib diisi');
    }
    validated.category = category;
  }

  if (!partial || payload.description !== undefined) {
    validated.description = normalizeDescription(payload.description);
  }

  if (!partial || payload.date !== undefined) {
    const date = normalizeDate(payload.date);
    if (!date) {
      throw createHttpError(400, 'Format tanggal tidak valid');
    }
    validated.date = date;
  }

  return validated;
}

function buildQuery(userId, filters) {
  const query = { userId: new mongoose.Types.ObjectId(userId) };

  if (filters.category) {
    query.category = filters.category;
  }

  if (filters.search) {
    const keyword = String(filters.search).trim();
    if (keyword) {
      query.$or = [
        { title: { $regex: keyword, $options: 'i' } },
        { description: { $regex: keyword, $options: 'i' } },
        { category: { $regex: keyword, $options: 'i' } },
      ];
    }
  }

  if (filters.from || filters.to) {
    query.date = {};
    if (filters.from) {
      const fromDate = new Date(filters.from);
      if (!Number.isNaN(fromDate.getTime())) {
        query.date.$gte = fromDate;
      }
    }
    if (filters.to) {
      const toDate = new Date(filters.to);
      if (!Number.isNaN(toDate.getTime())) {
        query.date.$lte = toDate;
      }
    }
  }

  return query;
}

function escapeCsv(value) {
  const text = String(value ?? '');
  if (text.includes('"') || text.includes(',') || text.includes('\n')) {
    return `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}

async function listFinance(userId, filters = {}) {
  const query = buildQuery(userId, filters);
  return Finance.find(query).sort({ date: -1, createdAt: -1 });
}

async function createFinance(userId, payload) {
  const validated = ensureValidPayload(payload, { partial: false });

  return Finance.create({
    userId,
    title: validated.title,
    amount: validated.amount,
    category: validated.category,
    description: validated.description,
    date: validated.date,
  });
}

async function updateFinance(userId, financeId, payload) {
  const finance = await Finance.findOne({ _id: financeId, userId });
  if (!finance) {
    throw createHttpError(404, 'Finance record not found');
  }

  const validated = ensureValidPayload(payload, { partial: true });

  if (validated.title !== undefined) finance.title = validated.title;
  if (validated.amount !== undefined) finance.amount = validated.amount;
  if (validated.category !== undefined) finance.category = validated.category;
  if (validated.description !== undefined) finance.description = validated.description;
  if (validated.date !== undefined) finance.date = validated.date;

  await finance.save();
  return finance;
}

async function deleteFinance(userId, financeId) {
  const finance = await Finance.findOneAndDelete({ _id: financeId, userId });
  if (!finance) {
    throw createHttpError(404, 'Finance record not found');
  }
}

async function getFinanceStats(userId, monthlyBudget) {
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

  const budget = Number(monthlyBudget || 0);
  const monthlyTotal = Number(monthly[0]?.total || 0);
  const remaining = Math.max(0, budget - monthlyTotal);
  const percentageUsed = budget > 0 ? Math.min(100, (monthlyTotal / budget) * 100) : 0;

  return {
    daily: Number(daily[0]?.total || 0),
    weekly: Number(weekly[0]?.total || 0),
    monthly: monthlyTotal,
    categoryBreakdown,
    budget,
    remaining,
    percentageUsed,
  };
}

async function exportFinanceCsv(userId, filters = {}) {
  const records = await listFinance(userId, filters);

  const header = ['Title', 'Amount', 'Category', 'Description', 'Date'];
  const lines = [
    header.join(','),
    ...records.map((item) =>
      [
        escapeCsv(item.title),
        escapeCsv(item.amount),
        escapeCsv(item.category),
        escapeCsv(item.description || ''),
        escapeCsv(item.date.toISOString()),
      ].join(',')
    ),
  ];

  return lines.join('\n');
}

async function getBudget(userId) {
  const user = await User.findById(userId).select('monthlyBudget');
  if (!user) {
    throw createHttpError(404, 'User not found');
  }

  return {
    monthlyBudget: Number(user.monthlyBudget || 0),
  };
}

async function setBudget(userId, monthlyBudget) {
  const value = Number(monthlyBudget);
  if (!Number.isFinite(value) || value < 0) {
    throw createHttpError(400, 'Budget harus angka >= 0');
  }

  const user = await User.findById(userId);
  if (!user) {
    throw createHttpError(404, 'User not found');
  }

  user.monthlyBudget = value;
  await user.save();

  return {
    monthlyBudget: Number(user.monthlyBudget || 0),
  };
}

module.exports = {
  listFinance,
  createFinance,
  updateFinance,
  deleteFinance,
  getFinanceStats,
  exportFinanceCsv,
  getBudget,
  setBudget,
};
