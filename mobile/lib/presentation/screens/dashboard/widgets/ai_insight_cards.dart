import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';

class InsightCard extends StatelessWidget {
  final bool isDark;

  const InsightCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.2) : const Color(0xFF6366F1).withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'AI INSIGHTS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              _Badge(label: 'Real-time', isDark: isDark),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'SmartLife AI telah menganalisis pengeluaran Anda.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda menghemat 12% lebih banyak dibanding bulan lalu. Pertahankan pola makan sehat dan kurangi langganan yang tidak terpakai.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _ActionLink(isDark: isDark),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF22C55E),
        ),
      ),
    );
  }
}

class _ActionLink extends StatelessWidget {
  final bool isDark;

  const _ActionLink({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Tanya AI selengkapnya',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF6366F1)),
      ],
    ).animate(onPlay: (c) => c.repeat())
     .shimmer(delay: 2.seconds, duration: 1.5.seconds);
  }
}
