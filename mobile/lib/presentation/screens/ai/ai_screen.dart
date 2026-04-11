import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/config/openai_config.dart';
import 'package:smartlife_app/core/constants/app_constants.dart';
import 'package:smartlife_app/core/services/openai_service.dart';
import 'package:smartlife_app/core/state/app_state.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final OpenAIService _openAIService = OpenAIService();
  bool _isLoading = false;
  List<MockAiMessage> _messages = <MockAiMessage>[];

  final List<(IconData, String)> _suggestions = <(IconData, String)>[
    (Icons.savings_outlined, 'Apakah saya boros bulan ini?'),
    (Icons.lightbulb_outline_rounded, 'Tips hemat bulan ini'),
    (Icons.pie_chart_outline_rounded, 'Kategori terbesar pengeluaran'),
    (Icons.track_changes_rounded, 'Target tabungan yang realistis'),
  ];

  @override
  void initState() {
    super.initState();
    _messages = List<MockAiMessage>.from(mockAiMessages);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _openAIService.dispose();
    super.dispose();
  }

  void _sendMessage(String text, List<MockTransaction> transactions) async {
    final String cleanText = text.trim();
    if (cleanText.isEmpty || _isLoading) {
      return;
    }

    _msgCtrl.clear();
    setState(() {
      _messages.add(
        MockAiMessage(
          text: cleanText,
          isAi: false,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) {
      return;
    }
    final String aiReply = await _buildAiResponse(cleanText, transactions);

    setState(() {
      _isLoading = false;
      _messages.add(
        MockAiMessage(
          text: aiReply,
          isAi: true,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollCtrl.hasClients) {
        return;
      }
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _buildAiResponse(
    String prompt,
    List<MockTransaction> transactions,
  ) async {
    if (!OpenAIConfig.isConfigured) {
      return '${_generateFallbackAiResponse(prompt, transactions)}\n\n'
          'Catatan: OPENAI_API_KEY belum diatur, jadi masih pakai mode lokal.';
    }

    try {
      return await _openAIService.generateFinanceAnswer(
        userPrompt: prompt,
        transactions: transactions,
      );
    } on OpenAIServiceException catch (e) {
      return '${_generateFallbackAiResponse(prompt, transactions)}\n\n'
          'Catatan: gagal terhubung ke OpenAI API ($e).';
    } catch (_) {
      return '${_generateFallbackAiResponse(prompt, transactions)}\n\n'
          'Catatan: terjadi gangguan saat memproses respons OpenAI.';
    }
  }

  String _generateFallbackAiResponse(
    String query,
    List<MockTransaction> transactions,
  ) {
    if (transactions.isEmpty) {
      return 'Belum ada transaksi yang bisa dianalisis. '
          'Tambahkan transaksi dulu agar saya bisa memberi insight yang akurat.';
    }

    final String q = query.toLowerCase();
    final double totalSpent = transactions.fold<double>(
      0,
      (double sum, MockTransaction tx) => sum + tx.amount,
    );
    final double budgetUsage = totalSpent / monthlyBudget;
    final Map<String, double> totalsByCategory = <String, double>{};

    for (final MockTransaction tx in transactions) {
      totalsByCategory.update(
        tx.category,
        (double value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }

    final List<({String name, double amount})> sortedCategories = financeCategories
        .map((FinanceCategory category) {
          return (
            name: category.name,
            amount: totalsByCategory[category.id] ?? 0,
          );
        })
        .where((item) => item.amount > 0)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    if (sortedCategories.isEmpty) {
      return 'Data kategori belum terbaca dengan baik. '
          'Coba tambah transaksi baru agar analisis lebih akurat.';
    }

    final ({String name, double amount}) topCategory = sortedCategories.first;
    final double topCategoryPct = totalSpent == 0 ? 0 : topCategory.amount / totalSpent;

    if (q.contains('boros')) {
      return 'Total pengeluaran kamu ${AppFormatters.currency(totalSpent)} '
          'dari budget ${AppFormatters.currency(monthlyBudget)} '
          '(${(budgetUsage * 100).toStringAsFixed(1)}%).\n\n'
          'Kategori terbesar: ${topCategory.name} '
          '(${(topCategoryPct * 100).toStringAsFixed(0)}%).\n'
          '${budgetUsage >= 0.8 ? 'Kondisi mulai kritis, sebaiknya kurangi belanja non-prioritas.' : 'Kondisi masih aman, pertahankan ritme ini.'}';
    }

    if (q.contains('tips') || q.contains('hemat')) {
      final double potentialSaving = topCategory.amount * 0.15;
      return '3 langkah hemat paling berdampak:\n'
          '1. Pangkas kategori ${topCategory.name} sekitar 10-15%.\n'
          '2. Pisahkan budget kebutuhan harian dan hiburan.\n'
          '3. Transfer tabungan otomatis di awal bulan.\n\n'
          'Estimasi penghematan: ${AppFormatters.currency(potentialSaving)} per bulan.';
    }

    if (q.contains('kategori')) {
      final Iterable<String> lines = sortedCategories.take(3).map((item) {
        final double percentage = totalSpent == 0 ? 0 : item.amount / totalSpent;
        return '- ${item.name}: ${AppFormatters.currency(item.amount)} '
            '(${(percentage * 100).toStringAsFixed(0)}%)';
      });
      return 'Top kategori pengeluaran kamu:\n${lines.join('\n')}';
    }

    if (q.contains('tabungan') || q.contains('target')) {
      final double monthlyPotential =
          (monthlyIncome - totalSpent).clamp(0, monthlyIncome).toDouble();
      final double safeTarget = monthlyPotential * 0.7;
      return 'Estimasi sisa dana bulan ini: ${AppFormatters.currency(monthlyPotential)}.\n'
          'Target tabungan realistis: ${AppFormatters.currency(safeTarget)} per bulan.\n\n'
          'Mulai dari auto-save mingguan agar konsisten.';
    }

    return 'Ringkasan cepat:\n'
        '- Total pengeluaran: ${AppFormatters.currency(totalSpent)}\n'
        '- Kategori terbesar: ${topCategory.name}\n'
        '- Persentase budget terpakai: ${(budgetUsage * 100).toStringAsFixed(1)}%\n\n'
        'Kalau mau, saya bisa bantu buat rencana hemat mingguan dari data ini.';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasOpenAIKey = OpenAIConfig.isConfigured;
    final List<MockTransaction> transactions = ref.watch(financeTransactionsProvider);

    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('SmartLife AI', style: AppTextStyles.heading3(context)),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: hasOpenAIKey
                                  ? AppColors.secondary
                                  : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasOpenAIKey ? 'OpenAI aktif' : 'Mode lokal',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: hasOpenAIKey
                                  ? AppColors.secondary
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        hasOpenAIKey ? 'OpenAI' : 'Local AI',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.length <= 1 && !_isLoading
                ? _WelcomeView(
                    suggestions: _suggestions,
                    onSuggestion: (String suggestion) =>
                        _sendMessage(suggestion, transactions),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (_, int i) {
                      if (i == _messages.length) {
                        return _AiLoadingBubble();
                      }
                      final MockAiMessage msg = _messages[i];
                      return _AiBubble(msg: msg)
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_messages.length <= 1) ...<Widget>[
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _suggestions.map((suggestion) {
                        return GestureDetector(
                          onTap: () => _sendMessage(suggestion.$2, transactions),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.dividerLight),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  suggestion.$1,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  suggestion.$2,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: InputDecoration(
                            hintText: 'Tanya sesuatu tentang keuanganmu...',
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textTertiary,
                            ),
                          ),
                          style: GoogleFonts.inter(fontSize: 14),
                          onSubmitted: (String value) =>
                              _sendMessage(value, transactions),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _sendMessage(_msgCtrl.text, transactions),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color(0x555B67F1),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final List<(IconData, String)> suggestions;
  final ValueChanged<String> onSuggestion;

  const _WelcomeView({
    required this.suggestions,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: AppColors.gradientPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
          ).animate().scaleXY(begin: 0.5, curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(height: 16),
          Text('SmartLife AI', style: AppTextStyles.heading2(context))
              .animate()
              .fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Asisten keuangan pintar untuk analisis cepat dan saran hemat.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          Text('Coba pertanyaan ini:', style: AppTextStyles.subtitle(context))
              .animate()
              .fadeIn(delay: 400.ms),
          const SizedBox(height: 14),
          ...suggestions.asMap().entries.map((entry) {
            final int i = entry.key;
            final (IconData, String) item = entry.value;
            return GestureDetector(
              onTap: () => onSuggestion(item.$2),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.cardDark
                      : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Icon(item.$1, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (400 + i * 100).ms).slideX(begin: 0.1),
            );
          }),
        ],
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final MockAiMessage msg;

  const _AiBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: msg.isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: <Widget>[
          if (msg.isAi) ...<Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: msg.isAi ? null : AppColors.gradientPrimary,
                color:
                    msg.isAi ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight) : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isAi ? 4 : 18),
                  bottomRight: Radius.circular(msg.isAi ? 18 : 4),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: (msg.isAi ? Colors.black : AppColors.primary).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color:
                      msg.isAi ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiLoadingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              gradient: AppColors.gradientPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const TypingIndicator(),
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}
