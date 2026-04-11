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

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final List<String> _filters = <String>[
    'Semua',
    'Makanan',
    'Transport',
    'Belanja',
    'Kesehatan',
    'Tagihan',
  ];

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
    final List<FinanceEntryEntity> filtered = List<FinanceEntryEntity>.from(financeState.entries);
    final double totalSpent = financeState.totalSpent;

    filtered.sort(
      (FinanceEntryEntity a, FinanceEntryEntity b) => b.date.compareTo(a.date),
    );

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
                            Text('Finance', style: AppTextStyles.heading2(context)),
                            Text(
                              AppFormatters.monthYear(DateTime.now()),
                              style: AppTextStyles.caption(context),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            _HeaderBtn(
                              icon: Icons.notifications_outlined,
                              badge: 2,
                              onTap: () {},
                            ),
                            const SizedBox(width: 8),
                            _HeaderBtn(
                              icon: Icons.tune_rounded,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BalanceCard(
                      totalSpent: totalSpent,
                      budget: financeState.budget,
                      income: 8000000,
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        _QuickAction(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Catat',
                          color: AppColors.primary,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.download_rounded,
                          label: 'Export',
                          color: AppColors.secondary,
                          onTap: () async {
                            final csv = ref.read(financeProvider.notifier).exportCsv();
                            await Clipboard.setData(ClipboardData(text: csv));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('CSV disalin ke clipboard')),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.pie_chart_outline_rounded,
                          label: 'Analisa',
                          color: AppColors.accent,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.flag_outlined,
                          label: 'Budget',
                          color: AppColors.error,
                          onTap: () {},
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
                        Text('Transaksi', style: AppTextStyles.heading3(context)),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Lihat semua',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        itemBuilder: (_, int i) {
                          final String currentFilter = _filters[i];
                          final bool isActive = financeState.selectedCategory == currentFilter;
                          return GestureDetector(
                            onTap: () => ref.read(financeProvider.notifier).setCategory(currentFilter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: isActive ? AppColors.gradientPrimary : null,
                                color: isActive
                                    ? null
                                    : (isDark
                                        ? AppColors.surfaceDark
                                        : AppColors.surfaceLight),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                currentFilter,
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
            if (filtered.isEmpty)
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
                          'Belum ada transaksi untuk filter ini.',
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
                      final FinanceCategory category = _getCategory(tx.category);
                      return FinanceCard(
                        id: tx.id,
                        category: category.name,
                        description: tx.description,
                        amount: tx.amount,
                        date: tx.date,
                        icon: category.icon,
                        color: category.color,
                        onDelete: () {
                          ref.read(financeProvider.notifier).delete(tx.id);
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
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _HeaderBtn({
    required this.icon,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: <Widget>[
          Container(
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
          if (badge > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
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
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
