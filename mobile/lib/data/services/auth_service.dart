import 'package:dio/dio.dart';

import 'package:smartlife_app/core/network/api_exception.dart';
import 'package:smartlife_app/core/network/dio_client.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';

class AuthService {
  AuthService(this._dioClient);

  final DioClient _dioClient;

  Future<(UserEntity, String)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final user = UserEntity.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      final token = (data['token'] ?? '').toString();
      return (user, token);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<(UserEntity, String)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        '/api/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final user = UserEntity.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      final token = (data['token'] ?? '').toString();
      return (user, token);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserEntity> me() async {
    try {
      final response = await _dioClient.instance.get('/api/auth/me');
      final data = Map<String, dynamic>.from(response.data as Map);
      return UserEntity.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
