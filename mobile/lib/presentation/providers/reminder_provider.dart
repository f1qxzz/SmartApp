import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartlife_app/core/notifications/notification_service.dart';
import 'package:smartlife_app/data/repositories/reminder_repository_impl.dart';
import 'package:smartlife_app/domain/entities/reminder_entity.dart';
import 'package:smartlife_app/domain/repositories/reminder_repository.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl();
});

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  final notifier = ReminderNotifier(repository);

  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.onAuthChanged(next);
  });

  notifier.onAuthChanged(ref.read(authProvider));
  return notifier;
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
  String? _activeUserId;

  ReminderNotifier(this._repository) : super(ReminderState());

  Future<void> onAuthChanged(AuthState authState) async {
    final userId = authState.user?.id.trim();
    if (!authState.isAuthenticated || userId == null || userId.isEmpty) {
      _activeUserId = null;
      state = ReminderState();
      await NotificationService.instance.syncReminderNotifications(const []);
      return;
    }

    if (_activeUserId == userId && state.reminders.isNotEmpty) {
      return;
    }

    _activeUserId = userId;
    await loadReminders();
  }

  Future<void> loadReminders() async {
    if (_activeUserId == null || _activeUserId!.isEmpty) {
      state = state.copyWith(reminders: const [], isLoading: false);
      await NotificationService.instance.syncReminderNotifications(const []);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final reminders = await _repository.getAll();
      await NotificationService.instance.syncReminderNotifications(reminders);
      state = state.copyWith(reminders: reminders, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addReminder(ReminderEntity reminder) async {
    try {
      await _repository.save(reminder);
      await NotificationService.instance.scheduleReminder(reminder);
      await loadReminders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateReminder(ReminderEntity reminder) async {
    try {
      await _repository.update(reminder);
      await NotificationService.instance.scheduleReminder(reminder);
      await loadReminders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      await _repository.delete(id);
      await NotificationService.instance.cancelReminder(id);
      await loadReminders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleCompletion(String id) async {
    try {
      final reminder = state.reminders.firstWhere((r) => r.id == id);
      final updated = reminder.copyWith(isCompleted: !reminder.isCompleted);
      if (updated.isCompleted) {
        await NotificationService.instance.cancelReminder(updated.id);
      } else {
        await NotificationService.instance.scheduleReminder(updated);
      }
      await updateReminder(updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
