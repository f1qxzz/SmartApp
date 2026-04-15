import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/screens/auth/auth_screen.dart';
import 'package:smartlife_app/presentation/screens/main_screen.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final bool isLoading = authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading;
    final bool isAuthenticated = authState.isAuthenticated;

    final Widget child;
    final String stateKey;
    if (isLoading) {
      child = const _BootLoadingView();
      stateKey = 'loading';
    } else if (isAuthenticated) {
      child = const MainScreen();
      stateKey = 'main';
    } else {
      child = const AuthScreen();
      stateKey = 'auth';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget transitioningChild, Animation<double> animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: transitioningChild,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(stateKey),
        child: child,
      ),
    );
  }
}

class _BootLoadingView extends StatelessWidget {
  const _BootLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              LoadingSkeleton(width: 160, height: 26, borderRadius: 10),
              SizedBox(height: 14),
              LoadingSkeleton(width: 220, height: 14, borderRadius: 8),
              SizedBox(height: 36),
              LoadingSkeleton(width: double.infinity, height: 180, borderRadius: 24),
            ],
          ),
        ),
      ),
    );
  }
}
