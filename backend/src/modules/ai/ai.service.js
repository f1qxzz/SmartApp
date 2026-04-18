const { GoogleGenerativeAI } = require('@google/generative-ai');
const Finance = require('../finance/finance.model');

function getModelCandidates() {
  const primary = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
  const fallbacks = (process.env.GEMINI_FALLBACK_MODELS || 'gemini-flash-latest')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  return Array.from(new Set([primary, ...fallbacks]));
}

function buildPrompt(financeData, userQuestion) {
  return [
    'Kamu adalah asisten keuangan yang cerdas pada aplikasi SmartLife.',
    'Tugasmu: analisis data pengeluaran user dan berikan saran yang actionable dalam Bahasa Indonesia.',
    '',
    'Berikut data pengeluaran user (JSON):',
    JSON.stringify(financeData, null, 2),
    '',
    `Pertanyaan user: ${userQuestion}`,
    '',
    'Instruksi Penting:',
    '- Format jawaban: HARUS berbentuk teks paragraf biasa. DILARANG KERAS menggunakan tanda bintang (*) atau format markdown apapun.',
    '- Jawaban harus RINGKAS tapi sangat DETAIL (high information density). Langsung ke poin permasalahan tanpa kata pengantar bertele-tele.',
    '- Jika ada pola boros, sebutkan kategorinya dengan spesifik dan angka pengeluarannya.',
    '- Berikan 3 saran konkret yang realistis menggunakan format penomoran angka biasa (1. 2. 3.).',
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
  const prompt = buildPrompt(financeSummary, message);

  if (!process.env.GEMINI_API_KEY) {
    return buildFallbackAnswer({
      financeSummary,
      reason: 'GEMINI_API_KEY belum dikonfigurasi',
    });
  }

  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const modelCandidates = getModelCandidates();
  let lastError = null;

  for (const modelName of modelCandidates) {
    try {
      const model = genAI.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(prompt);
      const outputText = result.response.text() || '';

      if (outputText.trim()) {
        return outputText.trim();
      }
    } catch (error) {
      lastError = error;
    }
  }

  const errorMsg = String(lastError?.message || '').toLowerCase();
  let reason;

  if (!lastError) {
    reason = 'Gemini mengembalikan respons kosong';
  } else if (errorMsg.includes('429') || errorMsg.includes('quota') || errorMsg.includes('resource_exhausted')) {
    reason = 'Kuota Gemini AI habis. Coba lagi besok atau upgrade ke paid plan.';
  } else if (errorMsg.includes('503') || errorMsg.includes('service unavailable') || errorMsg.includes('high demand')) {
    reason = 'Gemini AI sedang sibuk karena traffic tinggi. Coba lagi sebentar lagi.';
  } else if (errorMsg.includes('api key') || errorMsg.includes('invalid')) {
    reason = 'API Key Gemini tidak valid. Silakan cek konfigurasi.';
  } else if (errorMsg.includes('not found')) {
    reason = 'Model Gemini tidak ditemukan. Silakan cek GEMINI_MODEL.';
  } else {
    reason = 'Gemini AI sedang tidak tersedia. Coba lagi nanti.';
  }

  return buildFallbackAnswer({
    financeSummary,
    reason,
  });
}

function buildFallbackAnswer({ financeSummary, reason }) {
  const total = Number(financeSummary.total || 0);
  const topCategory = financeSummary.topCategories[0];
  const average = financeSummary.transactionCount > 0
    ? total / financeSummary.transactionCount
    : 0;

  const lines = [
    `AI sementara tidak tersedia (${reason}).`,
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

async function summarizeChat({ chatId, userId }) {
  // 1. Fetch the last 50 messages from this chat
  const messages = await require('../chat/message.model')
    .find({ chatId })
    .populate('senderId', 'username role')
    .sort({ createdAt: -1 })
    .limit(50);

  if (messages.length === 0) {
    return 'Belum ada percakapan yang bisa diringkas.';
  }

  // 2. Reverse to get chronological order and format for prompt
  const chatTranscript = messages
    .reverse()
    .map((msg) => {
      const sender = msg.senderId?.username || 'Unknown';
      const role = msg.senderId?.role || 'user';
      return `[${role.toUpperCase()}] ${sender}: ${msg.text}`;
    })
    .join('\n');

  // 3. Build prompt
  const prompt = [
    'Kamu adalah asisten pengelola percakapan SmartLife.',
    'Tugasmu: ringkas percakapan berikut menjadi poin-poin penting yang actionable dalam Bahasa Indonesia.',
    'Fokus pada: permintaan user, solusi yang diberikan staff/owner, dan status akhir (selesai/menunggu).',
    '',
    'Berikut transkrip percakapan:',
    chatTranscript,
    '',
    'Instruksi Output:',
    '- DILARANG KERAS menggunakan tanda bintang (*) atau format markdown. Gunakan penomoran angka biasa (1., 2., 3.).',
    '- Buat menjadi ringkas tapi sangat detail (maksimal 5 poin).',
    '- Gunakan nada profesional namun ramah.',
  ].join('\n');

  // 4. Call Gemini
  if (!process.env.GEMINI_API_KEY) {
    return 'Gagal membuat ringkasan: API Key belum dikonfigurasi.';
  }

  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const modelCandidates = getModelCandidates();

  for (const modelName of modelCandidates) {
    try {
      const model = genAI.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(prompt);
      const outputText = result.response.text() || '';

      if (outputText.trim()) {
        return outputText.trim();
      }
    } catch (error) {
      // Continue to next model if fails
    }
  }

  return 'Maaf, sistem AI sedang sibuk. Gagal membuat ringkasan saat ini.';
}

module.exports = {
  askAI,
  summarizeChat,
};
