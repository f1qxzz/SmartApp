import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/domain/entities/reminder_entity.dart';

class ReminderCard extends StatelessWidget {
  final ReminderEntity reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = reminder.isOverdue;

    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: reminder.isCompleted
                ? Colors.green.withValues(alpha: 0.3)
                : (isOverdue ? Colors.red.withValues(alpha: 0.3) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: 300.ms,
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: reminder.isCompleted ? Colors.green : Colors.transparent,
                        border: Border.all(
                          color: reminder.isCompleted ? Colors.green : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: reminder.isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: reminder.isCompleted
                                ? Colors.grey
                                : (isDark ? Colors.white : Colors.black87),
                            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: isOverdue ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(reminder.dateTime),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isOverdue ? Colors.red : Colors.grey,
                                fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            if (reminder.category != null) ...[
                              const SizedBox(width: 8),
                              _buildCategoryTag(reminder.category!, isDark),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    onTap: onDelete,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    String datePart;
    if (today == target) {
      datePart = 'Hari ini';
    } else if (today.add(const Duration(days: 1)) == target) {
      datePart = 'Besok';
    } else {
      datePart = DateFormat('dd MMM').format(dt);
    }

    return '$datePart, ${AppFormatters.timeOnly(dt)}';
  }

  Widget _buildCategoryTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}
