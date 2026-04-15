import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  void loadForUser(String? userId) {
    final value = HiveService.getUserScopedAppString(
      HiveBoxes.themeMode,
      userId: userId,
      fallback: 'light',
      fallbackToLegacy: true,
    );
    if (value == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await HiveService.putUserScopedAppValue(
      HiveBoxes.themeMode,
      state == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

final appThemeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) {
    final notifier = ThemeModeNotifier();
    ref.listen<AuthState>(authProvider, (previous, next) {
      notifier.loadForUser(next.user?.id);
    });
    notifier.loadForUser(ref.read(authProvider).user?.id);
    return notifier;
  },
);
