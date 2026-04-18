import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';
import 'package:smartlife_app/domain/entities/savings_goal_entity.dart';
import 'package:smartlife_app/domain/entities/subscription_entity.dart';

abstract class FinanceRepository {
  Future<List<FinanceEntryEntity>> getEntries({
    String? search,
    String? category,
    DateTime? from,
    DateTime? to,
  });
  Future<FinanceEntryEntity> createEntry(FinanceEntryEntity entry);
  Future<FinanceEntryEntity> updateEntry(String id, FinanceEntryEntity entry);
  Future<void> deleteEntry(String id);
  Future<FinanceStatsEntity> getStats();
  Future<String> exportCsv({DateTime? from, DateTime? to});
  Future<double> getBudget();
  Future<double> setBudget(double monthlyBudget);

  // Savings Goals
  Future<List<SavingsGoalEntity>> getSavingsGoals();
  Future<SavingsGoalEntity> createSavingsGoal(SavingsGoalEntity goal);
  Future<SavingsGoalEntity> updateSavingsGoal(String id, SavingsGoalEntity goal);
  Future<void> deleteSavingsGoal(String id);

  // Subscriptions
  Future<List<SubscriptionEntity>> getSubscriptions();
  Future<SubscriptionEntity> createSubscription(SubscriptionEntity sub);
  Future<SubscriptionEntity> updateSubscription(String id, SubscriptionEntity sub);
  Future<void> deleteSubscription(String id);
}
