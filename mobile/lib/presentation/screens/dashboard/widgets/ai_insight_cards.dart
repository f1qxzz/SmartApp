import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class InsightCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onAskAi;

  const InsightCard({
    super.key,
    required this.isDark,
    this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final Color headlineColor = isDark ? Colors.white : AppColors.textPrimary;
    final Color bodyColor =
        isDark ? Colors.white.withValues(alpha: 0.86) : const Color(0xFF334155);

    return ModernGlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary
                        .withValues(alpha: isDark ? 0.34 : 0.2),
                    width: 1.2,
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI INSIGHTS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              _Badge(label: 'Real-time', isDark: isDark),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'SmartLife AI telah menganalisis pengeluaran Anda.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: headlineColor,
              letterSpacing: -0.2,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 10),
          Text(
            'Anda menghemat 12% lebih banyak dibanding bulan lalu. Pertahankan pola makan sehat dan kurangi langganan yang tidak terpakai.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: bodyColor,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),
          _ActionLink(
            isDark: isDark,
            onTap: onAskAi,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool isDark;

  const _Badge({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF22C55E),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionLink extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;

  const _ActionLink({
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Tanya AI selengkapnya',
                style: GoogleFonts.inter(
                  fontSize: 13.2,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          delay: 3.seconds,
          duration: 2.seconds,
        );
  }
}
