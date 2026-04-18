import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardBackground extends StatelessWidget {
  final bool isDark;

  const DashboardBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        ),

        // Mesh Gradient Orbs
        Positioned(
          top: -150,
          right: -100,
          child: _MeshOrb(
            size: 400,
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
            duration: 8.seconds,
          ),
        ),
        Positioned(
          bottom: 100,
          left: -150,
          child: _MeshOrb(
            size: 350,
            color: const Color(0xFF00FFD1).withValues(alpha: isDark ? 0.1 : 0.05),
            duration: 10.seconds,
          ),
        ),
        Positioned(
          top: 300,
          left: 100,
          child: _MeshOrb(
            size: 250,
            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.08 : 0.04),
            duration: 12.seconds,
          ),
        ),

        // Noise/Texture overlay (Optional but adds premium feel)
        if (isDark)
          Opacity(
            opacity: 0.02,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MeshOrb extends StatelessWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _MeshOrb({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .scaleXY(begin: 0.8, end: 1.2, duration: duration, curve: Curves.easeInOut)
     .move(begin: const Offset(-20, -20), end: const Offset(20, 20), duration: duration, curve: Curves.easeInOut);
  }
}
