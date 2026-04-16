import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/constants/app_constants.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/presentation/providers/finance_provider.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';
import 'package:smartlife_app/presentation/widgets/transaction_form_sheet.dart';

enum _TimeRangeFilter {
  all('Semua Waktu'),
  today('Hari Ini'),
  last7Days('7 Hari'),
  last30Days('30 Hari');

  const _TimeRangeFilter(this.label);
  final String label;
}

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  _TimeRangeFilter _selectedTimeRange = _TimeRangeFilter.all;

  final List<(String id, String label)> _filters = <(String, String)>[
    ('Semua', 'Semua'),
    ('food', 'Makanan'),
    ('transport', 'Transport'),
    ('shopping', 'Belanja'),
    ('health', 'Kesehatan'),
    ('bills', 'Tagihan'),
    ('entertainment', 'Hiburan'),
    ('other', 'Lainnya'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  FinanceCategory _getCategory(String id) {
    return financeCategories.firstWhere(
      (FinanceCategory category) => category.id == id,
      orElse: () => financeCategories.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final financeState = ref.watch(financeProvider);
    final List<FinanceEntryEntity> baseFiltered =
        List<FinanceEntryEntity>.from(financeState.filteredEntries)
          ..sort((a, b) => b.date.compareTo(a.date));
    final List<FinanceEntryEntity> filtered = baseFiltered
        .where((FinanceEntryEntity entry) => _isInSelectedTimeRange(entry.date))
        .toList();
    final double filteredTotal = filtered.fold<double>(
        0, (double sum, FinanceEntryEntity item) => sum + item.amount);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          _FinanceBackground(isDark: isDark),
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await ref.read(financeProvider.notifier).load();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 20,
                      right: 20,
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Finance Hub',
                                  style: AppTextStyles.heading2(context),
                                ),
                                Text(
                                  AppFormatters.monthYear(DateTime.now()),
                                  style: AppTextStyles.caption(context),
                                ),
                              ],
                            ),
                            _HeaderBtn(
                              icon: Icons.refresh_rounded,
                              onTap: () =>
                                  ref.read(financeProvider.notifier).load(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.dividerLight,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradientPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.insights_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pantau cashflow, atur budget, dan catat transaksi harian kamu.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 350.ms),
                        const SizedBox(height: 16),
                        BalanceCard(
                          totalSpent: financeState.totalSpent,
                          budget: financeState.budget,
                          income: financeState.budget,
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            _QuickAction(
                              icon: Icons.edit_note_rounded,
                              label: 'Catat',
                              color: AppColors.primary,
                              onTap: _openAddSheet,
                            ),
                            const SizedBox(width: 10),
                            _QuickAction(
                              icon: Icons.download_rounded,
                              label: 'Export',
                              color: AppColors.secondary,
                              onTap: _exportCsv,
                            ),
                            const SizedBox(width: 10),
                            _QuickAction(
                              icon: Icons.pie_chart_outline_rounded,
                              label: 'Analisa',
                              color: AppColors.accent,
                              onTap: _openAnalyticsSheet,
                            ),
                            const SizedBox(width: 10),
                            _QuickAction(
                              icon: Icons.flag_outlined,
                              label: 'Budget',
                              color: AppColors.error,
                              onTap: _openBudgetDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Transaksi',
                              style: AppTextStyles.heading3(context),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (filtered.isNotEmpty) ...<Widget>[
                                  _HeaderBtn(
                                    icon: Icons.content_copy_rounded,
                                    onTap: () => _duplicateLatestTransaction(
                                        filtered.first),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (financeState.isExporting)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (value) {
                            ref.read(financeProvider.notifier).setSearch(value);
                          },
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari transaksi...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textTertiary,
                            ),
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: financeState.search.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      ref
                                          .read(financeProvider.notifier)
                                          .setSearch('');
                                    },
                                    icon: const Icon(Icons.close_rounded,
                                        size: 18),
                                  ),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.primary : AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            itemBuilder: (_, int i) {
                              final currentFilter = _filters[i];
                              final bool isActive =
                                  financeState.selectedCategory ==
                                      currentFilter.$1;
                              return GestureDetector(
                                onTap: () => ref
                                    .read(financeProvider.notifier)
                                    .setCategory(currentFilter.$1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isActive
                                        ? AppColors.gradientPrimary
                                        : null,
                                    color: isActive
                                        ? null
                                        : (isDark
                                            ? AppColors.surfaceDark
                                            : AppColors.surfaceLight),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    currentFilter.$2,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _TimeRangeFilter.values
                                .map(
                                  (_TimeRangeFilter range) => _TimeFilterChip(
                                    label: range.label,
                                    isActive: _selectedTimeRange == range,
                                    onTap: () {
                                      setState(() {
                                        _selectedTimeRange = range;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FilteredSummaryStrip(
                          isDark: isDark,
                          totalText: AppFormatters.currency(filteredTotal),
                          countText: '${filtered.length} item',
                          filterLabel: _selectedTimeRange.label,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (financeState.isLoading && filtered.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: LoadingSkeleton(
                              width: double.infinity,
                              height: 84,
                              borderRadius: 16),
                        ),
                        childCount: 4,
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 28,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada transaksi',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, int i) {
                          final FinanceEntryEntity tx = filtered[i];
                          final FinanceCategory category =
                              _getCategory(tx.category);
                          return FinanceCard(
                            id: tx.id,
                            title: tx.title,
                            category: category.name,
                            description: tx.description,
                            amount: tx.amount,
                            date: tx.date,
                            icon: category.icon,
                            color: category.color,
                            onTap: () => _openEditSheet(tx),
                            onDelete: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await ref
                                  .read(financeProvider.notifier)
                                  .delete(tx.id);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Transaksi dihapus')),
                              );
                            },
                          )
                              .animate()
                              .fadeIn(delay: (50 * i).ms)
                              .slideX(begin: 0.05, end: 0);
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormSheet(
        title: 'Catat Pengeluaran',
        submitLabel: 'Simpan',
        onSubmit: (value) async {
          await ref.read(financeProvider.notifier).create(
                title: value.title,
                amount: value.amount,
                category: value.categoryId,
                description: value.description,
                date: value.date,
              );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil ditambahkan')),
          );
        },
      ),
    );
  }

  Future<void> _openEditSheet(FinanceEntryEntity entry) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormSheet(
        title: 'Edit Transaksi',
        submitLabel: 'Update',
        initialValue: TransactionFormValue(
          title: entry.title,
          categoryId: entry.category,
          description: entry.description,
          amount: entry.amount,
          date: entry.date,
        ),
        onSubmit: (value) async {
          await ref.read(financeProvider.notifier).update(
                FinanceEntryEntity(
                  id: entry.id,
                  title: value.title,
                  amount: value.amount,
                  category: value.categoryId,
                  description: value.description,
                  date: value.date,
                ),
              );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil diperbarui')),
          );
        },
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final path = await ref.read(financeProvider.notifier).exportCsv();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export CSV berhasil: $path')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export gagal: $error')),
      );
    }
  }

  Future<void> _openBudgetDialog() async {
    final TextEditingController budgetController = TextEditingController(
      text: AppFormatters.currencyNoSymbol(ref.read(financeProvider).budget),
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Budget Bulanan'),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandSeparatorFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Budget (Rp)',
            hintText: '0',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (shouldSave != true) {
      budgetController.dispose();
      return;
    }

    try {
      final cleanText = budgetController.text.replaceAll('.', '').trim();
      final value = double.parse(cleanText);
      await ref.read(financeProvider.notifier).setBudget(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget berhasil diperbarui')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update budget: $error')),
      );
    } finally {
      budgetController.dispose();
    }
  }

  Future<void> _openAnalyticsSheet() async {
    final financeState = ref.read(financeProvider);
    final breakdown = financeState.stats?.categoryBreakdown ?? const [];
    final data = breakdown
        .map(
          (item) => (
            id: item.$1,
            total: item.$2,
            category: _getCategory(item.$1),
          ),
        )
        .where((item) => item.total > 0)
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.cardDark
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        if (data.isEmpty) {
          return const SizedBox(
            height: 240,
            child: Center(child: Text('Belum ada transaksi untuk analisa.')),
          );
        }

        final total = data.fold<double>(0, (sum, item) => sum + item.total);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Analisa Pengeluaran',
                style: AppTextStyles.heading3(context),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 180,
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: List<PieChartSectionData>.generate(data.length,
                        (index) {
                      final item = data[index];
                      final double percent =
                          total > 0 ? (item.total / total) * 100 : 0.0;
                      return PieChartSectionData(
                        color: item.category.color,
                        value: percent,
                        title: '${percent.toStringAsFixed(0)}%',
                        radius: 56,
                        titleStyle: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      );
                    }),
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...data.map((item) {
                final double percent =
                    total > 0 ? (item.total / total) * 100 : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.category.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.category.name)),
                      Text('${percent.toStringAsFixed(1)}%'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  bool _isInSelectedTimeRange(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime txDate = DateTime(date.year, date.month, date.day);

    switch (_selectedTimeRange) {
      case _TimeRangeFilter.all:
        return true;
      case _TimeRangeFilter.today:
        return txDate == today;
      case _TimeRangeFilter.last7Days:
        return !txDate.isBefore(today.subtract(const Duration(days: 6)));
      case _TimeRangeFilter.last30Days:
        return !txDate.isBefore(today.subtract(const Duration(days: 29)));
    }
  }

  Future<void> _duplicateLatestTransaction(FinanceEntryEntity entry) async {
    try {
      await ref.read(financeProvider.notifier).create(
            title: '${entry.title} (copy)',
            amount: entry.amount,
            category: entry.category,
            description: entry.description,
            date: DateTime.now(),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Transaksi terakhir berhasil diduplikasi')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal duplikasi transaksi: $error')),
      );
    }
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderBtn({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.dividerLight,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : AppColors.dividerLight,
              ),
            ),
            child: Column(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TimeFilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.gradientPrimary : null,
              color: isActive
                  ? null
                  : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.dividerLight),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilteredSummaryStrip extends StatelessWidget {
  final bool isDark;
  final String totalText;
  final String countText;
  final String filterLabel;

  const _FilteredSummaryStrip({
    required this.isDark,
    required this.totalText,
    required this.countText,
    required this.filterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.filter_alt_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    filterLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            countText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            totalText,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceBackground extends StatelessWidget {
  final bool isDark;

  const _FinanceBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                  AppColors.secondary.withValues(alpha: isDark ? 0.14 : 0.08),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
