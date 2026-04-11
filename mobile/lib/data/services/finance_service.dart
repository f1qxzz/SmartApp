import 'package:dio/dio.dart';

import 'package:smartlife_app/core/network/api_exception.dart';
import 'package:smartlife_app/core/network/dio_client.dart';
import 'package:smartlife_app/domain/entities/finance_entry_entity.dart';
import 'package:smartlife_app/domain/entities/finance_stats_entity.dart';

class FinanceService {
  FinanceService(this._dioClient);

  final DioClient _dioClient;

  Future<List<FinanceEntryEntity>> getEntries({String? search, String? category}) async {
    try {
      final response = await _dioClient.instance.get(
        '/api/finance',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty && category != 'Semua') 'category': category,
        },
      );

      final data = List<Map<String, dynamic>>.from((response.data['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map)));
      return data.map(FinanceEntryEntity.fromJson).toList();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<FinanceEntryEntity> create(FinanceEntryEntity entry) async {
    try {
      final response = await _dioClient.instance.post('/api/finance', data: entry.toRequest());
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return FinanceEntryEntity.fromJson(data);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<FinanceEntryEntity> update(String id, FinanceEntryEntity entry) async {
    try {
      final response = await _dioClient.instance.put('/api/finance/$id', data: entry.toRequest());
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
}
