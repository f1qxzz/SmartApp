import 'package:smartlife_app/data/services/finance_service.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';
import 'package:smartlife_app/domain/repositories/finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl(this._financeService);

  final FinanceService _financeService;

  @override
  Future<List<FinanceEntryEntity>> getEntries({String? search, String? category}) {
    return _financeService.getEntries(search: search, category: category);
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
}
