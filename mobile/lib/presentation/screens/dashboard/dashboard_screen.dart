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
import 'package:smartlife_app/presentation/providers/reminder_provider.dart';
import 'package:smartlife_app/presentation/screens/reminder/reminder_screen.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _touchedPieIndex = -1;

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
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: <Widget>[
              // Premium Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Dash',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Your financial pulse is stable',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      _buildTopDateBadge(isDark),
                    ],
                  ),
                ),
              ),

              // Bento Grid Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Row 1: Main Balance Card (Large)
                    _buildMainBalanceCard(totalSpent, budgetUsage, isDark)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.95, 0.95)),
                    const SizedBox(height: 16),

                    // Row 2: Two Small Grid Items
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatCard(
                            'Transaksi',
                            '$totalTransactions',
                            Icons.swap_vert_rounded,
                            AppColors.gradientPrimary,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMiniStatCard(
                            'Reminder',
                            '${ref.watch(reminderProvider).reminders.where((r) => !r.isCompleted).length}',
                            Icons.notifications_active_rounded,
                            AppColors.gradientSecondary,
                            isDark,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms, duration: 600.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),

                    // Row 3: Weekly Trend (Wide)
                    _buildWeeklyTrendCard(weeklySeries, isDark)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),

                    // Row 4: Category Distribution (Glassy Card)
                    _buildCategoryBentoCard(categoryData, isDark)
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),

                    // Row 5: Recent Reminders Bento
                    _buildRemindersBento(isDark)
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    await Future.wait<void>(<Future<void>>[
      ref.read(financeProvider.notifier).load(silent: true),
      ref.read(reminderProvider.notifier).loadReminders(),
    ]);
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
                  width: double.infinity,
                  height: 206,
                  borderRadius: 32,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LoadingSkeleton(
                        width: double.infinity,
                        height: 136,
                        borderRadius: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: LoadingSkeleton(
                        width: double.infinity,
                        height: 136,
                        borderRadius: 28,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                LoadingSkeleton(
                  width: double.infinity,
                  height: 238,
                  borderRadius: 32,
                ),
                SizedBox(height: 16),
                LoadingSkeleton(
                  width: double.infinity,
                  height: 216,
                  borderRadius: 32,
                ),
                SizedBox(height: 16),
                LoadingSkeleton(
                  width: double.infinity,
                  height: 174,
                  borderRadius: 32,
                ),
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopDateBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, 
               size: 16, 
               color: isDark ? AppColors.primaryLight : AppColors.primary),
          const SizedBox(width: 8),
          Text(
            AppFormatters.monthYear(DateTime.now()),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBalanceCard(double totalSpent, double budgetUsage, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pengeluaran',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, 
                                 color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.currency(totalSpent),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budget Usage',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(budgetUsage * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: budgetUsage,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Gradient gradient, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendCard(dynamic weeklySeries, bool isDark) {
    final double maxWeeklyValue = (weeklySeries.spots as List<FlSpot>).fold<double>(
      0,
      (double maxValue, FlSpot spot) => math.max(maxValue, spot.y),
    );
    final double maxChartY = math.max(100000.0, maxWeeklyValue * 1.3);
    final double intervalY = maxChartY / 4;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Trend',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Icon(Icons.insights_rounded, 
                   color: isDark ? Colors.white24 : Colors.black12),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxChartY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: intervalY,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final int index = value.toInt();
                        if (index < 0 || index >= weeklySeries.labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            weeklySeries.labels[index],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklySeries.spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    gradient: AppColors.gradientPrimary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBentoCard(List<dynamic> categoryData, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Mix',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
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
                        final dynamic data = entry.value;
                        final bool isTouched = index == _touchedPieIndex;
                        final double titleSize = isTouched ? 16 : 12;
                        final double radius = isTouched ? 48.0 : 40.0;

                        return PieChartSectionData(
                          color: data.color,
                          value: data.percentage * 100,
                          title: isTouched ? '${(data.percentage * 100).toStringAsFixed(0)}%' : '',
                          radius: radius,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                            final int newIndex =
                                pieTouchResponse.touchedSection!.touchedSectionIndex;
                            if (newIndex != _touchedPieIndex) {
                              _touchedPieIndex = newIndex;
                              if (newIndex != -1) {
                                HapticFeedback.lightImpact();
                              }
                            }
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
                              decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${(data.percentage * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
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
    return Consumer(
      builder: (context, ref, child) {
        final reminderState = ref.watch(reminderProvider);
        final pending = reminderState.reminders.where((r) => !r.isCompleted).toList();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2235) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      AppRoute<void>(
                        builder: (context) => const ReminderScreen(),
                        beginOffset: const Offset(0, 0.06),
                      ),
                    ),
                    child: Text('View All', 
                         style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pending.isEmpty)
                Text('All clear for today! 🚀', 
                     style: GoogleFonts.inter(color: Colors.grey, fontSize: 13))
              else
                ...pending.take(2).map((reminder) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.alarm_rounded, color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              AppFormatters.timeOnly(reminder.dateTime),
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  List<({String name, double amount, double percentage, Color color})>
      _buildCategoryData(List<FinanceEntryEntity> transactions, double totalSpent) {
    if (transactions.isEmpty || totalSpent <= 0) {
      return <({String name, double amount, double percentage, Color color})>[];
    }

    final Map<String, double> totalsByCategory = <String, double>{};
    for (final FinanceEntryEntity tx in transactions) {
      totalsByCategory.update(
        tx.category,
        (double value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }

    final List<({String name, double amount, double percentage, Color color})> result =
        financeCategories.map((FinanceCategory category) {
      final double amount = totalsByCategory[category.id] ?? 0;
      return (
        name: category.name,
        amount: amount,
        percentage: amount / totalSpent,
        color: category.color,
      );
    }).where((item) => item.amount > 0).toList();

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result.take(5).toList();
  }

  ({List<FlSpot> spots, List<String> labels}) _buildWeeklySeries(
    List<FinanceEntryEntity> transactions,
  ) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<DateTime> dates = List<DateTime>.generate(
      7,
      (int index) => today.subtract(Duration(days: 6 - index)),
    );
    final List<double> totals = List<double>.filled(7, 0);

    for (final FinanceEntryEntity tx in transactions) {
      final DateTime txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      for (int i = 0; i < dates.length; i++) {
        if (txDate == dates[i]) {
          totals[i] += tx.amount;
          break;
        }
      }
    }

    final List<FlSpot> spots = List<FlSpot>.generate(
      7,
      (int index) => FlSpot(index.toDouble(), totals[index]),
    );
    final List<String> labels =
        dates.map((DateTime date) => AppFormatters.weekDayShort(date)).toList();

    return (spots: spots, labels: labels);
  }
}
