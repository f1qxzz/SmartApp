import 'dart:math' as math;
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/savings_goal_entity.dart';
import 'package:smartlife_app/domain/entities/subscription_entity.dart';
import 'package:smartlife_app/presentation/providers/finance_provider.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class WealthHubScreen extends ConsumerStatefulWidget {
  const WealthHubScreen({super.key});

  @override
  ConsumerState<WealthHubScreen> createState() => _WealthHubScreenState();
}

class _WealthHubScreenState extends ConsumerState<WealthHubScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final FinanceState financeState = ref.watch(financeProvider);
    final List<SubscriptionEntity> activeSubscriptions = financeState
        .subscriptions
        .where((SubscriptionEntity sub) => sub.status == 'active')
        .toList();
    final double totalGoalTarget = financeState.goals.fold<double>(
      0,
      (double sum, SavingsGoalEntity item) => sum + item.targetAmount,
    );
    final double totalGoalSaved = financeState.goals.fold<double>(
      0,
      (double sum, SavingsGoalEntity item) => sum + item.currentAmount,
    );
    final double commitmentPerMonth = activeSubscriptions.fold<double>(
      0,
      (double sum, SubscriptionEntity item) => sum + _monthlyCommitment(item),
    );
    final List<({String title, String message, IconData icon, Color color})>
        insights =
        _buildInsights(financeState, activeSubscriptions, commitmentPerMonth);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          _WealthBackground(isDark: isDark),
          RefreshIndicator(
            onRefresh: () => ref.read(financeProvider.notifier).load(),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    child: _buildHeader(isDark),
                  ),
                ),
                if (financeState.isLoading &&
                    financeState.entries.isEmpty &&
                    financeState.goals.isEmpty &&
                    financeState.subscriptions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        <Widget>[
                          _buildSnapshotCard(
                            isDark: isDark,
                            state: financeState,
                            commitmentPerMonth: commitmentPerMonth,
                            totalGoalTarget: totalGoalTarget,
                            totalGoalSaved: totalGoalSaved,
                          )
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.06),
                          const SizedBox(height: 18),
                          _buildQuickActions(isDark)
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 500.ms)
                              .slideY(begin: 0.08),
                          const SizedBox(height: 18),
                          _buildInsightSection(isDark, insights)
                              .animate()
                              .fadeIn(delay: 180.ms, duration: 500.ms),
                          const SizedBox(height: 18),
                          _buildCashflowSection(isDark, financeState.entries)
                              .animate()
                              .fadeIn(delay: 240.ms, duration: 500.ms)
                              .slideY(begin: 0.08),
                          const SizedBox(height: 18),
                          _buildGoalSection(isDark, financeState.goals)
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 500.ms)
                              .slideY(begin: 0.08),
                          const SizedBox(height: 18),
                          _buildSubscriptionSection(isDark, activeSubscriptions)
                              .animate()
                              .fadeIn(delay: 360.ms, duration: 500.ms)
                              .slideY(begin: 0.08),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Wealth Planner',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pusat perencanaan finansial yang tersimpan permanen untuk akun Anda.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          onSelected: (String value) {
            switch (value) {
              case 'budget':
                _openBudgetEditor();
                break;
              case 'goal':
                _openGoalEditor();
                break;
              case 'subscription':
                _openSubscriptionEditor();
                break;
            }
          },
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'budget', child: Text('Atur Budget')),
            PopupMenuItem<String>(value: 'goal', child: Text('Tambah Goal')),
            PopupMenuItem<String>(
              value: 'subscription',
              child: Text('Tambah Subscription'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.tune_rounded,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotCard({
    required bool isDark,
    required FinanceState state,
    required double commitmentPerMonth,
    required double totalGoalTarget,
    required double totalGoalSaved,
  }) {
    final double goalProgress = totalGoalTarget <= 0
        ? 0
        : (totalGoalSaved / totalGoalTarget).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                const Color(0xFF243B67).withValues(alpha: 0.96),
                const Color(0xFF4C5372).withValues(alpha: 0.92),
                const Color(0xFF7C7E9D).withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF243B67).withValues(alpha: 0.34),
                blurRadius: 34,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'FINANCIAL SNAPSHOT',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.currency(state.monthlyBudget),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.monthlyBudget > 0
                              ? 'Budget aktif bulan ${AppFormatters.monthYear(DateTime.now())}'
                              : 'Atur budget bulanan agar Wealth bisa memberi insight yang realistis',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildSnapshotStat(
                      'Pengeluaran',
                      AppFormatters.currency(state.totalSpent),
                      Icons.arrow_upward_rounded,
                      const Color(0xFFFCA5A5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSnapshotStat(
                      'Sisa Budget',
                      AppFormatters.currency(state.remainingBudget),
                      Icons.savings_rounded,
                      const Color(0xFF86EFAC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildSnapshotStat(
                      'Komitmen / Bulan',
                      AppFormatters.currency(commitmentPerMonth),
                      Icons.receipt_long_rounded,
                      const Color(0xFFFDE68A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSnapshotStat(
                      'Goal Aktif',
                      '${state.goals.length} target',
                      Icons.flag_rounded,
                      const Color(0xFFBFDBFE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Progress semua goal',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    totalGoalTarget <= 0
                        ? 'Belum ada target'
                        : '${(goalProgress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: goalProgress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF86EFAC)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnapshotStat(
    String label,
    String value,
    IconData icon,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final List<({String title, IconData icon, VoidCallback onTap})> actions =
        <({String title, IconData icon, VoidCallback onTap})>[
      (
        title: 'Atur Budget',
        icon: Icons.account_balance_wallet_outlined,
        onTap: _openBudgetEditor,
      ),
      (title: 'Tambah Goal', icon: Icons.flag_outlined, onTap: _openGoalEditor),
      (
        title: 'Tambah Subscription',
        icon: Icons.subscriptions_outlined,
        onTap: _openSubscriptionEditor,
      ),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: action == actions.last ? 0 : 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.03),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(action.icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        action.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightSection(
    bool isDark,
    List<({String title, String message, IconData icon, Color color})> insights,
  ) {
    return _buildSectionContainer(
      isDark: isDark,
      title: 'Next Best Actions',
      subtitle:
          'Insight yang lebih membantu dan realistis berdasarkan data Anda.',
      trailing: Text(
        '${insights.length} insight',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white54 : const Color(0xFF64748B),
        ),
      ),
      child: Column(
        children: insights.map((insight) {
          final bool isLast = insight == insights.last;
          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: insight.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(insight.icon, color: insight.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        insight.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.message,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.55,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCashflowSection(bool isDark, List<FinanceEntryEntity> entries) {
    final ({List<FlSpot> spots, List<String> labels}) series =
        _buildMonthlySeries(entries);
    final double maxY = math.max(
      100000,
      series.spots.fold<double>(
            0,
            (double maxValue, FlSpot spot) => math.max(maxValue, spot.y),
          ) *
          1.2,
    );

    return _buildSectionContainer(
      isDark: isDark,
      title: 'Cashflow Trend',
      subtitle:
          '6 bulan terakhir berdasarkan transaksi yang tersimpan di database.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
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
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index < 0 || index >= series.labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            series.labels[index],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
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
                    spots: series.spots,
                    isCurved: true,
                    barWidth: 4,
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF4C5372), Color(0xFF8B5CF6)],
                    ),
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          const Color(0xFF4C5372).withValues(alpha: 0.18),
                          const Color(0xFF4C5372).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            entries.isEmpty
                ? 'Belum ada histori transaksi untuk divisualisasikan.'
                : 'Trend ini diperbarui setiap user menambah, mengubah, atau menghapus transaksi.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSection(bool isDark, List<SavingsGoalEntity> goals) {
    return _buildSectionContainer(
      isDark: isDark,
      title: 'Goals in Progress',
      subtitle:
          'Target tabungan yang tersimpan permanen per user dan bisa Anda ubah kapan saja.',
      trailing: TextButton(
        onPressed: _openGoalEditor,
        child: const Text('Tambah'),
      ),
      child: goals.isEmpty
          ? _buildEmptyState(
              isDark: isDark,
              icon: Icons.flag_outlined,
              title: 'Belum ada goal',
              message:
                  'Buat target keuangan pertama agar Wealth bisa membantu memberi arah yang lebih nyata.',
              buttonLabel: 'Buat Goal',
              onTap: _openGoalEditor,
            )
          : Column(
              children: goals.map((SavingsGoalEntity goal) {
                final bool isLast = goal == goals.last;
                final Color goalColor = _colorFromHex(goal.color);
                return Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: goalColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _iconFromName(goal.icon),
                              color: goalColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  goal.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  goal.deadline == null
                                      ? 'Tanpa deadline'
                                      : 'Target ${AppFormatters.relativeDate(goal.deadline!)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (String value) {
                              if (value == 'edit') {
                                _openGoalEditor(goal: goal);
                              } else if (value == 'delete') {
                                _deleteGoal(goal);
                              }
                            },
                            itemBuilder: (_) => const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '${(goal.progress * 100).toStringAsFixed(0)}% tercapai',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: goalColor,
                            ),
                          ),
                          Text(
                            '${AppFormatters.currency(goal.currentAmount)} / ${AppFormatters.currency(goal.targetAmount)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: goal.progress,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSubscriptionSection(
    bool isDark,
    List<SubscriptionEntity> subscriptions,
  ) {
    return _buildSectionContainer(
      isDark: isDark,
      title: 'Recurring Commitments',
      subtitle:
          'Semua subscription aktif tersimpan permanen dan hanya berubah saat Anda mengeditnya.',
      trailing: TextButton(
        onPressed: _openSubscriptionEditor,
        child: const Text('Tambah'),
      ),
      child: subscriptions.isEmpty
          ? _buildEmptyState(
              isDark: isDark,
              icon: Icons.subscriptions_outlined,
              title: 'Belum ada subscription aktif',
              message:
                  'Catat komitmen rutin agar pengeluaran bulanan terlihat lebih realistis.',
              buttonLabel: 'Tambah Subscription',
              onTap: _openSubscriptionEditor,
            )
          : Column(
              children: subscriptions.map((SubscriptionEntity subscription) {
                final bool isLast = subscription == subscriptions.last;
                final Color accent = _colorFromHex(subscription.color);
                return Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _iconFromName(subscription.icon),
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    subscription.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      subscription.status,
                                    ).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusLabel(subscription.status),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(subscription.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppFormatters.currency(subscription.amount)} • ${_billingLabel(subscription.billingCycle)}',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subscription.nextBillingDate == null
                                  ? 'Tanggal tagihan berikutnya belum diatur'
                                  : 'Tagihan berikutnya ${AppFormatters.relativeDate(subscription.nextBillingDate!)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          if (value == 'edit') {
                            _openSubscriptionEditor(subscription: subscription);
                          } else if (value == 'delete') {
                            _deleteSubscription(subscription);
                          }
                        },
                        itemBuilder: (_) => const <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Hapus'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSectionContainer({
    required bool isDark,
    required String title,
    required String subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.55,
                        color:
                            isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.55,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 220,
            child: CustomButton(
              text: buttonLabel,
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }

  double _monthlyCommitment(SubscriptionEntity subscription) {
    switch (subscription.billingCycle.toLowerCase()) {
      case 'yearly':
        return subscription.amount / 12;
      case 'weekly':
        return subscription.amount * 4;
      case 'daily':
        return subscription.amount * 30;
      default:
        return subscription.amount;
    }
  }

  List<({String title, String message, IconData icon, Color color})>
      _buildInsights(
    FinanceState state,
    List<SubscriptionEntity> activeSubscriptions,
    double commitmentPerMonth,
  ) {
    final List<({String title, String message, IconData icon, Color color})>
        insights =
        <({String title, String message, IconData icon, Color color})>[];

    if (state.monthlyBudget <= 0) {
      insights.add(
        (
          title: 'Atur budget bulanan',
          message:
              'Wealth akan jauh lebih membantu setelah budget ditentukan, karena semua insight akan dihitung dari angka nyata milik Anda.',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF38BDF8),
        ),
      );
    } else if (state.isOverBudget) {
      insights.add(
        (
          title: 'Pengeluaran melewati budget',
          message:
              'Pengeluaran bulan ini sudah ${AppFormatters.currency(state.totalSpent - state.monthlyBudget)} di atas budget. Review transaksi dan komitmen rutin agar arus kas kembali sehat.',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF97316),
        ),
      );
    } else {
      insights.add(
        (
          title: 'Sisa budget masih aman',
          message:
              'Masih tersedia ${AppFormatters.currency(state.remainingBudget)} untuk bulan ini. Sebagian bisa dialihkan ke goal agar progres tabungan lebih cepat.',
          icon: Icons.savings_outlined,
          color: const Color(0xFF22C55E),
        ),
      );
    }

    if (state.goals.isEmpty) {
      insights.add(
        (
          title: 'Belum ada target finansial',
          message:
              'Tambahkan minimal satu goal supaya Wealth bisa menunjukkan progres, kebutuhan dana, dan langkah berikutnya yang lebih relevan.',
          icon: Icons.flag_outlined,
          color: const Color(0xFF8B5CF6),
        ),
      );
    } else {
      final SavingsGoalEntity closestGoal = state.goals.reduce(
        (SavingsGoalEntity current, SavingsGoalEntity next) =>
            current.progress >= next.progress ? current : next,
      );
      insights.add(
        (
          title: 'Goal terdekat untuk dituntaskan',
          message:
              '${closestGoal.title} sudah ${(closestGoal.progress * 100).toStringAsFixed(0)}% tercapai. Fokus menambah saldo goal ini bisa memberi hasil yang terasa lebih cepat.',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF6366F1),
        ),
      );
    }

    if (activeSubscriptions.isEmpty) {
      insights.add(
        (
          title: 'Belum ada komitmen rutin tercatat',
          message:
              'Jika Anda punya Netflix, Spotify, hosting, atau cicilan langganan lain, catat di sini agar proyeksi bulanan lebih realistis.',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFFEAB308),
        ),
      );
    } else {
      final double ratio = state.monthlyBudget <= 0
          ? 0
          : (commitmentPerMonth / state.monthlyBudget);
      insights.add(
        (
          title: 'Komitmen rutin bulanan',
          message:
              '${activeSubscriptions.length} subscription aktif menghabiskan sekitar ${AppFormatters.currency(commitmentPerMonth)} per bulan${state.monthlyBudget > 0 ? ' atau ${(ratio * 100).toStringAsFixed(0)}% dari budget' : ''}.',
          icon: Icons.subscriptions_outlined,
          color: const Color(0xFFEC4899),
        ),
      );
    }

    return insights.take(3).toList();
  }

  ({List<FlSpot> spots, List<String> labels}) _buildMonthlySeries(
    List<FinanceEntryEntity> entries,
  ) {
    final DateTime now = DateTime.now();
    final List<DateTime> months = List<DateTime>.generate(
      6,
      (int index) => DateTime(now.year, now.month - (5 - index)),
    );

    final List<double> totals = months.map((DateTime month) {
      return entries
          .where(
            (FinanceEntryEntity entry) =>
                entry.date.year == month.year &&
                entry.date.month == month.month,
          )
          .fold<double>(
              0, (double sum, FinanceEntryEntity item) => sum + item.amount);
    }).toList();

    return (
      spots: List<FlSpot>.generate(
        totals.length,
        (int index) => FlSpot(index.toDouble(), totals[index]),
      ),
      labels: months
          .map((DateTime month) =>
              AppFormatters.monthYear(month).split(' ').first)
          .toList(),
    );
  }

  Future<void> _openBudgetEditor() async {
    final FinanceState state = ref.read(financeProvider);
    final _BudgetFormResult? result =
        await showModalBottomSheet<_BudgetFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _BudgetFormSheet(
        initialBudget: state.monthlyBudget,
      ),
    );

    if (result == null) {
      return;
    }

    try {
      await ref.read(financeProvider.notifier).setBudget(result.monthlyBudget);
      if (!mounted) {
        return;
      }
      _showSuccess('Budget bulanan berhasil diperbarui.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  Future<void> _openGoalEditor({SavingsGoalEntity? goal}) async {
    final _GoalFormResult? result = await showModalBottomSheet<_GoalFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _GoalFormSheet(goal: goal),
    );

    if (result == null) {
      return;
    }

    try {
      final FinanceNotifier notifier = ref.read(financeProvider.notifier);
      if (goal == null) {
        await notifier.createSavingsGoal(
          title: result.title,
          targetAmount: result.targetAmount,
          currentAmount: result.currentAmount,
          deadline: result.deadline,
          color: result.color,
          icon: result.icon,
        );
      } else {
        await notifier.updateSavingsGoal(
          SavingsGoalEntity(
            id: goal.id,
            userId: goal.userId,
            title: result.title,
            targetAmount: result.targetAmount,
            currentAmount: result.currentAmount,
            deadline: result.deadline,
            color: result.color,
            icon: result.icon,
          ),
        );
      }

      if (!mounted) {
        return;
      }
      _showSuccess(
        goal == null
            ? 'Goal berhasil ditambahkan.'
            : 'Goal berhasil diperbarui.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  Future<void> _openSubscriptionEditor(
      {SubscriptionEntity? subscription}) async {
    final _SubscriptionFormResult? result =
        await showModalBottomSheet<_SubscriptionFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          _SubscriptionFormSheet(subscription: subscription),
    );

    if (result == null) {
      return;
    }

    try {
      final FinanceNotifier notifier = ref.read(financeProvider.notifier);
      if (subscription == null) {
        await notifier.createSubscription(
          name: result.name,
          amount: result.amount,
          billingCycle: result.billingCycle,
          icon: result.icon,
          color: result.color,
          status: result.status,
          nextBillingDate: result.nextBillingDate,
        );
      } else {
        await notifier.updateSubscription(
          SubscriptionEntity(
            id: subscription.id,
            userId: subscription.userId,
            name: result.name,
            amount: result.amount,
            billingCycle: result.billingCycle,
            icon: result.icon,
            color: result.color,
            status: result.status,
            nextBillingDate: result.nextBillingDate,
          ),
        );
      }

      if (!mounted) {
        return;
      }
      _showSuccess(
        subscription == null
            ? 'Subscription berhasil ditambahkan.'
            : 'Subscription berhasil diperbarui.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  Future<void> _deleteGoal(SavingsGoalEntity goal) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus goal?'),
          content: Text('Goal "${goal.title}" akan dihapus dari akun Anda.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(financeProvider.notifier).deleteSavingsGoal(goal.id);
      if (!mounted) {
        return;
      }
      _showSuccess('Goal berhasil dihapus.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  Future<void> _deleteSubscription(SubscriptionEntity subscription) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus subscription?'),
          content: Text(
            'Subscription "${subscription.name}" akan dihapus dari akun Anda.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(financeProvider.notifier).deleteSubscription(
            subscription.id,
          );
      if (!mounted) {
        return;
      }
      _showSuccess('Subscription berhasil dihapus.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    final String message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Terjadi kesalahan.' : message),
          backgroundColor: AppColors.error,
        ),
      );
  }

  Color _colorFromHex(String value) {
    final String hex = value.replaceAll('#', '').trim();
    final String normalized = hex.length == 6 ? 'FF$hex' : hex;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFF6366F1);
  }

  IconData _iconFromName(String value) {
    switch (value) {
      case 'wallet_rounded':
        return Icons.wallet_rounded;
      case 'savings_rounded':
        return Icons.savings_rounded;
      case 'flag_rounded':
        return Icons.flag_rounded;
      case 'flight_rounded':
        return Icons.flight_rounded;
      case 'laptop_mac_rounded':
        return Icons.laptop_mac_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'play_circle_rounded':
        return Icons.play_circle_rounded;
      case 'music_note_rounded':
        return Icons.music_note_rounded;
      case 'cloud_rounded':
        return Icons.cloud_rounded;
      default:
        return Icons.dashboard_customize_rounded;
    }
  }

  String _billingLabel(String value) {
    switch (value) {
      case 'yearly':
        return 'Tahunan';
      case 'weekly':
        return 'Mingguan';
      case 'daily':
        return 'Harian';
      default:
        return 'Bulanan';
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'paused':
        return 'Paused';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Active';
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'paused':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF22C55E);
    }
  }
}

class _WealthBackground extends StatelessWidget {
  const _WealthBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            isDark ? const Color(0xFF21263A) : const Color(0xFFF8FAFC),
            isDark ? const Color(0xFF111827) : const Color(0xFFEEF2FF),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -70,
            left: -40,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFF60A5FA).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: 180,
            right: -40,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 40,
            child: _GlowOrb(
              size: 180,
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color,
              blurRadius: 80,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetFormResult {
  const _BudgetFormResult({required this.monthlyBudget});

  final double monthlyBudget;
}

class _GoalFormResult {
  const _GoalFormResult({
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.color,
    required this.icon,
  });

  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String color;
  final String icon;
}

class _SubscriptionFormResult {
  const _SubscriptionFormResult({
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.icon,
    required this.color,
    required this.status,
    required this.nextBillingDate,
  });

  final String name;
  final double amount;
  final String billingCycle;
  final String icon;
  final String color;
  final String status;
  final DateTime? nextBillingDate;
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDark.withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white24
                              : Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.55,
                        color:
                            isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 22),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({required this.initialBudget});

  final double initialBudget;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _budgetController;

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController(
      text: widget.initialBudget > 0
          ? AppFormatters.currencyNoSymbol(widget.initialBudget)
          : '',
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Atur Budget',
      subtitle:
          'Budget ini menjadi dasar insight Wealth dan tersimpan permanen di akun Anda.',
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorFormatter(),
              ],
              decoration: _sheetInputDecoration(
                context,
                label: 'Budget Bulanan',
                hint: 'Contoh: 7.500.000',
                prefixText: 'Rp ',
              ),
              validator: (String? value) {
                final double parsed = _toNumber(value);
                if (parsed <= 0) {
                  return 'Masukkan budget yang valid.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Simpan Budget',
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(
                  _BudgetFormResult(
                      monthlyBudget: _toNumber(_budgetController.text)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet({this.goal});

  final SavingsGoalEntity? goal;

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  static const List<MapEntry<String, IconData>> _goalIcons =
      <MapEntry<String, IconData>>[
    MapEntry<String, IconData>('wallet_rounded', Icons.wallet_rounded),
    MapEntry<String, IconData>('savings_rounded', Icons.savings_rounded),
    MapEntry<String, IconData>('flag_rounded', Icons.flag_rounded),
    MapEntry<String, IconData>('flight_rounded', Icons.flight_rounded),
    MapEntry<String, IconData>('laptop_mac_rounded', Icons.laptop_mac_rounded),
  ];

  static const List<String> _goalColors = <String>[
    '#6366F1',
    '#22C55E',
    '#F59E0B',
    '#EC4899',
    '#38BDF8',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _currentController;
  DateTime? _deadline;
  late String _selectedColor;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    final SavingsGoalEntity? goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _targetController = TextEditingController(
      text:
          goal == null ? '' : AppFormatters.currencyNoSymbol(goal.targetAmount),
    );
    _currentController = TextEditingController(
      text: goal == null
          ? ''
          : AppFormatters.currencyNoSymbol(goal.currentAmount),
    );
    _deadline = goal?.deadline;
    _selectedColor = goal?.color ?? _goalColors.first;
    _selectedIcon = goal?.icon ?? _goalIcons.first.key;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: widget.goal == null ? 'Tambah Goal' : 'Edit Goal',
      subtitle:
          'Goal disimpan per user di database dan progresnya hanya berubah saat Anda mengeditnya.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: _sheetInputDecoration(
                context,
                label: 'Nama Goal',
                hint: 'Contoh: Dana darurat',
              ),
              validator: (String? value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Nama goal wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorFormatter(),
              ],
              decoration: _sheetInputDecoration(
                context,
                label: 'Target Dana',
                hint: 'Contoh: 10.000.000',
                prefixText: 'Rp ',
              ),
              validator: (String? value) {
                if (_toNumber(value) <= 0) {
                  return 'Target harus lebih besar dari 0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _currentController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorFormatter(),
              ],
              decoration: _sheetInputDecoration(
                context,
                label: 'Dana Terkumpul',
                hint: 'Boleh 0',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 14),
            _DateTile(
              label: 'Deadline',
              value: _deadline == null
                  ? 'Belum diatur'
                  : AppFormatters.relativeDate(_deadline!),
              onTap: _pickDeadline,
              onClear: _deadline == null
                  ? null
                  : () => setState(() => _deadline = null),
            ),
            const SizedBox(height: 18),
            Text(
              'Warna',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _goalColors.map((String color) {
                final bool selected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _hexToColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _selectedIcon,
              items: _goalIcons.map((MapEntry<String, IconData> item) {
                return DropdownMenuItem<String>(
                  value: item.key,
                  child: Row(
                    children: <Widget>[
                      Icon(item.value, size: 18),
                      const SizedBox(width: 10),
                      Text(item.key
                          .replaceAll('_rounded', '')
                          .replaceAll('_', ' ')),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _selectedIcon = value);
                }
              },
              decoration: _sheetInputDecoration(
                context,
                label: 'Ikon Goal',
                hint: '',
              ),
            ),
            const SizedBox(height: 22),
            CustomButton(
              text: widget.goal == null ? 'Simpan Goal' : 'Update Goal',
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(
                  _GoalFormResult(
                    title: _titleController.text.trim(),
                    targetAmount: _toNumber(_targetController.text),
                    currentAmount: _toNumber(_currentController.text),
                    deadline: _deadline,
                    color: _selectedColor,
                    icon: _selectedIcon,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }
}

class _SubscriptionFormSheet extends StatefulWidget {
  const _SubscriptionFormSheet({this.subscription});

  final SubscriptionEntity? subscription;

  @override
  State<_SubscriptionFormSheet> createState() => _SubscriptionFormSheetState();
}

class _SubscriptionFormSheetState extends State<_SubscriptionFormSheet> {
  static const List<MapEntry<String, IconData>> _subscriptionIcons =
      <MapEntry<String, IconData>>[
    MapEntry<String, IconData>(
      'card_giftcard_rounded',
      Icons.card_giftcard_rounded,
    ),
    MapEntry<String, IconData>(
        'play_circle_rounded', Icons.play_circle_rounded),
    MapEntry<String, IconData>('music_note_rounded', Icons.music_note_rounded),
    MapEntry<String, IconData>('cloud_rounded', Icons.cloud_rounded),
    MapEntry<String, IconData>('wallet_rounded', Icons.wallet_rounded),
  ];

  static const List<String> _colors = <String>[
    '#6366F1',
    '#22C55E',
    '#F59E0B',
    '#EC4899',
    '#38BDF8',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late String _billingCycle;
  late String _selectedIcon;
  late String _selectedColor;
  late String _status;
  DateTime? _nextBillingDate;

  @override
  void initState() {
    super.initState();
    final SubscriptionEntity? subscription = widget.subscription;
    _nameController = TextEditingController(text: subscription?.name ?? '');
    _amountController = TextEditingController(
      text: subscription == null
          ? ''
          : AppFormatters.currencyNoSymbol(subscription.amount),
    );
    _billingCycle = subscription?.billingCycle ?? 'monthly';
    _selectedIcon = subscription?.icon ?? _subscriptionIcons.first.key;
    _selectedColor = subscription?.color ?? _colors.first;
    _status = subscription?.status ?? 'active';
    _nextBillingDate = subscription?.nextBillingDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: widget.subscription == null
          ? 'Tambah Subscription'
          : 'Edit Subscription',
      subtitle:
          'Komitmen rutin ini tersimpan di database dan akan tetap sama sampai Anda mengubahnya.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: _sheetInputDecoration(
                context,
                label: 'Nama Subscription',
                hint: 'Contoh: Netflix',
              ),
              validator: (String? value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Nama subscription wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorFormatter(),
              ],
              decoration: _sheetInputDecoration(
                context,
                label: 'Nominal',
                hint: 'Contoh: 169.000',
                prefixText: 'Rp ',
              ),
              validator: (String? value) {
                if (_toNumber(value) <= 0) {
                  return 'Nominal harus lebih besar dari 0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _billingCycle,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'monthly',
                  child: Text('Bulanan'),
                ),
                DropdownMenuItem<String>(
                  value: 'yearly',
                  child: Text('Tahunan'),
                ),
                DropdownMenuItem<String>(
                  value: 'weekly',
                  child: Text('Mingguan'),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _billingCycle = value);
                }
              },
              decoration: _sheetInputDecoration(
                context,
                label: 'Siklus Tagihan',
                hint: '',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'active',
                  child: Text('Active'),
                ),
                DropdownMenuItem<String>(
                  value: 'paused',
                  child: Text('Paused'),
                ),
                DropdownMenuItem<String>(
                  value: 'cancelled',
                  child: Text('Cancelled'),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
              decoration: _sheetInputDecoration(
                context,
                label: 'Status',
                hint: '',
              ),
            ),
            const SizedBox(height: 14),
            _DateTile(
              label: 'Tanggal Tagihan Berikutnya',
              value: _nextBillingDate == null
                  ? 'Belum diatur'
                  : AppFormatters.relativeDate(_nextBillingDate!),
              onTap: _pickNextBillingDate,
              onClear: _nextBillingDate == null
                  ? null
                  : () => setState(() => _nextBillingDate = null),
            ),
            const SizedBox(height: 18),
            Text(
              'Warna',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((String color) {
                final bool selected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _hexToColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _selectedIcon,
              items: _subscriptionIcons.map((MapEntry<String, IconData> item) {
                return DropdownMenuItem<String>(
                  value: item.key,
                  child: Row(
                    children: <Widget>[
                      Icon(item.value, size: 18),
                      const SizedBox(width: 10),
                      Text(item.key
                          .replaceAll('_rounded', '')
                          .replaceAll('_', ' ')),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _selectedIcon = value);
                }
              },
              decoration: _sheetInputDecoration(
                context,
                label: 'Ikon Subscription',
                hint: '',
              ),
            ),
            const SizedBox(height: 22),
            CustomButton(
              text: widget.subscription == null
                  ? 'Simpan Subscription'
                  : 'Update Subscription',
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(
                  _SubscriptionFormResult(
                    name: _nameController.text.trim(),
                    amount: _toNumber(_amountController.text),
                    billingCycle: _billingCycle,
                    icon: _selectedIcon,
                    color: _selectedColor,
                    status: _status,
                    nextBillingDate: _nextBillingDate,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickNextBillingDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _nextBillingDate = picked);
    }
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.calendar_today_rounded, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

InputDecoration _sheetInputDecoration(
  BuildContext context, {
  required String label,
  required String hint,
  String? prefixText,
}) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    labelText: label,
    hintText: hint.isEmpty ? null : hint,
    prefixText: prefixText,
    filled: true,
    fillColor:
        isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFF6366F1),
        width: 1.4,
      ),
    ),
  );
}

double _toNumber(String? value) {
  final String normalized =
      (value ?? '').replaceAll('.', '').replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? 0;
}

Color _hexToColor(String value) {
  final String hex = value.replaceAll('#', '').trim();
  final String normalized = hex.length == 6 ? 'FF$hex' : hex;
  return Color(int.tryParse(normalized, radix: 16) ?? 0xFF6366F1);
}
