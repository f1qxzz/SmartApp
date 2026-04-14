import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/domain/entities/reminder_entity.dart';
import 'package:smartlife_app/domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  @override
  Future<List<ReminderEntity>> getAll() async {
    final box = Hive.box(HiveBoxes.reminders);
    final List<dynamic> rawData = box.values.toList();
    
    return rawData.map((data) {
      if (data is String) {
        return ReminderEntity.fromJson(jsonDecode(data));
      } else if (data is Map) {
        return ReminderEntity.fromJson(Map<String, dynamic>.from(data));
      }
      return ReminderEntity.fromJson({});
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Future<void> save(ReminderEntity reminder) async {
    final box = Hive.box(HiveBoxes.reminders);
    await box.put(reminder.id, reminder.toJson());
  }

  @override
  Future<void> update(ReminderEntity reminder) async {
    final box = Hive.box(HiveBoxes.reminders);
    await box.put(reminder.id, reminder.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final box = Hive.box(HiveBoxes.reminders);
    await box.delete(id);
  }
}
