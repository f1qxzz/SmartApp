import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:smartlife_app/core/network/api_exception.dart';
import 'package:smartlife_app/core/network/dio_client.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';

class AuthService {
  AuthService(this._dioClient);

  final DioClient _dioClient;

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }

    throw const ApiException('Format response API tidak valid');
  }

  (UserEntity, String) _parseAuthResponse(Response<dynamic> response) {
    final root = _asMap(response.data);
    final payload = root['data'] is Map ? _asMap(root['data']) : root;

    final userRaw = payload['user'] ?? root['user'];
    final tokenRaw = payload['token'] ?? root['token'];

    final userMap = _asMap(userRaw);
    final user = UserEntity.fromJson(userMap);
    final token = (tokenRaw ?? '').toString().trim();

    if (token.isEmpty) {
      throw const ApiException('Token autentikasi tidak ditemukan dari server');
    }

    return (user, token);
  }

  Future<(UserEntity, String)> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AUTH][API] POST /auth/login email=$email');
      final response = await _dioClient.instance.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      return _parseAuthResponse(response);
    } catch (error) {
      debugPrint('[AUTH][API] /auth/login failed: $error');
      throw ApiException.fromDio(error);
    }
  }

  Future<(UserEntity, String)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AUTH][API] POST /auth/register email=$email');
      final response = await _dioClient.instance.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      return _parseAuthResponse(response);
    } catch (error) {
      debugPrint('[AUTH][API] /auth/register failed: $error');
      throw ApiException.fromDio(error);
    }
  }

  Future<(UserEntity, String)> socialLogin({
    required String provider,
    required String idToken,
  }) async {
    try {
      final normalizedProvider = provider.toLowerCase().trim();
      if (normalizedProvider != 'google') {
        throw const ApiException('Provider social login tidak didukung');
      }

      debugPrint('[AUTH][API] POST /auth/google');
      final response = await _dioClient.instance.post(
        '/auth/google',
        data: {'idToken': idToken},
      );

      return _parseAuthResponse(response);
    } catch (error) {
      debugPrint('[AUTH][API] /auth/google failed: $error');
      throw ApiException.fromDio(error);
    }
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      debugPrint('[AUTH][API] POST /auth/forgot-password email=$email');
      await _dioClient.instance.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } catch (error) {
      debugPrint('[AUTH][API] /auth/forgot-password failed: $error');
      throw ApiException.fromDio(error);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      debugPrint('[AUTH][API] POST /auth/reset-password email=$email');
      await _dioClient.instance.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'newPassword': newPassword,
        },
      );
    } catch (error) {
      debugPrint('[AUTH][API] /auth/reset-password failed: $error');
      throw ApiException.fromDio(error);
    }
  }

  Future<UserEntity> me() async {
    try {
      final response = await _dioClient.instance.get('/auth/me');
      final root = _asMap(response.data);
      final payload = root['data'] is Map ? _asMap(root['data']) : root;
      final userRaw = payload['user'] ?? root['user'];
      return UserEntity.fromJson(_asMap(userRaw));
    } on DioException catch (error) {
      debugPrint('[AUTH][API] /auth/me failed: $error');
      throw ApiException.fromDio(error);
    }
  }
}
