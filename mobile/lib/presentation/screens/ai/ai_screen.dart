import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/domain/entities/ai_message_entity.dart';
import 'package:smartlife_app/presentation/providers/ai_provider.dart';
import 'package:smartlife_app/presentation/providers/finance_provider.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<(IconData, String)> _suggestions = const <(IconData, String)>[
    (Icons.savings_outlined, 'Apakah saya boros bulan ini?'),
    (Icons.lightbulb_outline_rounded, 'Tips hemat realistis minggu ini'),
    (Icons.pie_chart_outline_rounded, 'Kategori pengeluaran paling besar?'),
    (Icons.track_changes_rounded, 'Target tabungan yang aman bulan ini'),
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AiState aiState = ref.watch(aiProvider);
    final financeState = ref.watch(financeProvider);

    ref.listen<AiState>(aiProvider, (previous, next) {
      if (!mounted) {
        return;
      }

      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty &&
          previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: <Widget>[
          FluidBackground(isDark: isDark),
          const _NoiseOverlay(),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                  child: _AiHeader(
                    isDark: isDark,
                    totalSpent: financeState.totalSpent,
                    budget: financeState.budget,
                    onClear: () => _clearConversation(aiState.messages.length),
                  ),
                ),
                Expanded(
                  child: aiState.messages.length <= 1 && !aiState.isLoading
                      ? SingleChildScrollView(
                          controller: _scrollCtrl,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                          child: _WelcomeView(
                            isDark: isDark,
                            totalSpent: financeState.totalSpent,
                            budget: financeState.budget,
                            suggestions: _suggestions,
                            onSuggestion: _sendMessage,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                          itemCount: aiState.messages.length +
                              (aiState.isLoading ? 1 : 0),
                          itemBuilder: (_, int index) {
                            if (index == aiState.messages.length) {
                              return const _AiLoadingBubble();
                            }

                            final AiMessageEntity message =
                                aiState.messages[index];
                            return _AiBubble(
                              message: message,
                              isDark: isDark,
                              onCopy: () => _copyMessage(message.text),
                            )
                                .animate()
                                .fadeIn(duration: 220.ms)
                                .slideY(begin: 0.05, end: 0);
                          },
                        ),
                ),
                _InputBar(
                  controller: _msgCtrl,
                  isDark: isDark,
                  isLoading: aiState.isLoading,
                  suggestions:
                      aiState.messages.length <= 1 ? _suggestions : null,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final String cleanText = text.trim();
    if (cleanText.isEmpty) {
      return;
    }

    HapticFeedback.lightImpact();
    _msgCtrl.clear();
    await ref.read(aiProvider.notifier).ask(cleanText);
    _scrollToBottom(delayMs: 180);
  }

  void _scrollToBottom({int delayMs = 120}) {
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!_scrollCtrl.hasClients) {
        return;
      }

      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _copyMessage(String text) async {
    final String clean = text.trim();
    if (clean.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: clean));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesan berhasil disalin')),
    );
  }

  void _clearConversation(int messageCount) {
    if (messageCount <= 1) {
      return;
    }

    ref.read(aiProvider.notifier).clearConversation();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Riwayat obrolan AI dibersihkan')),
    );
  }
}

class _AiHeader extends StatelessWidget {
  final bool isDark;
  final double totalSpent;
  final double budget;
  final VoidCallback onClear;

  const _AiHeader({
    required this.isDark,
    required this.totalSpent,
    required this.budget,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final double budgetPct = budget <= 0
        ? 0
        : ((totalSpent / budget) * 100).clamp(0, 999).toDouble();
    final bool isDanger = budgetPct >= 90;

    return ModernGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      borderRadius: 28,
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SmartLife AI',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDanger
                      ? 'Budget mulai ketat. Coba minta strategi hemat cepat.'
                      : 'Asisten finansial untuk insight, strategi, dan keputusan harian.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDanger ? AppColors.error : AppColors.success)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${budgetPct.toStringAsFixed(0)}%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDanger ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TopBarAction(
                icon: Icons.delete_sweep_rounded,
                onPressed: onClear,
                isDark: isDark,
                tooltip: 'Bersihkan percakapan',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final bool isDark;
  final double totalSpent;
  final double budget;
  final List<(IconData, String)> suggestions;
  final ValueChanged<String> onSuggestion;

  const _WelcomeView({
    required this.isDark,
    required this.totalSpent,
    required this.budget,
    required this.suggestions,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final double remaining = budget > totalSpent ? budget - totalSpent : 0;
    final double budgetPct = budget <= 0
        ? 0
        : ((totalSpent / budget) * 100).clamp(0, 999).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ModernGlassCard(
          isDark: isDark,
          borderRadius: 32,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ).animate().scaleXY(
                    begin: 0.8,
                    curve: Curves.easeOutBack,
                    duration: 500.ms,
                  ),
              const SizedBox(height: 22),
              Text(
                'Analisis cepat, gaya premium.',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Gunakan AI untuk membaca tren pengeluaran, cari peluang hemat, dan dapatkan rekomendasi cepat tanpa harus buka banyak menu.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _MetricCard(
                      label: 'Spent',
                      value: AppFormatters.currency(totalSpent),
                      accent: AppColors.error,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Remaining',
                      value: AppFormatters.currency(remaining),
                      accent: AppColors.success,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Usage',
                      value: '${budgetPct.toStringAsFixed(0)}%',
                      accent: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Prompt Cepat',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pilih salah satu untuk mulai obrolan lebih cepat.',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...suggestions.asMap().entries.map((entry) {
          final int index = entry.key;
          final (IconData, String) item = entry.value;
          return _PromptCard(
            isDark: isDark,
            icon: item.$1,
            label: item.$2,
            onTap: () => onSuggestion(item.$2),
          ).animate().fadeIn(delay: (150 + index * 80).ms).slideY(begin: 0.06);
        }),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PromptCard({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      isDark: isDark,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool isDark;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isLoading;
  final List<(IconData, String)>? suggestions;
  final ValueChanged<String> onSend;

  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.isLoading,
    required this.suggestions,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (suggestions != null) ...<Widget>[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: suggestions!.map((suggestion) {
                  return GestureDetector(
                    onTap: () => onSend(suggestion.$2),
                    child: (ModernGlassCard(
                      isDark: isDark,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      borderRadius: 22,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            suggestion.$1,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            suggestion.$2,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )).animate().fadeIn(duration: 380.ms).slideX(begin: 0.08),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],
          ModernGlassCard(
            isDark: isDark,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            borderRadius: 30,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: onSend,
                    decoration: InputDecoration(
                      hintText: 'Tanya apa pun soal keuangan kamu...',
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: isLoading ? null : () => onSend(controller.text),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: isLoading ? null : AppColors.gradientPrimary,
                      color: isLoading ? Colors.white10 : null,
                      shape: BoxShape.circle,
                      boxShadow: isLoading
                          ? const <BoxShadow>[]
                          : <BoxShadow>[
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white24,
                            ),
                          )
                        : const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final AiMessageEntity message;
  final bool isDark;
  final VoidCallback onCopy;

  const _AiBubble({
    required this.message,
    required this.isDark,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAi = !message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: <Widget>[
          if (isAi) ...<Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onCopy,
              child: ModernGlassCard(
                isDark: isDark,
                padding: const EdgeInsets.all(16),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (isAi ? AppColors.primary : AppColors.info)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isAi ? 'AI ANALYSIS' : 'YOU',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isAi ? AppColors.primary : AppColors.info,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        strong: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                        listBullet: GoogleFonts.inter(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${AppFormatters.timeOnly(message.timestamp)} • tahan untuk salin',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isAi) ...<Widget>[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiLoadingBubble extends StatelessWidget {
  const _AiLoadingBubble();

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
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const TypingIndicator(),
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.03,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://www.transparenttextures.com/patterns/carbon-fibre.png',
            ),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    );
  }
}
