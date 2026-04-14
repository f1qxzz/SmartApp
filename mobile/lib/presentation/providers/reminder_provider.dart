import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartlife_app/data/repositories/reminder_repository_impl.dart';
import 'package:smartlife_app/domain/entities/reminder_entity.dart';
import 'package:smartlife_app/domain/repositories/reminder_repository.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl();
});

final reminderProvider = StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return ReminderNotifier(repository);
});

class ReminderState {
  final List<ReminderEntity> reminders;
  final bool isLoading;
  final String? error;

  ReminderState({
    this.reminders = const [],
    this.isLoading = false,
    this.error,
  });

  ReminderState copyWith({
    List<ReminderEntity>? reminders,
    bool? isLoading,
    String? error,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ReminderNotifier extends StateNotifier<ReminderState> {
  final ReminderRepository _repository;

  ReminderNotifier(this._repository) : super(ReminderState()) {
    loadReminders();
  }

  Future<void> loadReminders() async {
    state = state.copyWith(isLoading: true);
    try {
      final reminders = await _repository.getAll();
      state = state.copyWith(reminders: reminders, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addReminder(ReminderEntity reminder) async {
    try {
      await _repository.save(reminder);
      await loadReminders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateReminder(ReminderEntity reminder) async {
    try {
      await _repository.update(reminder);
      await loadReminders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      await _repository.delete(id);
      await loadReminders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleCompletion(String id) async {
    try {
      final reminder = state.reminders.firstWhere((r) => r.id == id);
      final updated = reminder.copyWith(isCompleted: !reminder.isCompleted);
      await updateReminder(updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
