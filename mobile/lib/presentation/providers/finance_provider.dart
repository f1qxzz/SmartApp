import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/core/utils/export_helper.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';
import 'package:smartlife_app/domain/usecases/finance_usecases.dart';
import 'package:smartlife_app/presentation/providers/app_providers.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';

import 'package:smartlife_app/domain/entities/savings_goal_entity.dart';
import 'package:smartlife_app/domain/entities/subscription_entity.dart';

class FinanceState {
  final List<FinanceEntryEntity> entries;
  final List<SavingsGoalEntity> goals;
  final List<SubscriptionEntity> subscriptions;
  final FinanceStatsEntity? stats;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategory;
  final String search;
  final double monthlyBudget;
  final bool isExporting;

  const FinanceState({
    this.entries = const [],
    this.goals = const [],
    this.subscriptions = const [],
    this.stats,
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory = 'Semua',
    this.search = '',
    this.monthlyBudget = 0,
    this.isExporting = false,
  });

  double get totalSpent =>
      entries.fold<double>(0, (sum, item) => sum + item.amount);
  double get budget => monthlyBudget;
  double get remainingBudget => (budget - totalSpent).clamp(0, double.infinity);
  double get percentageUsed =>
      budget <= 0 ? 0 : ((totalSpent / budget) * 100).clamp(0, 100);
  bool get isOverBudget => budget > 0 && totalSpent > budget;

  List<FinanceEntryEntity> get filteredEntries {
    final String category = selectedCategory.trim();
    final String searchQuery = search.trim().toLowerCase();

    return entries.where((entry) {
      final bool categoryMatch =
          category.isEmpty || category == 'Semua' || entry.category == category;
      if (!categoryMatch) {
        return false;
      }

      if (searchQuery.isEmpty) {
        return true;
      }

      return entry.title.toLowerCase().contains(searchQuery) ||
          entry.description.toLowerCase().contains(searchQuery) ||
          entry.category.toLowerCase().contains(searchQuery);
    }).toList();
  }

  FinanceState copyWith({
    List<FinanceEntryEntity>? entries,
    List<SavingsGoalEntity>? goals,
    List<SubscriptionEntity>? subscriptions,
    FinanceStatsEntity? stats,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
    String? search,
    double? monthlyBudget,
    bool? isExporting,
    bool clearError = false,
  }) {
    return FinanceState(
      entries: entries ?? this.entries,
      goals: goals ?? this.goals,
      subscriptions: subscriptions ?? this.subscriptions,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedCategory: selectedCategory ?? this.selectedCategory,
      search: search ?? this.search,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier(this._useCases) : super(const FinanceState());

  final FinanceUseCases _useCases;
  String? _activeUserId;

  Future<void> onAuthChanged(AuthState authState) async {
    final userId = authState.user?.id.trim();
    if (!authState.isAuthenticated || userId == null || userId.isEmpty) {
      _activeUserId = null;
      reset();
      return;
    }

    if (_activeUserId == userId && state.entries.isNotEmpty) {
      return;
    }

    _activeUserId = userId;
    state = const FinanceState();
    await load();
  }

  Future<void> load({bool silent = false}) async {
    if (_activeUserId == null || _activeUserId!.isEmpty) {
      reset();
      return;
    }

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final results = await Future.wait<dynamic>([
        _useCases.getEntries(),
        _useCases.stats(),
        _useCases.getBudget(),
        _useCases.getSavingsGoals(),
        _useCases.getSubscriptions(),
      ]);

      final entries = results[0] as List<FinanceEntryEntity>;
      final stats = results[1] as FinanceStatsEntity;
      final budget = results[2] as double;
      final goals = results[3] as List<SavingsGoalEntity>;
      final subscriptions = results[4] as List<SubscriptionEntity>;

      state = state.copyWith(
        entries: entries,
        stats: stats,
        monthlyBudget: budget,
        goals: goals,
        subscriptions: subscriptions,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> create({
    required String title,
    required double amount,
    required String category,
    String description = '',
    DateTime? date,
  }) async {
    final entry = FinanceEntryEntity(
      id: '',
      title: title.trim(),
      amount: amount,
      category: category,
      description: description.trim(),
      date: date ?? DateTime.now(),
    );

    try {
      await _useCases.create(entry);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> update(FinanceEntryEntity entry) async {
    try {
      await _useCases.update(entry.id, entry);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _useCases.delete(id);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> setBudget(double monthlyBudget) async {
    try {
      final budget = await _useCases.setBudget(monthlyBudget);
      state = state.copyWith(monthlyBudget: budget);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  // --- Savings Goals ---
  Future<void> createSavingsGoal({
    required String title,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    String color = '#6366F1',
    String icon = 'wallet_rounded',
  }) async {
    final goal = SavingsGoalEntity(
      id: '',
      userId: _activeUserId ?? '',
      title: title.trim(),
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      color: color,
      icon: icon,
    );

    try {
      await _useCases.createSavingsGoal(goal);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> updateSavingsGoal(SavingsGoalEntity goal) async {
    try {
      await _useCases.updateSavingsGoal(goal.id, goal);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    try {
      await _useCases.deleteSavingsGoal(id);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  // --- Subscriptions ---
  Future<void> createSubscription({
    required String name,
    required double amount,
    String billingCycle = 'monthly',
    String icon = 'card_giftcard_rounded',
    String color = '#6366F1',
    String status = 'active',
    DateTime? nextBillingDate,
  }) async {
    final sub = SubscriptionEntity(
      id: '',
      userId: _activeUserId ?? '',
      name: name.trim(),
      amount: amount,
      billingCycle: billingCycle,
      icon: icon,
      color: color,
      status: status,
      nextBillingDate: nextBillingDate,
    );

    try {
      await _useCases.createSubscription(sub);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> updateSubscription(SubscriptionEntity sub) async {
    try {
      await _useCases.updateSubscription(sub.id, sub);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await _useCases.deleteSubscription(id);
      await load(silent: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> setCategory(String category) async {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> setSearch(String search) async {
    state = state.copyWith(search: search);
  }

  Future<String> exportCsv({DateTime? from, DateTime? to}) async {
    state = state.copyWith(isExporting: true, clearError: true);
    try {
      final csv = await _useCases.exportCsv(from: from, to: to);
      final now = DateTime.now();
      final fileName =
          'smartlife-export-${now.year}-${now.month.toString().padLeft(2, '0')}.csv';
      final savedPath =
          await saveCsvExport(csvContent: csv, fileName: fileName);
      state = state.copyWith(isExporting: false);
      return savedPath;
    } catch (error) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  void reset() {
    state = const FinanceState();
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>(
  (ref) {
    final notifier = FinanceNotifier(ref.read(financeUseCasesProvider));

    ref.listen<AuthState>(authProvider, (previous, next) {
      notifier.onAuthChanged(next);
    });

    notifier.onAuthChanged(ref.read(authProvider));
    return notifier;
  },
);
