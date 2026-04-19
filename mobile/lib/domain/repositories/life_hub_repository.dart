import 'package:smartlife_app/domain/entities/life_hub_entities.dart';

abstract class LifeHubRepository {
  // Habits
  Future<List<Habit>> getHabits();
  Future<Habit> createHabit(Habit habit);
  Future<Habit> updateHabit(String id, Habit habit);
  Future<void> deleteHabit(String id);
  Future<Habit> toggleHabit(String id);

  // Life Goals
  Future<List<LifeGoal>> getGoals();
  Future<LifeGoal> createGoal(LifeGoal goal);
  Future<LifeGoal> updateGoal(String id, LifeGoal goal);
  Future<void> deleteGoal(String id);
}
