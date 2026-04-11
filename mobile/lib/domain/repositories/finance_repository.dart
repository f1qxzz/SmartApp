import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';

abstract class FinanceRepository {
  Future<List<FinanceEntryEntity>> getEntries({String? search, String? category});
  Future<FinanceEntryEntity> createEntry(FinanceEntryEntity entry);
  Future<FinanceEntryEntity> updateEntry(String id, FinanceEntryEntity entry);
  Future<void> deleteEntry(String id);
  Future<FinanceStatsEntity> getStats();
}
