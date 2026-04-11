import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:smartlife_app/core/constants/app_constants.dart';

const double monthlyBudget = 5000000;
const double monthlyIncome = 8000000;

final StateProvider<ThemeMode> appThemeModeProvider =
    StateProvider<ThemeMode>((_) => ThemeMode.light);

class FinanceTransactionsNotifier extends StateNotifier<List<MockTransaction>> {
  FinanceTransactionsNotifier()
      : super(List<MockTransaction>.from(mockTransactions));

  final Uuid _uuid = const Uuid();

  void addTransaction({
    required String categoryId,
    required String description,
    required double amount,
    DateTime? date,
  }) {
    final double cleanAmount = amount <= 0 ? 0 : amount;
    if (cleanAmount == 0) {
      return;
    }

    state = <MockTransaction>[
      MockTransaction(
        id: _uuid.v4(),
        category: categoryId,
        description: description.trim().isEmpty
            ? _defaultDescriptionForCategory(categoryId)
            : description.trim(),
        amount: cleanAmount,
        date: date ?? DateTime.now(),
      ),
      ...state,
    ];
  }

  void removeTransactionById(String id) {
    state = state.where((MockTransaction tx) => tx.id != id).toList();
  }

  String _defaultDescriptionForCategory(String categoryId) {
    final FinanceCategory category = financeCategories.firstWhere(
      (FinanceCategory item) => item.id == categoryId,
      orElse: () => financeCategories.last,
    );
    return 'Pengeluaran ${category.name}';
  }
}

final StateNotifierProvider<FinanceTransactionsNotifier, List<MockTransaction>>
    financeTransactionsProvider = StateNotifierProvider<
        FinanceTransactionsNotifier, List<MockTransaction>>(
  (_) => FinanceTransactionsNotifier(),
);

final Provider<double> totalSpentProvider = Provider<double>(
  (ref) {
    final List<MockTransaction> transactions =
        ref.watch(financeTransactionsProvider);
    return transactions.fold<double>(
      0,
      (double sum, MockTransaction tx) => sum + tx.amount,
    );
  },
);

final Provider<Map<String, double>> categoryTotalsProvider =
    Provider<Map<String, double>>(
  (ref) {
    final List<MockTransaction> transactions =
        ref.watch(financeTransactionsProvider);
    final Map<String, double> totals = <String, double>{
      for (final FinanceCategory category in financeCategories) category.id: 0,
    };

    for (final MockTransaction tx in transactions) {
      totals.update(
        tx.category,
        (double value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }

    return totals;
  },
);

final Provider<double> budgetUsageProvider = Provider<double>(
  (ref) {
    final double spent = ref.watch(totalSpentProvider);
    if (monthlyBudget <= 0) {
      return 0;
    }
    return (spent / monthlyBudget).clamp(0, 1).toDouble();
  },
);

final Provider<double> remainingBalanceProvider = Provider<double>(
  (ref) {
    final double spent = ref.watch(totalSpentProvider);
    return monthlyIncome - spent;
  },
);
