import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SceneGrid extends StatelessWidget {
  const SceneGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final scenes = [
      (label: 'Cinema', icon: Icons.movie_filter_rounded, color: const Color(0xFF6366F1)),
      (label: 'Sleep', icon: Icons.bedtime_rounded, color: const Color(0xFFEC4899)),
      (label: 'Work', icon: Icons.laptop_chromebook_rounded, color: const Color(0xFF10B981)),
      (label: 'Away', icon: Icons.travel_explore_rounded, color: const Color(0xFFF59E0B)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK SCENES',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: scenes.length,
          itemBuilder: (context, index) {
            final scene = scenes[index];
            return _SceneCard(
              label: scene.label,
              icon: scene.icon,
              color: scene.color,
            );
          },
        ),
      ],
    );
  }
}

class _SceneCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SceneCard({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
