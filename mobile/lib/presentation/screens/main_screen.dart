import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_list_screen.dart';
import 'package:smartlife_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:smartlife_app/presentation/screens/finance/finance_screen.dart';
import 'package:smartlife_app/presentation/screens/profile/profile_screen.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  bool _isSuccessMessageScheduled = false;
  String _activeTabUserId = '';
  ProviderSubscription<AuthState>? _authSubscription;

  final List<Widget> _screens = const <Widget>[
    ChatListScreen(),
    FinanceScreen(),
    DashboardScreen(),
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
        _handleAuthFeedback(next);
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

  void _handleAuthFeedback(AuthState next) {
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

      AppAlert.show(
        context,
        title: 'Selamat Datang!',
        message: message,
        isError: false,
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
        duration: const Duration(milliseconds: 280),
        children: _screens,
      ),
      floatingActionButton: null,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _updateTab,
        isDark: isDark,
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
    final List<(IconData, IconData, String, Color)> items =
        <(IconData, IconData, String, Color)>[
      (
        Icons.chat_bubble_outline_rounded,
        Icons.chat_bubble_rounded,
        'Chat',
        const Color(0xFF4F46E5), // Primary Indigo
      ),
      (
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet_rounded,
        'Finance',
        const Color(0xFF10B981), // Emerald
      ),
      (
        Icons.bar_chart_outlined,
        Icons.bar_chart_rounded,
        'Dashboard',
        const Color(0xFF6366F1), // Indigo Light
      ),
      (
        Icons.person_outline_rounded,
        Icons.person_rounded,
        'Profile',
        const Color(0xFF0EA5E9), // Sky
      ),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? <Color>[
                            const Color(0xFF131D32).withValues(alpha: 0.88),
                            const Color(0xFF0E172A).withValues(alpha: 0.80),
                          ]
                        : <Color>[
                            Colors.white.withValues(alpha: 0.95),
                            const Color(0xFFF3F8FF).withValues(alpha: 0.90),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.98),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List<Widget>.generate(
                    items.length,
                    (int i) {
                      final bool isActive = currentIndex == i;
                      final Color itemColor = items[i].$4;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              if (!isActive) {
                                HapticFeedback.lightImpact();
                              }
                              onTap(i);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.fastOutSlowIn,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: <Color>[
                                          itemColor.withValues(alpha: 0.96),
                                          AppColors.primary
                                              .withValues(alpha: 0.92),
                                        ],
                                      )
                                    : null,
                                color: isActive
                                    ? null
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.045)
                                        : Colors.white.withValues(alpha: 0.44)),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : Colors.white.withValues(
                                          alpha: isDark ? 0.06 : 0.52,
                                        ),
                                ),
                                boxShadow: isActive
                                    ? <BoxShadow>[
                                        BoxShadow(
                                          color:
                                              itemColor.withValues(alpha: 0.28),
                                          blurRadius: 22,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : const <BoxShadow>[],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (isActive)
                                    Container(
                                      width: 16,
                                      height: 3,
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 9),
                                  Icon(
                                    isActive ? items[i].$2 : items[i].$1,
                                    size: isActive ? 20 : 19,
                                    color: isActive
                                        ? Colors.white
                                        : itemColor.withValues(
                                            alpha: isDark ? 0.84 : 0.92,
                                          ),
                                  ),
                                  const SizedBox(height: 5),
                                    Text(
                                      items[i].$3,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isActive
                                            ? Colors.white
                                            : (isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondary),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
