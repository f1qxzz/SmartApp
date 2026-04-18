import 'package:flutter/material.dart';

class LifeHubBackground extends StatelessWidget {
  final bool isDark;
  const LifeHubBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F121F),
                  const Color(0xFF1E2235),
                  const Color(0xFF0F121F),
                ]
              : [
                  const Color(0xFF4C5372),
                  const Color(0xFF2F344A),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: isDark ? 0.05 : 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withValues(alpha: isDark ? 0.05 : 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
