import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartlife_app/domain/entities/life_hub_entities.dart';
import 'package:smartlife_app/domain/repositories/life_hub_repository.dart';
import 'package:smartlife_app/presentation/providers/app_providers.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';

class LifeHubState {
  final List<Habit> habits;
  final List<LifeGoal> goals;
  final bool isLoading;
  final String? errorMessage;

  LifeHubState({
    required this.habits,
    required this.goals,
    this.isLoading = false,
    this.errorMessage,
  });

  LifeHubState copyWith({
    List<Habit>? habits,
    List<LifeGoal>? goals,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LifeHubState(
      habits: habits ?? this.habits,
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final lifeHubProvider =
    StateNotifierProvider<LifeHubNotifier, LifeHubState>((ref) {
  final notifier = LifeHubNotifier(ref.read(lifeHubRepositoryProvider));

  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.onAuthChanged(next);
  });

  notifier.onAuthChanged(ref.read(authProvider));
  return notifier;
});

class LifeHubNotifier extends StateNotifier<LifeHubState> {
  LifeHubNotifier(this._repository)
      : super(LifeHubState(habits: [], goals: []));

  final LifeHubRepository _repository;
  String? _activeUserId;

  Future<void> onAuthChanged(AuthState authState) async {
    final userId = authState.user?.id.trim();
    if (!authState.isAuthenticated || userId == null || userId.isEmpty) {
      _activeUserId = null;
      state = LifeHubState(habits: [], goals: []);
      return;
    }

    if (_activeUserId == userId && state.habits.isNotEmpty) {
      return;
    }

    _activeUserId = userId;
    await loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.getHabits(),
        _repository.getGoals(),
      ]);

      state = state.copyWith(
        habits: results[0] as List<Habit>,
        goals: results[1] as List<LifeGoal>,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  // --- Habits CRUD ---
  Future<void> toggleHabit(String id) async {
    try {
      final updated = await _repository.toggleHabit(id);
      state = state.copyWith(
        habits: state.habits.map((h) => h.id == id ? updated : h).toList(),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> addHabit({
    required String title,
    required String icon,
    String frequency = 'daily',
  }) async {
    final newHabit = Habit(
      id: '',
      title: title,
      icon: icon,
      frequency: frequency,
    );
    try {
      final created = await _repository.createHabit(newHabit);
      state = state.copyWith(habits: [...state.habits, created]);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      final updated = await _repository.updateHabit(habit.id, habit);
      state = state.copyWith(
        habits: state.habits.map((h) => h.id == habit.id ? updated : h).toList(),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> deleteHabit(String id) async {
    try {
      await _repository.deleteHabit(id);
      state = state.copyWith(
        habits: state.habits.where((h) => h.id != id).toList(),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  // --- Goals CRUD ---
  Future<void> addLifeGoal({
    required String title,
    required String deadline,
    String category = 'General',
  }) async {
    final newGoal = LifeGoal(
      id: '',
      title: title,
      progress: 0.0,
      deadline: deadline,
      category: category,
    );
    try {
      final created = await _repository.createGoal(newGoal);
      state = state.copyWith(goals: [...state.goals, created]);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> updateLifeGoal(LifeGoal goal) async {
    try {
      final updated = await _repository.updateGoal(goal.id, goal);
      state = state.copyWith(
        goals: state.goals.map((g) => g.id == goal.id ? updated : g).toList(),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> updateGoalProgress(String id, double progress) async {
    final goal = state.goals.firstWhere((g) => g.id == id);
    await updateLifeGoal(goal.copyWith(progress: progress));
  }

  Future<void> deleteLifeGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      state = state.copyWith(
        goals: state.goals.where((g) => g.id != id).toList(),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  String getAiSuggestion() {
    if (state.habits.isEmpty) {
      return 'Tambahkan kebiasaan pertamamu untuk memulai hari!';
    }

    final uncompleted = state.habits.where((h) => !h.isCompletedToday).toList();
    if (uncompleted.isEmpty) {
      return 'Luar biasa! Semua kebiasaan hari ini sudah tercapai. Pertahankan streak-mu.';
    }

    final topHabit = uncompleted.first;
    return 'Lanjutkan progresmu! Sedikit lagi kamu akan mencapai target "${topHabit.title}".';
  }
}
