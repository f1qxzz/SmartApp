import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';
import 'package:smartlife_app/domain/entities/savings_goal_entity.dart';
import 'package:smartlife_app/domain/entities/subscription_entity.dart';
import 'package:smartlife_app/domain/repositories/finance_repository.dart';

class FinanceUseCases {
  FinanceUseCases(this._repository);

  final FinanceRepository _repository;

  Future<List<FinanceEntryEntity>> getEntries({
    String? search,
    String? category,
    DateTime? from,
    DateTime? to,
  }) {
    return _repository.getEntries(
      search: search,
      category: category,
      from: from,
      to: to,
    );
  }

  Future<FinanceEntryEntity> create(FinanceEntryEntity entry) => _repository.createEntry(entry);

  Future<FinanceEntryEntity> update(String id, FinanceEntryEntity entry) => _repository.updateEntry(id, entry);

  Future<void> delete(String id) => _repository.deleteEntry(id);

  Future<FinanceStatsEntity> stats() => _repository.getStats();

  Future<String> exportCsv({DateTime? from, DateTime? to}) =>
      _repository.exportCsv(from: from, to: to);

  Future<double> getBudget() => _repository.getBudget();

  Future<double> setBudget(double monthlyBudget) =>
      _repository.setBudget(monthlyBudget);

  // --- Savings Goals ---
  Future<List<SavingsGoalEntity>> getSavingsGoals() => _repository.getSavingsGoals();
  Future<SavingsGoalEntity> createSavingsGoal(SavingsGoalEntity goal) => _repository.createSavingsGoal(goal);
  Future<SavingsGoalEntity> updateSavingsGoal(String id, SavingsGoalEntity goal) => _repository.updateSavingsGoal(id, goal);
  Future<void> deleteSavingsGoal(String id) => _repository.deleteSavingsGoal(id);

  // --- Subscriptions ---
  Future<List<SubscriptionEntity>> getSubscriptions() => _repository.getSubscriptions();
  Future<SubscriptionEntity> createSubscription(SubscriptionEntity sub) => _repository.createSubscription(sub);
  Future<SubscriptionEntity> updateSubscription(String id, SubscriptionEntity sub) => _repository.updateSubscription(id, sub);
  Future<void> deleteSubscription(String id) => _repository.deleteSubscription(id);
}
