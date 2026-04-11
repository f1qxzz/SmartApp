import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';
import 'package:smartlife_app/domain/repositories/finance_repository.dart';

class FinanceUseCases {
  FinanceUseCases(this._repository);

  final FinanceRepository _repository;

  Future<List<FinanceEntryEntity>> getEntries({String? search, String? category}) {
    return _repository.getEntries(search: search, category: category);
  }

  Future<FinanceEntryEntity> create(FinanceEntryEntity entry) => _repository.createEntry(entry);

  Future<FinanceEntryEntity> update(String id, FinanceEntryEntity entry) => _repository.updateEntry(id, entry);

  Future<void> delete(String id) => _repository.deleteEntry(id);

  Future<FinanceStatsEntity> stats() => _repository.getStats();
}
