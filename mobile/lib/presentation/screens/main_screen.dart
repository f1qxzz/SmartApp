import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/finance_provider.dart';
import 'package:smartlife_app/presentation/screens/ai/ai_screen.dart';
import 'package:smartlife_app/presentation/screens/calculator/calculator_screen.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_list_screen.dart';
import 'package:smartlife_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:smartlife_app/presentation/screens/finance/finance_screen.dart';
import 'package:smartlife_app/presentation/screens/profile/profile_screen.dart';
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
    CalculatorScreen(),
    DashboardScreen(),
    AIScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialTab();
    _authSubscription = ref.listenManual<AuthState>(
      authProvider,
      (AuthState? previous, AuthState next) {
        _showRegisterSuccess(next);
      },
      fireImmediately: true,
    );
  }

  void _loadInitialTab() {
    final savedIndex = HiveService.appBox.get(HiveBoxes.lastTab) as int?;
    if (savedIndex != null && savedIndex >= 0 && savedIndex < _screens.length) {
      _currentIndex = savedIndex;
    }
  }

  void _updateTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    HiveService.appBox.put(HiveBoxes.lastTab, index);
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
      extendBody: true,
      body: FadeIndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showAddTransaction(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              tooltip: 'Tambah transaksi',
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x557C7E9D),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
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
        onTap: _updateTab,
        isDark: isDark,
      ),
    );
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
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Alert: pengeluaran bulan ini melebihi budget',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          messenger.showSnackBar(
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

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
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
      (Icons.calculate_outlined, Icons.calculate_rounded, 'Hitung'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Dashboard'),
      (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'AI'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161A2D).withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List<Widget>.generate(
                    items.length,
                    (int i) {
                      final bool isActive = currentIndex == i;
                      return GestureDetector(
                        onTap: () {
                          if (!isActive) HapticFeedback.lightImpact();
                          onTap(i);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.fastOutSlowIn,
                          padding: isActive
                              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                              : const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: isActive ? AppColors.gradientPrimary : null,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (!isActive)
                                Icon(
                                  items[i].$1,
                                  size: 24,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              if (isActive)
                                Icon(
                                  items[i].$2,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              if (isActive) ...<Widget>[
                                const SizedBox(width: 8),
                                Text(
                                  items[i].$3,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class FadeIndexedStack extends StatelessWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List<Widget>.generate(children.length, (int i) {
        final bool isActive = index == i;
        return IgnorePointer(
          ignoring: !isActive,
          child: AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: isActive ? Offset.zero : const Offset(0.0, 0.02),
              duration: duration,
              curve: Curves.easeOutQuart,
              child: AnimatedScale(
                scale: isActive ? 1.0 : 0.98,
                duration: duration,
                curve: Curves.easeOutQuart,
                child: TickerMode(
                  enabled: isActive,
                  child: children[i],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
