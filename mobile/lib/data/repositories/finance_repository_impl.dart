import 'package:smartlife_app/data/services/finance_service.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';
import 'package:smartlife_app/domain/entities/savings_goal_entity.dart';
import 'package:smartlife_app/domain/entities/subscription_entity.dart';
import 'package:smartlife_app/domain/repositories/finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl(this._financeService);

  final FinanceService _financeService;

  @override
  Future<List<FinanceEntryEntity>> getEntries({
    String? search,
    String? category,
    DateTime? from,
    DateTime? to,
  }) {
    return _financeService.getEntries(
      search: search,
      category: category,
      from: from,
      to: to,
    );
  }

  @override
  Future<FinanceEntryEntity> createEntry(FinanceEntryEntity entry) => _financeService.create(entry);

  @override
  Future<FinanceEntryEntity> updateEntry(String id, FinanceEntryEntity entry) {
    return _financeService.update(id, entry);
  }

  @override
  Future<void> deleteEntry(String id) => _financeService.delete(id);

  @override
  Future<FinanceStatsEntity> getStats() => _financeService.stats();

  @override
  Future<String> exportCsv({DateTime? from, DateTime? to}) =>
      _financeService.exportCsv(from: from, to: to);

  @override
  Future<double> getBudget() => _financeService.getBudget();

  @override
  Future<double> setBudget(double monthlyBudget) =>
      _financeService.setBudget(monthlyBudget);

  // --- Savings Goals ---
  @override
  Future<List<SavingsGoalEntity>> getSavingsGoals() async {
    final list = await _financeService.listSavingsGoals();
    return list.map(SavingsGoalEntity.fromJson).toList();
  }

  @override
  Future<SavingsGoalEntity> createSavingsGoal(SavingsGoalEntity goal) async {
    final data = await _financeService.createSavingsGoal(goal.toJson());
    return SavingsGoalEntity.fromJson(data);
  }

  @override
  Future<SavingsGoalEntity> updateSavingsGoal(String id, SavingsGoalEntity goal) async {
    final data = await _financeService.updateSavingsGoal(id, goal.toJson());
    return SavingsGoalEntity.fromJson(data);
  }

  @override
  Future<void> deleteSavingsGoal(String id) => _financeService.deleteSavingsGoal(id);

  // --- Subscriptions ---
  @override
  Future<List<SubscriptionEntity>> getSubscriptions() async {
    final list = await _financeService.listSubscriptions();
    return list.map(SubscriptionEntity.fromJson).toList();
  }

  @override
  Future<SubscriptionEntity> createSubscription(SubscriptionEntity sub) async {
    final data = await _financeService.createSubscription(sub.toJson());
    return SubscriptionEntity.fromJson(data);
  }

  @override
  Future<SubscriptionEntity> updateSubscription(String id, SubscriptionEntity sub) async {
    final data = await _financeService.updateSubscription(id, sub.toJson());
    return SubscriptionEntity.fromJson(data);
  }

  @override
  Future<void> deleteSubscription(String id) => _financeService.deleteSubscription(id);
}
