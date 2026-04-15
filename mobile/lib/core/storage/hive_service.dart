import 'package:hive_flutter/hive_flutter.dart';

import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/session_auth_cache.dart';

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

  static String? get activeUserId {
    final sessionUserId = SessionAuthCache.user?.id.trim();
    if (sessionUserId != null && sessionUserId.isNotEmpty) {
      return sessionUserId;
    }

    final cachedUser = user;
    final rawId =
        (cachedUser?['id'] ?? cachedUser?['_id'] ?? '').toString().trim();
    return rawId.isEmpty ? null : rawId;
  }

  static String userScopedAppKey(
    String baseKey, {
    String? userId,
  }) {
    final scopedUserId = (userId ?? activeUserId ?? '').trim();
    if (scopedUserId.isEmpty) {
      return baseKey;
    }
    return '$baseKey::$scopedUserId';
  }

  static bool getUserScopedAppBool(
    String baseKey, {
    String? userId,
    bool fallback = false,
    bool fallbackToLegacy = false,
  }) {
    final scopedUserId = (userId ?? activeUserId ?? '').trim();
    if (scopedUserId.isNotEmpty) {
      final scopedValue = appBox.get(userScopedAppKey(baseKey, userId: userId));
      if (scopedValue is bool) {
        return scopedValue;
      }
    }

    if (fallbackToLegacy) {
      final legacyValue =
          _tryMigrateLegacyAppValue<bool>(baseKey, scopedUserId: scopedUserId);
      if (legacyValue != null) {
        return legacyValue;
      }
    }

    return fallback;
  }

  static int getUserScopedAppInt(
    String baseKey, {
    String? userId,
    int fallback = 0,
    bool fallbackToLegacy = false,
  }) {
    final scopedUserId = (userId ?? activeUserId ?? '').trim();
    if (scopedUserId.isNotEmpty) {
      final scopedValue = appBox.get(userScopedAppKey(baseKey, userId: userId));
      if (scopedValue is int) {
        return scopedValue;
      }
    }

    if (fallbackToLegacy) {
      final legacyValue =
          _tryMigrateLegacyAppValue<int>(baseKey, scopedUserId: scopedUserId);
      if (legacyValue != null) {
        return legacyValue;
      }
    }

    return fallback;
  }

  static String? getUserScopedAppString(
    String baseKey, {
    String? userId,
    String? fallback,
    bool fallbackToLegacy = false,
  }) {
    final scopedUserId = (userId ?? activeUserId ?? '').trim();
    if (scopedUserId.isNotEmpty) {
      final scopedValue = appBox.get(userScopedAppKey(baseKey, userId: userId));
      if (scopedValue is String) {
        return scopedValue;
      }
    }

    if (fallbackToLegacy) {
      final legacyValue = _tryMigrateLegacyAppValue<String>(
        baseKey,
        scopedUserId: scopedUserId,
      );
      if (legacyValue != null) {
        return legacyValue;
      }
    }

    return fallback;
  }

  static Future<void> putUserScopedAppValue(
    String baseKey,
    dynamic value, {
    String? userId,
  }) async {
    await appBox.put(userScopedAppKey(baseKey, userId: userId), value);
  }

  static T? _tryMigrateLegacyAppValue<T>(
    String baseKey, {
    required String scopedUserId,
  }) {
    final legacyValue = appBox.get(baseKey);
    if (legacyValue is! T) {
      return null;
    }

    if (scopedUserId.isNotEmpty) {
      final scopedKey = userScopedAppKey(baseKey, userId: scopedUserId);
      appBox.put(scopedKey, legacyValue);
      appBox.delete(baseKey);
    }

    return legacyValue;
  }
}
