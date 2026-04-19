import 'package:smartlife_app/core/network/api_exception.dart';
import 'package:smartlife_app/core/network/dio_client.dart';

class LifeHubService {
  LifeHubService(this._dioClient);

  final DioClient _dioClient;

  // Habits
  Future<List<Map<String, dynamic>>> getHabits() async {
    try {
      final response = await _dioClient.instance.get('/api/lifehub/habits');
      final data = List<Map<String, dynamic>>.from(
        (response.data['data'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );
      return data;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> createHabit(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.instance.post('/api/lifehub/habits', data: data);
      return Map<String, dynamic>.from(response.data['data'] as Map);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateHabit(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.instance.put('/api/lifehub/habits/$id', data: data);
      return Map<String, dynamic>.from(response.data['data'] as Map);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteHabit(String id) async {
    try {
      await _dioClient.instance.delete('/api/lifehub/habits/$id');
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> toggleHabit(String id) async {
    try {
      final response = await _dioClient.instance.patch('/api/lifehub/habits/$id/toggle');
      return Map<String, dynamic>.from(response.data['data'] as Map);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  // Goals
  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final response = await _dioClient.instance.get('/api/lifehub/goals');
      final data = List<Map<String, dynamic>>.from(
        (response.data['data'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );
      return data;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.instance.post('/api/lifehub/goals', data: data);
      return Map<String, dynamic>.from(response.data['data'] as Map);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.instance.put('/api/lifehub/goals/$id', data: data);
      return Map<String, dynamic>.from(response.data['data'] as Map);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _dioClient.instance.delete('/api/lifehub/goals/$id');
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
