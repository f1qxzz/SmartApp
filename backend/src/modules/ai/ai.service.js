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
  const financeSummary = await collectFinanceSummary(userId);

  if (!process.env.OPENAI_API_KEY) {
    return buildFallbackAnswer({
      financeSummary,
      reason: 'OPENAI_API_KEY belum dikonfigurasi',
    });
  }

  try {
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
      return buildFallbackAnswer({
        financeSummary,
        reason: 'OpenAI mengembalikan respons kosong',
      });
    }

    return outputText.trim();
  } catch (error) {
    const reason = error?.status === 429
      ? 'Kuota OpenAI habis / limit tercapai'
      : 'OpenAI sedang tidak tersedia';

    return buildFallbackAnswer({
      financeSummary,
      reason,
    });
  }
}

function buildFallbackAnswer({ financeSummary, reason }) {
  const total = Number(financeSummary.total || 0);
  const topCategory = financeSummary.topCategories[0];
  const average = financeSummary.transactionCount > 0
    ? total / financeSummary.transactionCount
    : 0;

  const lines = [
    `OpenAI sementara tidak tersedia (${reason}).`,
    'Berikut analisis cepat dari data real transaksi kamu:',
    `- Total pengeluaran: Rp ${Math.round(total).toLocaleString('id-ID')}`,
    `- Jumlah transaksi: ${financeSummary.transactionCount}`,
    `- Rata-rata per transaksi: Rp ${Math.round(average).toLocaleString('id-ID')}`,
  ];

  if (topCategory) {
    lines.push(
      `- Kategori tertinggi: ${topCategory.category} (Rp ${Math.round(topCategory.amount).toLocaleString('id-ID')})`
    );
  }

  lines.push(
    '',
    'Saran aksi:',
    '1. Tetapkan batas harian untuk kategori terbesar.',
    '2. Evaluasi 3 transaksi terakhir yang bukan kebutuhan utama.',
    '3. Sisihkan tabungan di awal bulan agar disiplin.'
  );

  return lines.join('\n');
}

module.exports = {
  askAI,
};
