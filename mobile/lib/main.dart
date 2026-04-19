import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/core/notifications/notification_service.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/theme_provider.dart';
import 'package:smartlife_app/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await HiveService.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: SmartLifeApp()));

  // Run non-essential boot tasks in the background
  _backgroundBootTasks();
}

Future<void> _backgroundBootTasks() async {
  try {
    await NotificationService.instance.initialize();
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.syncReminderNotificationsFromStorage();
  } catch (e) {
    debugPrint('[BOOT] Background tasks failed: $e');
  }
}

class SmartLifeApp extends ConsumerWidget {
  const SmartLifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: 'SmartLife',
      debugShowCheckedModeBanner: false,
      themeAnimationCurve: Curves.easeInOutCubic,
      themeAnimationDuration: const Duration(milliseconds: 320),
      scrollBehavior: const AppSmoothScrollBehavior(),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AppRouter(),
    );
  }
}
