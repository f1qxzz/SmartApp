import 'package:smartlife_app/domain/entities/reminder_entity.dart';

abstract class ReminderRepository {
  Future<List<ReminderEntity>> getAll();
  Future<void> save(ReminderEntity reminder);
  Future<void> delete(String id);
  Future<void> update(ReminderEntity reminder);
}
