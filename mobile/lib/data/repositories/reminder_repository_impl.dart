import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/storage/session_auth_cache.dart';
import 'package:smartlife_app/domain/entities/reminder_entity.dart';
import 'package:smartlife_app/domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  static const String _userIdKey = 'userId';

  String? _activeUserId() {
    final fromSession = SessionAuthCache.user?.id.trim();
    if (fromSession != null && fromSession.isNotEmpty) {
      return fromSession;
    }

    final cachedUser = HiveService.user;
    final raw =
        (cachedUser?['id'] ?? cachedUser?['_id'] ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }

  String _scopedKey(String userId, String reminderId) => '$userId::$reminderId';

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  @override
  Future<List<ReminderEntity>> getAll() async {
    final userId = _activeUserId();
    if (userId == null) {
      return <ReminderEntity>[];
    }

    final box = Hive.box(HiveBoxes.reminders);
    final allEntries = box.toMap();
    final reminders = <ReminderEntity>[];

    for (final entry in allEntries.entries) {
      final map = _toMap(entry.value);
      if (map == null) {
        continue;
      }

      final reminderId = (map['id'] ?? '').toString().trim();
      if (reminderId.isEmpty) {
        continue;
      }

      final ownerId = (map[_userIdKey] ?? '').toString().trim();
      final isCurrentUserData = ownerId == userId;

      // Backward compatibility: old reminders without owner become current user reminders.
      if (isCurrentUserData || ownerId.isEmpty) {
        if (ownerId.isEmpty) {
          final migrated = Map<String, dynamic>.from(map)
            ..[_userIdKey] = userId;
          await box.put(_scopedKey(userId, reminderId), migrated);
          if (entry.key != _scopedKey(userId, reminderId)) {
            await box.delete(entry.key);
          }
          reminders.add(ReminderEntity.fromJson(migrated));
        } else {
          reminders.add(ReminderEntity.fromJson(map));
        }
      }
    }

    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return reminders;
  }

  @override
  Future<void> save(ReminderEntity reminder) async {
    final userId = _activeUserId();
    if (userId == null) {
      throw Exception('User belum login. Tidak bisa menyimpan reminder.');
    }

    final box = Hive.box(HiveBoxes.reminders);
    final payload = reminder.toJson()..[_userIdKey] = userId;
    await box.put(_scopedKey(userId, reminder.id), payload);
    await box.delete(reminder.id);
  }

  @override
  Future<void> update(ReminderEntity reminder) async {
    final userId = _activeUserId();
    if (userId == null) {
      throw Exception('User belum login. Tidak bisa memperbarui reminder.');
    }

    final box = Hive.box(HiveBoxes.reminders);
    final payload = reminder.toJson()..[_userIdKey] = userId;
    await box.put(_scopedKey(userId, reminder.id), payload);
    await box.delete(reminder.id);
  }

  @override
  Future<void> delete(String id) async {
    final userId = _activeUserId();
    final box = Hive.box(HiveBoxes.reminders);
    if (userId != null && userId.isNotEmpty) {
      await box.delete(_scopedKey(userId, id));
    }
    await box.delete(id);
  }
}
