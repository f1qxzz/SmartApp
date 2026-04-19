import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/life_hub_provider.dart';
import 'package:smartlife_app/presentation/screens/life_hub/widgets/habit_card.dart';
import 'package:smartlife_app/presentation/screens/life_hub/widgets/goal_card.dart';

import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';
import 'package:smartlife_app/domain/entities/life_hub_entities.dart';

class LifeHubScreen extends ConsumerStatefulWidget {
  const LifeHubScreen({super.key});

  @override
  ConsumerState<LifeHubScreen> createState() => _LifeHubScreenState();
}

class _LifeHubScreenState extends ConsumerState<LifeHubScreen> {
  String _todayLabel() {
    const List<String> dayNames = <String>[
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final DateTime now = DateTime.now();
    return '${dayNames[now.weekday - 1]}, ${now.day}/${now.month}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color appBarForeground =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final lifeHubState = ref.watch(lifeHubProvider);
    final lifeHubNotifier = ref.read(lifeHubProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: _ToolbarIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
            isDark: isDark,
          ),
        ),
        titleSpacing: 2,
        title: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.28),
                ),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Life Hub',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: appBarForeground,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _todayLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.72)
                          : const Color(0xFF334155).withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: _ToolbarIconButton(
              icon: Icons.add_rounded,
              onTap: () => _openAddSelector(context),
              isDark: isDark,
              highlightColor: const Color(0xFF4F75FF),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const FluidBackground(
            orbColors: <Color>[
              Color(0xFF365DF5),
              Color(0xFF44C2FF),
              Color(0xFF8BE4C8),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? <Color>[
                            Colors.black.withValues(alpha: 0.08),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.16),
                          ]
                        : <Color>[
                            Colors.black.withValues(alpha: 0.03),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.04),
                          ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: lifeHubState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(isDark),
                        const SizedBox(height: 32),

                        _SectionHeader(
                          title: 'Daily Habits',
                          icon: Icons.checklist_rounded,
                          count: lifeHubState.habits
                              .where((h) => h.isCompletedToday)
                              .length,
                          total: lifeHubState.habits.length,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        // Habit Grid (Bento Style)
                        if (lifeHubState.habits.isEmpty)
                          _buildEmptyState(
                            isDark: isDark,
                            icon: Icons.repeat_rounded,
                            title: 'Belum ada habit',
                            subtitle:
                                'Tekan tombol + untuk menambahkan kebiasaan harian pertama kamu.',
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.08,
                            ),
                            itemCount: lifeHubState.habits.length,
                            itemBuilder: (context, index) {
                              final habit = lifeHubState.habits[index];
                              return HabitCard(
                                habit: habit,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  lifeHubNotifier.toggleHabit(habit.id);
                                },
                                onEdit: () => _showEditHabitSheet(habit),
                                onLongPress: () => _confirmDelete(
                                  context,
                                  'Hapus Kebiasaan?',
                                  'Apakah Anda yakin ingin menghapus "${habit.title}"?',
                                  () => lifeHubNotifier.deleteHabit(habit.id),
                                ),
                              );
                            },
                          )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        _SectionHeader(
                          title: 'Life Goals',
                          icon: Icons.flag_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        // Goals List
                        if (lifeHubState.goals.isEmpty)
                          _buildEmptyState(
                            isDark: isDark,
                            icon: Icons.flag_rounded,
                            title: 'Belum ada target',
                            subtitle:
                                'Buat life goal agar progress mingguan kamu bisa dipantau jelas.',
                          )
                        else
                          ...lifeHubState.goals
                              .map((goal) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: GoalCard(
                                      goal: goal,
                                      onUpdate: (val) => lifeHubNotifier
                                          .updateGoalProgress(goal.id, val),
                                      onEdit: () => _showEditGoalSheet(goal),
                                      onLongPress: () => _confirmDelete(
                                        context,
                                        'Hapus Target?',
                                        'Apakah Anda yakin ingin menghapus "${goal.title}"?',
                                        () => lifeHubNotifier
                                            .deleteLifeGoal(goal.id),
                                      ),
                                    ),
                                  ))
                              .toList()
                              .animate(interval: 100.ms)
                              .fadeIn()
                              .slideX(begin: 0.1),

                        const SizedBox(height: 20),

                        _buildAiSuggestionCard(isDark),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isDark) {
    final user = ref.watch(authProvider).user;
    final lifeHubState = ref.watch(lifeHubProvider);
    final String name = user?.name.split(' ').first ?? 'User';
    final int totalHabits = lifeHubState.habits.length;
    final int doneHabits =
        lifeHubState.habits.where((h) => h.isCompletedToday).length;
    final int totalGoals = lifeHubState.goals.length;
    final Color titleSoftColor = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF334155).withValues(alpha: 0.90);
    final Color titleStrongColor =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.86)
        : const Color(0xFF1E293B).withValues(alpha: 0.82);

    return ModernGlassCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      borderRadius: 28,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _TopBadge(
                label: 'Life Planner',
                icon: Icons.track_changes_rounded,
                isDark: isDark,
                tint: const Color(0xFF44C2FF),
              ),
              _TopBadge(
                label: '$doneHabits/$totalHabits selesai',
                icon: Icons.bolt_rounded,
                isDark: isDark,
                tint: const Color(0xFF7C9CFF),
              ),
              _TopBadge(
                label: _todayLabel(),
                icon: Icons.calendar_month_rounded,
                isDark: isDark,
                tint: const Color(0xFF22C55E),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Halo,',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: titleSoftColor,
            ),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: titleStrongColor,
              letterSpacing: -0.8,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jaga ritme kebiasaan harian dan capai target besar kamu secara konsisten.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: subtitleColor,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InfoPill(
                icon: Icons.repeat_rounded,
                label: '$totalHabits Habit Aktif',
                isDark: isDark,
              ),
              _InfoPill(
                icon: Icons.flag_outlined,
                label: '$totalGoals Goal Berjalan',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestionCard(bool isDark) {
    final lifeHubNotifier = ref.read(lifeHubProvider.notifier);
    final suggestion = lifeHubNotifier.getAiSuggestion();
    final Color insightLabelColor =
        isDark ? Colors.amber : const Color(0xFFB45309);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return ModernGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      isDark: isDark,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI INSIGHT',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: insightLabelColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  suggestion,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().shimmer(delay: 3.seconds, duration: 2.seconds);
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ModernGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      isDark: isDark,
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : const Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAddSelector(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        borderRadius: 32,
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'APA YANG INGIN KAMU TAMBAHKAN?',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? Colors.white70
                    : const Color(0xFF334155).withValues(alpha: 0.85),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildSelectorOption(
                    context,
                    icon: Icons.repeat_rounded,
                    label: 'Habit',
                    color: const Color(0xFF818CF8),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      _showAddHabitSheet();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSelectorOption(
                    context,
                    icon: Icons.stars_rounded,
                    label: 'Life Goal',
                    color: const Color(0xFFFACC15),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      _showAddGoalSheet();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitSheet() {
    _showHabitForm(null);
  }

  void _showEditHabitSheet(Habit habit) {
    _showHabitForm(habit);
  }

  void _showHabitForm(Habit? habit) {
    final bool isEdit = habit != null;
    final titleController = TextEditingController(text: habit?.title);
    String selectedIcon = habit?.icon ?? 'check_circle_outline';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ModernGlassCard(
          padding: const EdgeInsets.all(32),
          borderRadius: 32,
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'EDIT HABIT' : 'NEW HABIT',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color:
                      isDark ? AppColors.primaryLight : AppColors.primaryDark,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Nama kebiasaan...',
                  hintStyle: GoogleFonts.poppins(
                    color: isDark
                        ? Colors.white38
                        : const Color(0xFF64748B).withValues(alpha: 0.88),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      if (isEdit) {
                        ref.read(lifeHubProvider.notifier).updateHabit(
                              habit.copyWith(
                                title: titleController.text,
                                icon: selectedIcon,
                              ),
                            );
                      } else {
                        ref.read(lifeHubProvider.notifier).addHabit(
                              title: titleController.text,
                              icon: selectedIcon,
                            );
                      }
                      Navigator.pop(context);
                    } else {
                      HapticFeedback.vibrate();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Tambah Kebiasaan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGoalSheet() {
    _showGoalForm(null);
  }

  void _showEditGoalSheet(LifeGoal goal) {
    _showGoalForm(goal);
  }

  void _showGoalForm(LifeGoal? goal) {
    final bool isEdit = goal != null;
    final titleController = TextEditingController(text: goal?.title);
    final deadlineController = TextEditingController(text: goal?.deadline);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ModernGlassCard(
          padding: const EdgeInsets.all(32),
          borderRadius: 32,
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'EDIT LIFE GOAL' : 'NEW LIFE GOAL',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFACC15),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Target besarmu...',
                  hintStyle: GoogleFonts.poppins(
                    color: isDark
                        ? Colors.white38
                        : const Color(0xFF64748B).withValues(alpha: 0.88),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deadlineController,
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Deadline (Contoh: Des 2026)',
                  hintStyle: GoogleFonts.poppins(
                    color: isDark
                        ? Colors.white38
                        : const Color(0xFF64748B).withValues(alpha: 0.88),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      if (isEdit) {
                        ref.read(lifeHubProvider.notifier).updateLifeGoal(
                              goal.copyWith(
                                title: titleController.text,
                                deadline: deadlineController.text,
                              ),
                            );
                      } else {
                        ref.read(lifeHubProvider.notifier).addLifeGoal(
                              title: titleController.text,
                              deadline: deadlineController.text,
                            );
                      }
                      Navigator.pop(context);
                    } else {
                      HapticFeedback.vibrate();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Tambah Target',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String title, String content,
      VoidCallback onConfirm) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color? highlightColor;

  const _ToolbarIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color tint = highlightColor ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.90),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : tint.withValues(alpha: 0.22),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tint.withValues(alpha: isDark ? 0.22 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final Color tint;

  const _TopBadge({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tint.withValues(alpha: isDark ? 0.18 : 0.12),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.74),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.09)
              : const Color(0xFFCBD5E1).withValues(alpha: 0.50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final int? count;
  final int? total;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.isDark,
    this.icon,
    this.count,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 16,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.88)
                        : const Color(0xFF334155).withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (count != null && total != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              '$count/$total selesai',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
              ),
            ),
          ),
      ],
    );
  }
}
