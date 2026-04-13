import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/finance_provider.dart';
import 'package:smartlife_app/presentation/providers/theme_provider.dart';
import 'package:smartlife_app/presentation/screens/ai/ai_screen.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_list_screen.dart';
import 'package:smartlife_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:smartlife_app/presentation/screens/finance/finance_screen.dart';
import 'package:smartlife_app/presentation/widgets/transaction_form_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  bool _isSuccessMessageScheduled = false;
  ProviderSubscription<AuthState>? _authSubscription;

  final List<Widget> _screens = const <Widget>[
    ChatListScreen(),
    FinanceScreen(),
    DashboardScreen(),
    AIScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthState>(
      authProvider,
      (AuthState? previous, AuthState next) {
        _showRegisterSuccess(next);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  void _showRegisterSuccess(AuthState next) {
    if (!mounted) {
      return;
    }

    final String? message = next.successMessage;
    if (message == null || message.isEmpty || _isSuccessMessageScheduled) {
      return;
    }

    _isSuccessMessageScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      ref.read(authProvider.notifier).clearSuccessMessage();
      _isSuccessMessageScheduled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showAddTransaction(context),
              backgroundColor: AppColors.primary,
              elevation: 4,
              tooltip: 'Tambah transaksi',
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : null,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
        isDark: isDark,
        onToggleTheme: _toggleTheme,
        onLogout: _logout,
      ),
    );
  }

  void _toggleTheme() {
    ref.read(appThemeModeProvider.notifier).toggle();
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormSheet(
        title: 'Catat Pengeluaran',
        submitLabel: 'Simpan',
        onSubmit: (value) async {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Gagal menambahkan transaksi',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          if (!mounted) {
            return;
          }

          if (ref.read(financeProvider).isOverBudget) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Alert: pengeluaran bulan ini melebihi budget',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transaksi berhasil ditambahkan',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final List<(IconData, IconData, String)> items =
        <(IconData, IconData, String)>[
      (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
      (
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet_rounded,
        'Finance',
      ),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Dashboard'),
      (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'AI'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: <Widget>[
              ...List<Widget>.generate(
                items.length,
                (int i) => Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: currentIndex == i ? 44 : 36,
                            height: currentIndex == i ? 44 : 36,
                            decoration: BoxDecoration(
                              gradient: currentIndex == i
                                  ? AppColors.gradientPrimary
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              currentIndex == i ? items[i].$2 : items[i].$1,
                              size: currentIndex == i ? 22 : 20,
                              color: currentIndex == i
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textTertiary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: GoogleFonts.inter(
                              fontSize: currentIndex == i ? 11 : 10,
                              fontWeight: currentIndex == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: currentIndex == i
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textTertiary),
                            ),
                            child: Text(items[i].$3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggleTheme,
                onLongPress: onLogout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? AppColors.accent : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
