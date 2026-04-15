import 'dart:ui';
import 'package:smartlife_app/domain/entities/reminder_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/reminder_provider.dart';
import 'package:smartlife_app/presentation/widgets/reminder_card.dart';
import 'package:smartlife_app/presentation/widgets/reminder_form_sheet.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1221) : Colors.white,
      body: RepaintBoundary(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(reminderProvider.notifier).loadReminders(),
          child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Pengingat Pintar',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, 
                      color: isDark ? Colors.white : Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                if (state.isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LoadingSkeleton(
                            width: double.infinity,
                            height: 94,
                            borderRadius: 22,
                          ),
                        ),
                        childCount: 5,
                      ),
                    ),
                  )
                else if (state.reminders.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(context, isDark),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reminder = state.reminders[index];
                          return ReminderCard(
                            reminder: reminder,
                            onToggle: () => ref.read(reminderProvider.notifier).toggleCompletion(reminder.id),
                            onDelete: () => _confirmDelete(context, ref, reminder.id),
                            onEdit: () => _showReminderForm(context, ref, reminder: reminder),
                          );
                        },
                        childCount: state.reminders.length,
                      ),
                    ),
                  ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReminderForm(context, ref),
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.add_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Buat Baru',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ).animate().scale(delay: 500.ms),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.notifications_none_rounded,
          size: 80,
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        const SizedBox(height: 16),
        Text(
          'Belum ada pengingat',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Klik tombol di bawah untuk membuat satu.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  void _showReminderForm(BuildContext context, WidgetRef ref, {ReminderEntity? reminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReminderFormSheet(
        reminder: reminder,
        title: reminder == null ? 'Pengingat Baru' : 'Edit Pengingat',
        submitLabel: reminder == null ? 'Buat Pengingat' : 'Simpan Perubahan',
        onSubmit: (newReminder) {
          if (reminder == null) {
            ref.read(reminderProvider.notifier).addReminder(newReminder);
          } else {
            ref.read(reminderProvider.notifier).updateReminder(newReminder);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF161A2D) 
              : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Hapus Pengingat?', style: AppTextStyles.heading3(context)),
          content: Text(
            'Tindakan ini tidak bisa dibatalkan.',
            style: AppTextStyles.body(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                ref.read(reminderProvider.notifier).deleteReminder(id);
                Navigator.pop(context);
              },
              child: Text('Hapus', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
