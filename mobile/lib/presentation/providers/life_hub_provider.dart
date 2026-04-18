import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartlife_app/domain/entities/life_hub_entities.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';

class LifeHubState {
  final List<Habit> habits;
  final List<LifeGoal> goals;
  final bool isLoading;

  LifeHubState({
    required this.habits,
    required this.goals,
    this.isLoading = false,
  });

  LifeHubState copyWith({
    List<Habit>? habits,
    List<LifeGoal>? goals,
    bool? isLoading,
  }) {
    return LifeHubState(
      habits: habits ?? this.habits,
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final lifeHubProvider = StateNotifierProvider<LifeHubNotifier, LifeHubState>((ref) {
  return LifeHubNotifier();
});

class LifeHubNotifier extends StateNotifier<LifeHubState> {
  LifeHubNotifier() : super(LifeHubState(habits: [], goals: [])) {
    loadData();
  }

  static const String _habitsKey = 'life_habits';
  static const String _goalsKey = 'life_goals';

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    
    final habitsData = HiveService.appBox.get(HiveService.userScopedAppKey(_habitsKey)) as List?;
    final goalsData = HiveService.appBox.get(HiveService.userScopedAppKey(_goalsKey)) as List?;

    final habits = habitsData?.map((e) => Habit.fromJson(Map<String, dynamic>.from(e))).toList() ?? _defaultHabits();
    final goals = goalsData?.map((e) => LifeGoal.fromJson(Map<String, dynamic>.from(e))).toList() ?? _defaultGoals();

    state = LifeHubState(habits: habits, goals: goals, isLoading: false);
  }

  List<Habit> _defaultHabits() {
    return [
      Habit(id: '1', title: 'Minum Air (2L)', icon: 'water_drop', streak: 5),
      Habit(id: '2', title: 'Olahraga 30m', icon: 'fitness_center', streak: 2),
      Habit(id: '3', title: 'Membaca Buku', icon: 'book', streak: 12),
    ];
  }

  List<LifeGoal> _defaultGoals() {
    return [
      LifeGoal(id: '1', title: 'Liburan ke Jepang', progress: 0.65, deadline: 'Des 2026', category: 'Travel'),
      LifeGoal(id: '2', title: 'Mahir Flutter', progress: 0.85, deadline: 'Mei 2026', category: 'Skill'),
    ];
  }

  Future<void> toggleHabit(String id) async {
    final updatedHabits = state.habits.map((h) {
      if (h.id == id) {
        final isCompleted = !h.isCompletedToday;
        return h.copyWith(
          isCompletedToday: isCompleted,
          streak: isCompleted ? h.streak + 1 : (h.streak > 0 ? h.streak - 1 : 0),
        );
      }
      return h;
    }).toList();

    state = state.copyWith(habits: updatedHabits);
    await _saveHabits();
  }

  Future<void> updateGoalProgress(String id, double progress) async {
    final updatedGoals = state.goals.map((g) {
      if (g.id == id) {
        return g.copyWith(progress: progress, isCompleted: progress >= 1.0);
      }
      return g;
    }).toList();

    state = state.copyWith(goals: updatedGoals);
    await _saveGoals();
  }

  Future<void> _saveHabits() async {
    await HiveService.putUserScopedAppValue(_habitsKey, state.habits.map((e) => e.toJson()).toList());
  }

  Future<void> _saveGoals() async {
    await HiveService.putUserScopedAppValue(_goalsKey, state.goals.map((e) => e.toJson()).toList());
  }

  String getAiSuggestion() {
    if (state.habits.isEmpty) return 'Tambahkan kebiasaan pertamamu untuk memulai hari!';
    
    final uncompleted = state.habits.where((h) => !h.isCompletedToday).toList();
    if (uncompleted.isEmpty) return 'Luar biasa! Semua kebiasaan hari ini sudah tercapai. Pertahankan streak-mu! 🔥';
    
    final topHabit = uncompleted.first;
    return 'Lanjutkan progresmu! Sedikit lagi kamu akan mencapai target "${topHabit.title}".';
  }
}
