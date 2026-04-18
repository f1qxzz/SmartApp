import 'package:smartlife_app/core/network/api_exception.dart';
import 'package:smartlife_app/core/network/dio_client.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';

class FinanceService {
  FinanceService(this._dioClient);

  final DioClient _dioClient;

  Future<List<FinanceEntryEntity>> getEntries({
    String? search,
    String? category,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dioClient.instance.get(
        '/api/finance',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty && category != 'Semua')
            'category': category,
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
        },
      );

      final data = List<Map<String, dynamic>>.from(
        (response.data['data'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );
      return data.map(FinanceEntryEntity.fromJson).toList();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<FinanceEntryEntity> create(FinanceEntryEntity entry) async {
    try {
      final response =
          await _dioClient.instance.post('/api/finance', data: entry.toRequest());
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return FinanceEntryEntity.fromJson(data);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<FinanceEntryEntity> update(String id, FinanceEntryEntity entry) async {
    try {
      final response = await _dioClient.instance
          .put('/api/finance/$id', data: entry.toRequest());
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return FinanceEntryEntity.fromJson(data);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dioClient.instance.delete('/api/finance/$id');
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<FinanceStatsEntity> stats() async {
    try {
      final response = await _dioClient.instance.get('/api/finance/stats');
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return FinanceStatsEntity.fromJson(data);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> exportCsv({DateTime? from, DateTime? to}) async {
    try {
      final response = await _dioClient.instance.get<String>(
        '/api/finance/export/csv',
        queryParameters: {
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
        },
      );
      return response.data ?? '';
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<double> getBudget() async {
    try {
      final response = await _dioClient.instance.get('/api/finance/budget');
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return (data['monthlyBudget'] as num?)?.toDouble() ?? 0;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<double> setBudget(double monthlyBudget) async {
    try {
      final response = await _dioClient.instance.put(
        '/api/finance/budget',
        data: {'monthlyBudget': monthlyBudget},
      );
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return (data['monthlyBudget'] as num?)?.toDouble() ?? 0;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  // --- Savings Goals ---
  Future<List<Map<String, dynamic>>> listSavingsGoals() async {
    try {
      final response = await _dioClient.instance.get('/api/finance/goals');
      return List<Map<String, dynamic>>.from(
        (response.data['data'] as List).map((i) => Map<String, dynamic>.from(i as Map)),
      );
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> createSavingsGoal(Map<String, dynamic> goal) async {
    try {
      final response = await _dioClient.instance.post('/api/finance/goals', data: goal);
      return Map<String, dynamic>.from(response.data['data'] as Map);
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> updateSavingsGoal(String id, Map<String, dynamic> goal) async {
    try {
      final response = await _dioClient.instance.put('/api/finance/goals/$id', data: goal);
      return Map<String, dynamic>.from(response.data['data'] as Map);
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    try {
      await _dioClient.instance.delete('/api/finance/goals/$id');
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Subscriptions ---
  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    try {
      final response = await _dioClient.instance.get('/api/finance/subscriptions');
      return List<Map<String, dynamic>>.from(
        (response.data['data'] as List).map((i) => Map<String, dynamic>.from(i as Map)),
      );
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> createSubscription(Map<String, dynamic> sub) async {
    try {
      final response = await _dioClient.instance.post('/api/finance/subscriptions', data: sub);
      return Map<String, dynamic>.from(response.data['data'] as Map);
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> updateSubscription(String id, Map<String, dynamic> sub) async {
    try {
      final response = await _dioClient.instance.put('/api/finance/subscriptions/$id', data: sub);
      return Map<String, dynamic>.from(response.data['data'] as Map);
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await _dioClient.instance.delete('/api/finance/subscriptions/$id');
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
