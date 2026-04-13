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
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';
import 'package:smartlife_app/presentation/widgets/transaction_form_sheet.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

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
    final List<FinanceEntryEntity> filtered =
        List<FinanceEntryEntity>.from(financeState.filteredEntries)
          ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(financeProvider.notifier).load();
        },
        child: CustomScrollView(
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
                            Text('Finance',
                                style: AppTextStyles.heading2(context)),
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
                    const SizedBox(height: 20),
                    BalanceCard(
                      totalSpent: financeState.totalSpent,
                      budget: financeState.budget,
                      income: financeState.budget,
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        _QuickAction(
                          icon: Icons.edit_note_rounded,
                          label: 'Catat',
                          color: AppColors.primary,
                          onTap: _openAddSheet,
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.download_rounded,
                          label: 'Export',
                          color: AppColors.secondary,
                          onTap: _exportCsv,
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.pie_chart_outline_rounded,
                          label: 'Analisa',
                          color: AppColors.accent,
                          onTap: _openAnalyticsSheet,
                        ),
                        const SizedBox(width: 12),
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
                        Text('Transaksi',
                            style: AppTextStyles.heading3(context)),
                        if (financeState.isExporting)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: financeState.search.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref
                                      .read(financeProvider.notifier)
                                      .setSearch('');
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
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
                              financeState.selectedCategory == currentFilter.$1;
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
                                gradient:
                                    isActive ? AppColors.gradientPrimary : null,
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
                          width: double.infinity, height: 84, borderRadius: 16),
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
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
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
                          await ref
                              .read(financeProvider.notifier)
                              .delete(tx.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaksi dihapus')),
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
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
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
      text: ref.read(financeProvider).budget.toStringAsFixed(0),
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Budget Bulanan'),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget (Rp)',
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
      final value = double.parse(budgetController.text.trim());
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
