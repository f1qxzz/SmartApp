import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/core/config/env_config.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';
import 'package:smartlife_app/domain/usecases/finance_usecases.dart';
import 'package:smartlife_app/presentation/providers/app_providers.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';

class FinanceState {
  final List<FinanceEntryEntity> entries;
  final FinanceStatsEntity? stats;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategory;
  final String search;

  const FinanceState({
    this.entries = const [],
    this.stats,
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory = 'Semua',
    this.search = '',
  });

  double get totalSpent => entries.fold<double>(0, (sum, item) => sum + item.amount);
  double get budget => EnvConfig.monthlyBudget;
  bool get isOverBudget => totalSpent > budget;
  List<FinanceEntryEntity> get filteredEntries {
    final String category = selectedCategory.trim();
    final String searchQuery = search.trim().toLowerCase();

    return entries.where((entry) {
      final bool categoryMatch = category.isEmpty || category == 'Semua' || entry.category == category;
      if (!categoryMatch) {
        return false;
      }

      if (searchQuery.isEmpty) {
        return true;
      }

      return entry.description.toLowerCase().contains(searchQuery) ||
          entry.category.toLowerCase().contains(searchQuery);
    }).toList();
  }

  FinanceState copyWith({
    List<FinanceEntryEntity>? entries,
    FinanceStatsEntity? stats,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
    String? search,
    bool clearError = false,
  }) {
    return FinanceState(
      entries: entries ?? this.entries,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedCategory: selectedCategory ?? this.selectedCategory,
      search: search ?? this.search,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier(this._useCases) : super(const FinanceState()) {
    load();
  }

  final FinanceUseCases _useCases;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final entries = await _useCases.getEntries();
      final stats = await _useCases.stats();
      state = state.copyWith(entries: entries, stats: stats, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> create({
    required double amount,
    required String category,
    required String description,
    DateTime? date,
  }) async {
    final entry = FinanceEntryEntity(
      id: '',
      amount: amount,
      category: category,
      description: description,
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

  Future<void> setCategory(String category) async {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> setSearch(String search) async {
    state = state.copyWith(search: search);
  }

  String exportCsv() {
    final rows = <List<dynamic>>[
      ['Amount', 'Category', 'Description', 'Date'],
      ...state.entries.map((e) => [e.amount, e.category, e.description, e.date.toIso8601String()]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  void reset() {
    state = const FinanceState();
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>(
  (ref) {
    final notifier = FinanceNotifier(ref.read(financeUseCasesProvider));

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isAuthenticated) {
        notifier.reset();
        return;
      }
      notifier.load();
    });

    return notifier;
  },
);
