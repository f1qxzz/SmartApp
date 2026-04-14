import 'package:hive_flutter/hive_flutter.dart';

import 'package:smartlife_app/core/storage/hive_boxes.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(HiveBoxes.auth),
      Hive.openBox(HiveBoxes.app),
      Hive.openBox(HiveBoxes.reminders),
    ]);
  }

  static Box<dynamic> get authBox => Hive.box(HiveBoxes.auth);
  static Box<dynamic> get appBox => Hive.box(HiveBoxes.app);

  static String? get token => authBox.get(HiveBoxes.token) as String?;

  static Future<void> saveToken(String token) async {
    await authBox.put(HiveBoxes.token, token);
  }

  static Future<void> clearToken() async {
    await authBox.delete(HiveBoxes.token);
  }

  static Map<String, dynamic>? get user {
    final value = authBox.get(HiveBoxes.user);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await authBox.put(HiveBoxes.user, user);
  }

  static Future<void> clearUser() async {
    await authBox.delete(HiveBoxes.user);
  }

  static Future<void> clearAuth() async {
    await Future.wait([clearToken(), clearUser(), clearRememberMe()]);
  }

  static bool get rememberMe =>
      (authBox.get(HiveBoxes.rememberMe) as bool?) ?? false;

  static Future<void> saveRememberMe(bool value) async {
    await authBox.put(HiveBoxes.rememberMe, value);
  }

  static Future<void> clearRememberMe() async {
    await authBox.delete(HiveBoxes.rememberMe);
  }
}
