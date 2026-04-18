import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/life_hub_provider.dart';
import 'package:smartlife_app/presentation/screens/life_hub/widgets/habit_card.dart';
import 'package:smartlife_app/presentation/screens/life_hub/widgets/goal_card.dart';
import 'package:smartlife_app/presentation/screens/life_hub/widgets/life_hub_background.dart';

class LifeHubScreen extends ConsumerStatefulWidget {
  const LifeHubScreen({super.key});

  @override
  ConsumerState<LifeHubScreen> createState() => _LifeHubScreenState();
}

class _LifeHubScreenState extends ConsumerState<LifeHubScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final lifeHubState = ref.watch(lifeHubProvider);
    final lifeHubNotifier = ref.read(lifeHubProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        title: Text(
          'Life Hub',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          LifeHubBackground(isDark: isDark),
          SafeArea(
            child: lifeHubState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildWelcomeHeader(isDark),
                        const SizedBox(height: 32),

                        _SectionHeader(
                          title: 'DAILY HABITS',
                          count: lifeHubState.habits.where((h) => h.isCompletedToday).length,
                          total: lifeHubState.habits.length,
                        ),
                        const SizedBox(height: 16),
                        
                        // Habit Grid (Bento Style)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
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
                            );
                          },
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        const _SectionHeader(title: 'LIFE GOALS'),
                        const SizedBox(height: 16),
                        
                        // Goals List
                        ...lifeHubState.goals.map((goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GoalCard(
                            goal: goal,
                            onUpdate: (val) => lifeHubNotifier.updateGoalProgress(goal.id, val),
                          ),
                        )).toList().animate(interval: 100.ms).fadeIn().slideX(begin: 0.1),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Master Your Life',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        Text(
          'Track your habits and achieve your big goals.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestionCard(bool isDark) {
    final lifeHubNotifier = ref.read(lifeHubProvider.notifier);
    final suggestion = lifeHubNotifier.getAiSuggestion();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.2),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().shimmer(delay: 2.seconds, duration: 2.seconds);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final int? total;

  const _SectionHeader({required this.title, this.count, this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        if (count != null && total != null)
          Text(
            '$count/$total Done',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}
