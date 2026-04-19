import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartlife_app/domain/entities/life_hub_entities.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDone = habit.isCompletedToday;
    final Color titleColor = isDone
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));
    final Color subtitleColor = isDone
        ? Colors.white.withValues(alpha: 0.86)
        : (isDark
            ? Colors.white.withValues(alpha: 0.72)
            : const Color(0xFF475569));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(24),
        child: ModernGlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 24,
          opacity: isDone ? 0.24 : (isDark ? 0.14 : 0.08),
          isDark: isDark,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isDone
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFF3559E0),
                        Color(0xFF4D73FF),
                        Color(0xFF44C2FF),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDone
                    ? Colors.white.withValues(alpha: 0.26)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFCBD5E1).withValues(alpha: 0.52)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.white.withValues(alpha: 0.20)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDone
                              ? Colors.white.withValues(alpha: 0.30)
                              : AppColors.primary.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Icon(
                        _getIcon(habit.icon),
                        color: isDone ? Colors.white : AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    if (onEdit != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: isDone
                                  ? Colors.white
                                  : (isDark ? Colors.white54 : Colors.black26),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Done',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  habit.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: isDone
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFFF97316),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${habit.streak} hari streak',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: subtitleColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'book':
        return Icons.book_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}
