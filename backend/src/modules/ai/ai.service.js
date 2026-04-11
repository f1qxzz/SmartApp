const OpenAI = require('openai');
const Finance = require('../finance/finance.model');

function buildPrompt(financeData, userQuestion) {
  return [
    'Berikut data pengeluaran user (JSON):',
    JSON.stringify(financeData, null, 2),
    '',
    `Pertanyaan user: ${userQuestion}`,
    '',
    'Tugas:',
    '- Berikan analisis singkat, jelas, dan actionable dalam Bahasa Indonesia.',
    '- Jika ada pola boros, sebutkan kategorinya.',
    '- Berikan 3 saran konkret yang realistis.',
  ].join('\n');
}

async function collectFinanceSummary(userId) {
  const transactions = await Finance.find({ userId }).sort({ date: -1 }).limit(200);

  const total = transactions.reduce((sum, item) => sum + item.amount, 0);
  const byCategory = transactions.reduce((acc, item) => {
    const key = item.category || 'other';
    acc[key] = (acc[key] || 0) + item.amount;
    return acc;
  }, {});

  return {
    total,
    transactionCount: transactions.length,
    topCategories: Object.entries(byCategory)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([category, amount]) => ({ category, amount })),
    latestTransactions: transactions.slice(0, 20).map((item) => ({
      amount: item.amount,
      category: item.category,
      description: item.description,
      date: item.date,
    })),
  };
}

async function askAI({ userId, message }) {
  if (!process.env.OPENAI_API_KEY) {
    const error = new Error('OPENAI_API_KEY is not configured');
    error.statusCode = 500;
    throw error;
  }

  const financeSummary = await collectFinanceSummary(userId);
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

  const response = await client.chat.completions.create({
    model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
    temperature: 0.4,
    max_tokens: 500,
    messages: [
      {
        role: 'system',
        content: 'You are a helpful financial assistant for the SmartLife app. You analyze user spending and provide advice based on their transaction data.',
      },
      {
        role: 'user',
        content: buildPrompt(financeSummary, message),
      },
    ],
  });

  const outputText = response.choices[0]?.message?.content || '';
  if (!outputText.trim()) {
    return 'Maaf, saya belum bisa memproses jawaban saat ini. Coba lagi beberapa saat.';
  }

  return outputText.trim();
}

module.exports = {
  askAI,
};
