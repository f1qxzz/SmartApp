import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LightControlCard extends StatelessWidget {
  final bool isOn;
  final double brightness;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onBrightnessChanged;

  const LightControlCard({
    super.key,
    required this.isOn,
    required this.brightness,
    required this.onToggle,
    required this.onBrightnessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BentoBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconCircle(
                icon: Icons.light_mode_rounded,
                color: isOn ? Colors.yellow : Colors.white24,
              ),
              Switch(
                value: isOn,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  onToggle(v);
                },
                activeThumbColor: Colors.yellow,
                activeTrackColor: Colors.yellow.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Main Lighting',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            isOn ? '${(brightness * 100).toInt()}% Brightness' : 'Turned Off',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.yellow,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: brightness,
                onChanged: onBrightnessChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SecurityControlCard extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onTap;

  const SecurityControlCard({super.key, required this.isLocked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = isLocked ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return _BentoBase(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Icon(
              isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: statusColor,
              size: 28,
            ),
          ).animate(target: isLocked ? 1 : 0).shimmer(color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            isLocked ? 'LOCKED' : 'UNLOCKED',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          Text(
            'Smart Lock',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class ClimateControlCard extends StatelessWidget {
  final bool isOn;
  final double temp;
  final VoidCallback onToggle;
  final VoidCallback onTempUp;
  final VoidCallback onTempDown;

  const ClimateControlCard({
    super.key,
    required this.isOn,
    required this.temp,
    required this.onToggle,
    required this.onTempUp,
    required this.onTempDown,
  });

  @override
  Widget build(BuildContext context) {
    return _BentoBase(
      child: Column(
        children: [
          Row(
            children: [
              _IconCircle(
                icon: Icons.air_rounded,
                color: isOn ? const Color(0xFF3B82F6) : Colors.white24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Climate Control',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isOn ? 'Cooling Mode' : 'Power Off',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (_) {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                activeThumbColor: const Color(0xFF3B82F6),
                activeTrackColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TempBtn(icon: Icons.remove, onTap: onTempDown),
                const SizedBox(width: 24),
                Text(
                  '${temp.toInt()}°',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 24),
                _TempBtn(icon: Icons.add, onTap: onTempUp),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CctvControlCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const CctvControlCard({super.key, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _BentoBase(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1558002038-1055907df827?q=80&w=1200',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
                ),
              ),
            ),
            if (isActive)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScanlinePainter(),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.red : Colors.grey).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isActive)
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 500.ms),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'LIVE FEED' : 'PAUSED',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Icon(
                isActive ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──

class _BentoBase extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const _BentoBase({required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconCircle({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _TempBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TempBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
