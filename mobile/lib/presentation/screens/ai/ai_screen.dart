import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final aiState = ref.watch(aiProvider);
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
          const _MeshBackground(),
          const _NoiseOverlay(),
          Column(
            children: <Widget>[
              _AiHeader(
                isDark: isDark,
                totalSpent: financeState.totalSpent,
                budget: financeState.budget,
                onClear: () => _clearConversation(aiState.messages.length),
              ),
              Expanded(
                child: aiState.messages.length <= 1 && !aiState.isLoading
                    ? _WelcomeView(
                        suggestions: _suggestions,
                        onSuggestion: _sendMessage,
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: aiState.messages.length +
                            (aiState.isLoading ? 1 : 0),
                        itemBuilder: (_, int i) {
                          if (i == aiState.messages.length) {
                            return const _AiLoadingBubble();
                          }
                          final message = aiState.messages[i];
                          return _AiBubble(
                            message: message,
                            onCopy: () => _copyMessage(message.text),
                          )
                              .animate()
                              .fadeIn(duration: 200.ms)
                              .slideY(begin: 0.1, end: 0);
                        },
                      ),
              ),
              _buildInputBar(
                isDark,
                aiState.isLoading,
                aiState.messages.length <= 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, bool isLoading, bool showSuggestions) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF0F172A).withValues(alpha: 0.7) 
                : Colors.white.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (showSuggestions) ...<Widget>[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _suggestions.map((suggestion) {
                      return GestureDetector(
                        onTap: () => _sendMessage(suggestion.$2),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.dividerLight),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(suggestion.$1,
                                  size: 14, color: AppColors.primary),
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
                              horizontal: 18, vertical: 14),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textTertiary,
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        onSubmitted: (value) => _sendMessage(value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: isLoading ? null : () => _sendMessage(_msgCtrl.text),
                    child: Opacity(
                      opacity: isLoading ? 0.6 : 1,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color(0x557C7E9D),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return;
    }

    HapticFeedback.lightImpact();
    _msgCtrl.clear();
    await ref.read(aiProvider.notifier).ask(cleanText);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
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
    final double budgetPct =
        budget <= 0 ? 0 : ((totalSpent / budget) * 100).clamp(0, 999);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.3),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
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
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('SmartLife AI', style: AppTextStyles.heading3(context)),
                      Text(
                        'Asisten insight keuangan real-time',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${budgetPct.toStringAsFixed(0)}% budget',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cleaning_services_rounded, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 36),
          )
              .animate()
              .scaleXY(begin: 0.5, curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(height: 16),
          Text('SmartLife AI', style: AppTextStyles.heading2(context))
              .animate()
              .fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Asisten keuangan pintar dengan data real dari transaksi kamu.',
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
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.primary),
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
  final AiMessageEntity message;
  final VoidCallback onCopy;

  const _AiBubble({
    required this.message,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onLongPress: onCopy,
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isAi ? null : AppColors.gradientPrimary,
                  color: isAi
                      ? (isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.9))
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isAi ? 4 : 20),
                    bottomRight: Radius.circular(isAi ? 20 : 4),
                  ),
                  border: isAi 
                      ? Border.all(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.black.withValues(alpha: 0.02),
                        )
                      : null,
                  boxShadow: <BoxShadow>[
                    if (isAi) ...[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ] else
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      message.text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        color: isAi
                            ? (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppFormatters.timeOnly(message.timestamp)}  •  tahan untuk salin',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isAi
                            ? (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textTertiary)
                            : Colors.white70,
                      ),
                    ),
                  ],
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
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const TypingIndicator(),
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}

class _MeshBackground extends StatelessWidget {
  const _MeshBackground();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          // Dynamic Blobs
          _Blob(
            color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1),
            size: 400,
            initialOffset: const Offset(-100, -100),
            animationDuration: 15.seconds,
          ),
          _Blob(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.08),
            size: 350,
            initialOffset: const Offset(200, 100),
            animationDuration: 20.seconds,
            begin: 0.2,
          ),
          _Blob(
            color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.1 : 0.06),
            size: 300,
            initialOffset: const Offset(50, 400),
            animationDuration: 18.seconds,
            begin: 0.4,
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final Offset initialOffset;
  final Duration animationDuration;
  final double begin;

  const _Blob({
    required this.color,
    required this.size,
    required this.initialOffset,
    required this.animationDuration,
    this.begin = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: initialOffset.dx,
      top: initialOffset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .move(
            begin: Offset.zero,
            end: const Offset(50, 80),
            duration: animationDuration,
            curve: Curves.easeInOut,
          )
          .scaleXY(begin: 1, end: 1.2, duration: animationDuration),
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
