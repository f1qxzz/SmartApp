import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/constants/app_constants.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/presentation/providers/finance_provider.dart';
import 'package:smartlife_app/presentation/providers/reminder_provider.dart';
import 'package:smartlife_app/presentation/screens/reminder/reminder_screen.dart';

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
    final double maxWeeklyValue = weeklySeries.spots.fold<double>(
      0,
      (double maxValue, FlSpot spot) => math.max(maxValue, spot.y),
    );
    final double maxChartY = math.max(100000.0, maxWeeklyValue * 1.25);
    final double intervalY = math.max(25000.0, maxChartY / 4);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Dashboard', style: AppTextStyles.heading2(context)),
                      Text(
                        'Ringkasan keuangan kamu',
                        style: AppTextStyles.caption(context),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppFormatters.monthYear(DateTime.now()),
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
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Keluar',
                      value: AppFormatters.currency(totalSpent),
                      change: '${(budgetUsage * 100).toStringAsFixed(0)}% budget',
                      isPositive: budgetUsage < 0.8,
                      gradient: AppColors.gradientPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Transaksi',
                      value: '$totalTransactions',
                      change: _buildTransactionSubLabel(categoryData),
                      isPositive: true,
                      gradient: AppColors.gradientSecondary,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Kategori Pengeluaran', style: AppTextStyles.heading3(context)),
                    const SizedBox(height: 4),
                    Text('Distribusi bulan ini', style: AppTextStyles.caption(context)),
                    const SizedBox(height: 24),
                    if (categoryData.isEmpty)
                      _EmptySection(
                        icon: Icons.pie_chart_outline_rounded,
                        text: 'Belum ada transaksi untuk dianalisis.',
                      )
                    else
                      Row(
                        children: <Widget>[
                          RepaintBoundary(
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieResponse == null ||
                                            pieResponse.touchedSection == null) {
                                          _touchedPieIndex = -1;
                                        } else {
                                          _touchedPieIndex = pieResponse
                                              .touchedSection!.touchedSectionIndex;
                                        }
                                      });
                                    },
                                  ),
                                  sections: List<PieChartSectionData>.generate(
                                    categoryData.length,
                                    (int i) {
                                      final bool isTouched = i == _touchedPieIndex;
                                      final data = categoryData[i];
                                      return PieChartSectionData(
                                        color: data.color,
                                        value: data.percentage * 100,
                                        title: isTouched
                                            ? '${(data.percentage * 100).toStringAsFixed(0)}%'
                                            : '',
                                        radius: isTouched ? 65 : 55,
                                        titleStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 30,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: categoryData.map((data) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: data.color,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          data.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(data.percentage * 100).toStringAsFixed(0)}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: data.color,
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
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pengingat Mendatang', style: AppTextStyles.heading3(context)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReminderScreen()),
                        ),
                        child: Text(
                          'Lihat Semua',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final reminderState = ref.watch(reminderProvider);
                      final pendingReminders = reminderState.reminders
                          .where((r) => !r.isCompleted)
                          .toList();

                      if (pendingReminders.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notifications_paused_rounded, color: Colors.grey[400]),
                              const SizedBox(width: 12),
                              Text(
                                'Tidak ada pengingat pending',
                                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return RepaintBoundary(
                        child: SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: math.min(pendingReminders.length, 5),
                            itemBuilder: (context, index) {
                              final reminder = pendingReminders[index];
                              return Container(
                                width: 220,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: index == 0 ? AppColors.gradientPrimary : null,
                                  color: index == 0 ? null : (isDark ? AppColors.cardDark : Colors.white),
                                  borderRadius: BorderRadius.circular(24),
                                  border: index == 0 ? null : Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      reminder.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: index == 0 ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: index == 0 ? Colors.white70 : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppFormatters.timeOnly(reminder.dateTime),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: index == 0 ? Colors.white70 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Tren Mingguan', style: AppTextStyles.heading3(context)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '7 Hari',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    RepaintBoundary(
                      child: SizedBox(
                        height: 180,
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
                                color:
                                    isDark ? AppColors.dividerDark : AppColors.dividerLight,
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (double value, TitleMeta _) {
                                    final int index = value.toInt();
                                    if (index < 0 || index >= weeklySeries.labels.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        weeklySeries.labels[index],
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textTertiary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: <LineChartBarData>[
                              LineChartBarData(
                                spots: weeklySeries.spots,
                                isCurved: true,
                                curveSmoothness: 0.3,
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    AppColors.primary,
                                    AppColors.primaryLight,
                                  ],
                                ),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                    radius: 4,
                                    color: AppColors.primary,
                                    strokeColor: isDark ? AppColors.cardDark : Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      AppColors.primary.withOpacity(0.25),
                                      AppColors.primary.withOpacity(0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Kategori Paling Boros', style: AppTextStyles.heading3(context)),
                  const SizedBox(height: 12),
                  if (categoryData.isEmpty)
                    _EmptySection(
                      icon: Icons.insights_outlined,
                      text: 'Top kategori akan tampil setelah ada transaksi.',
                    )
                  else
                    ...categoryData.take(3).toList().asMap().entries.map((entry) {
                      final int index = entry.key;
                      final data = entry.value;
                      return _TopCategoryItem(
                        rank: index + 1,
                        name: data.name,
                        percentage: data.percentage,
                        color: data.color,
                        amount: AppFormatters.currency(data.amount),
                      )
                          .animate()
                          .fadeIn(delay: (300 + index * 100).ms)
                          .slideX(begin: 0.1);
                    }),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _buildTransactionSubLabel(
    List<({String name, double amount, double percentage, Color color})> categoryData,
  ) {
    if (categoryData.isEmpty) {
      return 'Belum ada data';
    }
    return 'Top: ${categoryData.first.name}';
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final Gradient gradient;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final LinearGradient castedGradient = gradient as LinearGradient;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: castedGradient.colors.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: isPositive ? AppColors.secondary : AppColors.accentLight,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopCategoryItem extends StatelessWidget {
  final int rank;
  final String name;
  final double percentage;
  final Color color;
  final String amount;

  const _TopCategoryItem({
    required this.rank,
    required this.name,
    required this.percentage,
    required this.color,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      amount,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 6,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptySection({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 28,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context),
          ),
        ],
      ),
    );
  }
}
