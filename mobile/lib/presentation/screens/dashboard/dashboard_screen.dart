import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/constants/app_constants.dart';
import 'package:smartlife_app/core/navigation/app_route.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/presentation/providers/finance_provider.dart';
import 'package:smartlife_app/presentation/providers/life_hub_provider.dart';
import 'package:smartlife_app/presentation/providers/reminder_provider.dart';
import 'package:smartlife_app/presentation/screens/ai/ai_screen.dart';

import 'package:smartlife_app/presentation/screens/reminder/reminder_screen.dart';
import 'package:smartlife_app/presentation/screens/life_hub/life_hub_screen.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';
import 'package:smartlife_app/presentation/widgets/transaction_form_sheet.dart';

// New Modular Widgets
import 'package:smartlife_app/presentation/screens/dashboard/widgets/dashboard_header.dart';
import 'package:smartlife_app/presentation/screens/dashboard/widgets/balance_card.dart';
import 'package:smartlife_app/presentation/screens/dashboard/widgets/stat_cards.dart';
import 'package:smartlife_app/presentation/screens/dashboard/widgets/trend_charts.dart';
import 'package:smartlife_app/presentation/screens/dashboard/widgets/ai_insight_cards.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _touchedPieIndex = -1;
  static const String _menuAssetIconPath =
      'assets/images/app_logo_transparent.png';

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final financeState = ref.watch(financeProvider);

    if (financeState.isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0F121F), const Color(0xFF1E2235)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
            ),
          ),
          child: _buildLoadingView(context),
        ),
      );
    }

    final List<FinanceEntryEntity> transactions = financeState.entries;
    final double totalSpent = financeState.totalSpent;
    final double budgetUsage = financeState.budget <= 0
        ? 0
        : (totalSpent / financeState.budget).clamp(0.0, 1.0).toDouble();
    final int totalTransactions = transactions.length;

    final List<({String name, double amount, double percentage, Color color})>
        categoryData = _buildCategoryData(transactions, totalSpent);
    final ({List<FlSpot> spots, List<String> labels}) weeklySeries =
        _buildWeeklySeries(transactions);

    return Scaffold(
      body: Stack(
        children: [
          const FluidBackground(),
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshDashboard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: <Widget>[
                // Header (Greeting & AI Status)
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: DashboardHeader(
                      isDark: isDark,
                      greeting: _getGreeting(),
                    ),
                  ),
                ),

                // Main Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Search Bar & Actions
                      _buildSearchBar(isDark)
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.1),
                      const SizedBox(height: 24),

                      _buildQuickActions(isDark)
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 600.ms),
                      const SizedBox(height: 28),

                      // Main Balance Module
                      AppBalanceCard(
                        totalSpent: totalSpent,
                        budgetUsage: budgetUsage,
                        isDark: isDark,
                      ).animate().fadeIn(duration: 800.ms).scale(
                          begin: const Offset(0.95, 0.95),
                          curve: Curves.easeOutCubic),
                      const SizedBox(height: 20),

                      // Stat Grid
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Transaksi',
                              value: '$totalTransactions',
                              icon: Icons.swap_vert_rounded,
                              gradient: AppColors.gradientPrimary,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              title: 'Reminders',
                              value:
                                  '${ref.watch(reminderProvider).reminders.where((r) => !r.isCompleted).length}',
                              icon: Icons.notifications_active_rounded,
                              gradient: AppColors.gradientChatHeader,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      // Savings Goal
                      _buildSavingsGoalBento(isDark)
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 600.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      // Insight Spotlight
                      InsightCard(
                        isDark: isDark,
                        onAskAi: _openSmartAi,
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      // Life Hub Status
                      _buildLifeHubStatusBento(isDark)
                          .animate()
                          .fadeIn(delay: 450.ms, duration: 600.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      // Detailed Charts
                      TrendChart(
                        spots: weeklySeries.spots,
                        isDark: isDark,
                        maxY: math.max(
                            100000.0,
                            weeklySeries.spots.fold<double>(
                                    0, (max, spot) => math.max(max, spot.y)) *
                                1.3),
                      )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 600.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      _buildCategoryBentoCard(categoryData, isDark)
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      _buildRemindersBento(isDark)
                          .animate()
                          .fadeIn(delay: 700.ms, duration: 600.ms)
                          .slideY(begin: 0.1),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeHubStatusBento(bool isDark) {
    final lifeHubState = ref.watch(lifeHubProvider);
    final completedHabits =
        lifeHubState.habits.where((h) => h.isCompletedToday).length;
    final totalHabits = lifeHubState.habits.length;
    final progress = totalHabits == 0 ? 0.0 : completedHabits / totalHabits;
    final bool allDone = progress >= 1.0;
    final String statusText =
        allDone ? 'All Habits Done' : '$completedHabits habits completed';

    return InkWell(
      onTap: _openLifeHub,
      borderRadius: BorderRadius.circular(32),
      child: ModernGlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 32,
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY MOTIVATION',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      if (allDone) ...<Widget>[
                        AppAssetIcon(
                          path: AppConstants.appLogoPath,
                          size: 16,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: isDark ? Colors.white24 : Colors.black12, size: 16),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  Future<void> _refreshDashboard() async {
    await Future.wait<void>(<Future<void>>[
      ref.read(financeProvider.notifier).load(silent: true),
      ref.read(reminderProvider.notifier).loadReminders(),
    ]);
  }

  Future<void> _openSmartAi() async {
    await Navigator.push<void>(
      context,
      AppRoute<void>(builder: (BuildContext context) => const AIScreen()),
    );
  }

  Future<void> _openReminderCenter() async {
    await Navigator.push<void>(
      context,
      AppRoute<void>(builder: (BuildContext context) => const ReminderScreen()),
    );
  }

  Future<void> _openLifeHub() async {
    await Navigator.push<void>(
      context,
      AppRoute<void>(builder: (BuildContext context) => const LifeHubScreen()),
    );
  }

  Future<void> _openAddExpenseSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormSheet(
        title: 'Catat Pengeluaran',
        submitLabel: 'Simpan',
        onSubmit: (value) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref.read(financeProvider.notifier).create(
                  title: value.title,
                  amount: value.amount,
                  category: value.categoryId,
                  description: value.description,
                  date: value.date,
                );
          } catch (_) {
            if (!mounted) return;
            messenger.showSnackBar(
              const SnackBar(content: Text('Gagal menambahkan transaksi')),
            );
            return;
          }

          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil ditambahkan')),
          );
        },
      ),
    );
  }

  Future<void> _openAnalyticsSheet() async {
    final state = ref.read(financeProvider);
    final transactions = state.entries;
    final categories = _buildCategoryData(transactions, state.totalSpent);
    final topCategory = categories.isEmpty ? null : categories.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ringkasan Analitik',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dashboard dan SmartLife AI sekarang saling terhubung dari sini.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              _MetricTile(
                label: 'Total Pengeluaran',
                value: AppFormatters.currency(state.totalSpent),
                icon: Icons.payments_rounded,
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(height: 12),
              _MetricTile(
                label: 'Sisa Budget',
                value: AppFormatters.currency(state.remainingBudget),
                icon: Icons.savings_rounded,
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(height: 12),
              _MetricTile(
                label: 'Kategori Terbesar',
                value: topCategory == null
                    ? 'Belum ada data'
                    : '${topCategory.name} • ${AppFormatters.currency(topCategory.amount)}',
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Buka SmartLife AI',
                  onPressed: () {
                    Navigator.pop(context);
                    _openSmartAi();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(width: 150, height: 28, borderRadius: 10),
                    SizedBox(height: 10),
                    LoadingSkeleton(width: 210, height: 14, borderRadius: 8),
                  ],
                ),
                LoadingSkeleton(width: 104, height: 38, borderRadius: 20),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              const [
                LoadingSkeleton(
                    width: double.infinity, height: 206, borderRadius: 32),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: LoadingSkeleton(
                            width: double.infinity,
                            height: 136,
                            borderRadius: 28)),
                    SizedBox(width: 16),
                    Expanded(
                        child: LoadingSkeleton(
                            width: double.infinity,
                            height: 136,
                            borderRadius: 28)),
                  ],
                ),
                SizedBox(height: 16),
                LoadingSkeleton(
                    width: double.infinity, height: 238, borderRadius: 32),
                SizedBox(height: 16),
                LoadingSkeleton(
                    width: double.infinity, height: 216, borderRadius: 32),
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded,
                  color: isDark ? Colors.white54 : Colors.black38, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  readOnly: true,
                  onTap: _openSmartAi,
                  decoration: InputDecoration(
                    hintText: 'Tanya AI apa saja...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openSmartAi,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_none_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      (
        label: 'Add Expense',
        icon: Icons.add_rounded,
        color: const Color(0xFF6366F1),
        onTap: _openAddExpenseSheet
      ),
      (
        label: 'Reminders',
        icon: Icons.notifications_none_rounded,
        color: const Color(0xFFF59E0B),
        onTap: _openReminderCenter
      ),
      (
        label: 'Analytics',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF10B981),
        onTap: _openAnalyticsSheet
      ),
      (
        label: 'Smart AI',
        icon: Icons.auto_awesome_rounded, // Keeps the icon for reference, but we will use asset below
        color: const Color(0xFFEC4899),
        onTap: _openSmartAi
      ),
      (
        label: 'Life Hub',
        icon: Icons.rocket_launch_rounded,
        color: const Color(0xFFF472B6),
        onTap: _openLifeHub
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  action.onTap();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: action.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: action.label == 'Smart AI'
                            ? Icon(action.icon, color: action.color, size: 16)
                            : Icon(action.icon, color: action.color, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        action.label,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSavingsGoalBento(bool isDark) {
    final financeState = ref.watch(financeProvider);
    final goal = financeState.goals.firstOrNull;

    if (goal == null) {
      return ModernGlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 32,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.add_task_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIAPKAN TABUNGAN',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buat target keuangan pertamamu',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final double progress = goal.progress;
    final Color goalColor =
        Color(int.parse(goal.color.replaceFirst('#', '0xFF')));

    return ModernGlassCard(
      padding: const EdgeInsets.all(28),
      borderRadius: 32,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                    ),
                  ),
                ),
                Center(
                    child: Text('${(progress * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B)))),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: goalColor, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'SAVINGS GOAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: goalColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  goal.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${AppFormatters.currency(goal.targetAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBentoCard(
      List<({String name, double amount, double percentage, Color color})>
          categoryData,
      bool isDark) {
    return ModernGlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENDING MIX',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (categoryData.isEmpty)
            const Center(child: Text('No data available'))
          else
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 34,
                      sections: categoryData.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final data = entry.value;
                        final bool isTouched = index == _touchedPieIndex;
                        return PieChartSectionData(
                          color: data.color,
                          value: data.percentage * 100,
                          title: isTouched
                              ? '${(data.percentage * 100).toStringAsFixed(0)}%'
                              : '',
                          radius: isTouched ? 48.0 : 40.0,
                          titleStyle: GoogleFonts.poppins(
                              fontSize: isTouched ? 16 : 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        );
                      }).toList(),
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: categoryData.take(3).map((data) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: data.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(data.name,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF475569),
                                        fontWeight: FontWeight.w700))),
                            Text(
                                '${(data.percentage * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRemindersBento(bool isDark) {
    final reminderState = ref.watch(reminderProvider);
    final pending =
        reminderState.reminders.where((r) => !r.isCompleted).toList();

    return ModernGlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AppAssetIcon(
                    path: AppConstants.appLogoPath,
                    size: 16,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'UPCOMING',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _openReminderCenter,
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (pending.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: <Widget>[
                  AppAssetIcon(
                    path: AppConstants.appLogoPath,
                    size: 18,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All clear for today',
                      style: GoogleFonts.inter(
                        color:
                            isDark ? Colors.white70 : const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...pending.take(2).map((reminder) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.alarm_rounded,
                              color: AppColors.primary, size: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reminder.title,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B))),
                            Text(AppFormatters.timeOnly(reminder.dateTime),
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  List<({String name, double amount, double percentage, Color color})>
      _buildCategoryData(
          List<FinanceEntryEntity> transactions, double totalSpent) {
    if (transactions.isEmpty || totalSpent <= 0) return [];
    final Map<String, double> totals = {};
    for (final tx in transactions) {
      totals.update(tx.category, (v) => v + tx.amount,
          ifAbsent: () => tx.amount);
    }
    final result = financeCategories
        .map((cat) {
          final amount = totals[cat.id] ?? 0;
          return (
            name: cat.name,
            amount: amount,
            percentage: amount / totalSpent,
            color: cat.color
          );
        })
        .where((item) => item.amount > 0)
        .toList();
    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result.take(5).toList();
  }

  ({List<FlSpot> spots, List<String> labels}) _buildWeeklySeries(
      List<FinanceEntryEntity> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates =
        List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final totals = List.filled(7, 0.0);
    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      for (int i = 0; i < 7; i++) {
        if (txDate == dates[i]) {
          totals[i] += tx.amount;
          break;
        }
      }
    }
    return (
      spots: List.generate(7, (i) => FlSpot(i.toDouble(), totals[i])),
      labels: dates.map((d) => AppFormatters.weekDayShort(d)).toList(),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton(
      {super.key,
      required this.width,
      required this.height,
      required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
        duration: 1.5.seconds, color: isDark ? Colors.white12 : Colors.black12);
  }
}
