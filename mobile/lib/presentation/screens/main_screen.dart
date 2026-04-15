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
  bool _isQuickActionsOpen = false;
  String _activeTabUserId = '';
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
    final userId = ref.read(authProvider).user?.id;
    _loadInitialTab(userId: userId);
    _authSubscription = ref.listenManual<AuthState>(
      authProvider,
      (AuthState? previous, AuthState next) {
        final nextUserId = (next.user?.id ?? '').trim();
        if (_activeTabUserId != nextUserId) {
          _loadInitialTab(userId: next.user?.id, refreshUi: true);
        }
        _showRegisterSuccess(next);
      },
      fireImmediately: true,
    );
  }

  void _loadInitialTab({
    String? userId,
    bool refreshUi = false,
  }) {
    final scopedUserId = (userId ?? '').trim();
    final savedIndex = HiveService.getUserScopedAppInt(
      HiveBoxes.lastTab,
      userId: scopedUserId,
      fallback: 0,
      fallbackToLegacy: true,
    );
    final safeIndex =
        savedIndex >= 0 && savedIndex < _screens.length ? savedIndex : 0;

    _activeTabUserId = scopedUserId;
    if (refreshUi && mounted) {
      setState(() => _currentIndex = safeIndex);
      return;
    }

    _currentIndex = safeIndex;
  }

  void _updateTab(int index) {
    if (_isQuickActionsOpen) {
      _closeQuickActions();
    }
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    HiveService.putUserScopedAppValue(
      HiveBoxes.lastTab,
      index,
      userId: ref.read(authProvider).user?.id,
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
      extendBody: true,
      body: Stack(
        children: <Widget>[
          FadeIndexedStack(
            index: _currentIndex,
            duration: const Duration(milliseconds: 280),
            children: _screens,
          ),
          if (_isQuickActionsOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeQuickActions,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.14),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _QuickActionFabMenu(
        isDark: isDark,
        isOpen: _isQuickActionsOpen,
        onToggle: _toggleQuickActions,
        onAddTransaction: () => _runQuickAction(
          () => _showAddTransaction(context),
        ),
        onOpenChat: () => _runQuickAction(() => _updateTab(0)),
        onOpenDashboard: () => _runQuickAction(() => _updateTab(3)),
        onOpenAI: () => _runQuickAction(() => _updateTab(4)),
        onOpenProfile: () => _runQuickAction(() => _updateTab(5)),
      ),
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

  void _toggleQuickActions() {
    HapticFeedback.lightImpact();
    setState(() => _isQuickActionsOpen = !_isQuickActionsOpen);
  }

  void _closeQuickActions() {
    if (!_isQuickActionsOpen) {
      return;
    }
    setState(() => _isQuickActionsOpen = false);
  }

  void _runQuickAction(VoidCallback action) {
    _closeQuickActions();
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) {
        return;
      }
      action();
    });
  }
}

class _QuickActionFabMenu extends StatelessWidget {
  final bool isDark;
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onAddTransaction;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenDashboard;
  final VoidCallback onOpenAI;
  final VoidCallback onOpenProfile;

  const _QuickActionFabMenu({
    required this.isDark,
    required this.isOpen,
    required this.onToggle,
    required this.onAddTransaction,
    required this.onOpenChat,
    required this.onOpenDashboard,
    required this.onOpenAI,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        _buildAnimatedAction(
          order: 0,
          child: _QuickActionChip(
            label: 'Catat Transaksi',
            icon: Icons.add_card_rounded,
            isDark: isDark,
            onTap: onAddTransaction,
          ),
        ),
        _buildAnimatedAction(
          order: 1,
          child: _QuickActionChip(
            label: 'Buka Chat',
            icon: Icons.chat_bubble_rounded,
            isDark: isDark,
            onTap: onOpenChat,
          ),
        ),
        _buildAnimatedAction(
          order: 2,
          child: _QuickActionChip(
            label: 'Dashboard',
            icon: Icons.bar_chart_rounded,
            isDark: isDark,
            onTap: onOpenDashboard,
          ),
        ),
        _buildAnimatedAction(
          order: 3,
          child: _QuickActionChip(
            label: 'Smart AI',
            icon: Icons.auto_awesome_rounded,
            isDark: isDark,
            onTap: onOpenAI,
          ),
        ),
        _buildAnimatedAction(
          order: 4,
          child: _QuickActionChip(
            label: 'Profile',
            icon: Icons.person_rounded,
            isDark: isDark,
            onTap: onOpenProfile,
          ),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          onPressed: onToggle,
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: isOpen ? 'Tutup aksi cepat' : 'Buka aksi cepat',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: isOpen
                  ? const LinearGradient(
                      colors: <Color>[
                        Color(0xFF4C5372),
                        Color(0xFF2F344A),
                      ],
                    )
                  : AppColors.gradientPrimary,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.38 : 0.26),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: AnimatedRotation(
                turns: isOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Icon(
                  isOpen ? Icons.close_rounded : Icons.widgets_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedAction({
    required int order,
    required Widget child,
  }) {
    final duration = Duration(milliseconds: 160 + (order * 40));
    return IgnorePointer(
      ignoring: !isOpen,
      child: AnimatedSlide(
        duration: duration,
        curve: Curves.easeOutCubic,
        offset: isOpen ? Offset.zero : const Offset(0.3, 0.04),
        child: AnimatedOpacity(
          duration: duration,
          curve: Curves.easeOutCubic,
          opacity: isOpen ? 1 : 0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.white,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              ? const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8)
                              : const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient:
                                isActive ? AppColors.gradientPrimary : null,
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
                    child: RepaintBoundary(
                      child: children[i],
                    ),
                  ),
                ),
              ),
          ),
        );
      }),
    );
  }
}
