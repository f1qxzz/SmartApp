import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SmartHomeBackground extends StatelessWidget {
  final bool isDark;

  const SmartHomeBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Tech-Dark Color
        Container(color: const Color(0xFF0F172A)),

        // Animated Mesh Blooms
        _MeshBloom(
          color: const Color(0xFF3B82F6),
          offset: const Offset(-0.3, 0.2),
          size: 450,
          duration: 7.seconds,
        ),
        _MeshBloom(
          color: const Color(0xFFEC4899),
          offset: const Offset(0.7, 0.5),
          size: 400,
          duration: 9.seconds,
        ),
        _MeshBloom(
          color: const Color(0xFF8B5CF6),
          offset: const Offset(0.2, -0.1),
          size: 380,
          duration: 8.seconds,
        ),

        // Subtle Grain Overlay
        const _NoiseOverlay(),
      ],
    );
  }
}

class _MeshBloom extends StatelessWidget {
  final Color color;
  final Offset offset;
  final double size;
  final Duration duration;

  const _MeshBloom({
    required this.color,
    required this.offset,
    required this.size,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * offset.dx,
      top: MediaQuery.of(context).size.height * offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.3, 1.3),
            duration: duration,
            curve: Curves.easeInOutSine,
          )
          .move(
            begin: Offset.zero,
            end: const Offset(20, 30),
            duration: duration,
            curve: Curves.easeInOutSine,
          ),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.015,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://www.transparenttextures.com/patterns/stardust.png'),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    );
  }
}
