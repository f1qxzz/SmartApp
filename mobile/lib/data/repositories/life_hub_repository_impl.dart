import 'package:smartlife_app/data/services/life_hub_service.dart';
import 'package:smartlife_app/domain/entities/life_hub_entities.dart';
import 'package:smartlife_app/domain/repositories/life_hub_repository.dart';

class LifeHubRepositoryImpl implements LifeHubRepository {
  LifeHubRepositoryImpl(this._service);

  final LifeHubService _service;

  @override
  Future<List<Habit>> getHabits() async {
    final data = await _service.getHabits();
    return data.map(Habit.fromJson).toList();
  }

  @override
  Future<Habit> createHabit(Habit habit) async {
    final data = await _service.createHabit(habit.toJson());
    return Habit.fromJson(data);
  }

  @override
  Future<Habit> updateHabit(String id, Habit habit) async {
    final data = await _service.updateHabit(id, habit.toJson());
    return Habit.fromJson(data);
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _service.deleteHabit(id);
  }

  @override
  Future<Habit> toggleHabit(String id) async {
    final data = await _service.toggleHabit(id);
    return Habit.fromJson(data);
  }

  @override
  Future<List<LifeGoal>> getGoals() async {
    final data = await _service.getGoals();
    return data.map(LifeGoal.fromJson).toList();
  }

  @override
  Future<LifeGoal> createGoal(LifeGoal goal) async {
    final data = await _service.createGoal(goal.toJson());
    return LifeGoal.fromJson(data);
  }

  @override
  Future<LifeGoal> updateGoal(String id, LifeGoal goal) async {
    final data = await _service.updateGoal(id, goal.toJson());
    return LifeGoal.fromJson(data);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _service.deleteGoal(id);
  }
}
