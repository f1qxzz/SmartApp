import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:smartlife_app/core/config/env_config.dart';
import 'package:smartlife_app/core/network/api_exception.dart';
import 'package:smartlife_app/core/network/dio_client.dart';
import 'package:smartlife_app/core/utils/url_helper.dart';
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
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      debugPrint('[AUTH][API] POST /auth/login identifier=$identifier');
      final response = await _dioClient.instance.post(
        '/auth/login',
        data: {
          'identifier': identifier,
          'password': password,
          'rememberMe': rememberMe,
        },
      );

      return _parseAuthResponse(response);
    } catch (error) {
      debugPrint('[AUTH][API] /auth/login failed: $error');
      throw ApiException.fromDio(error);
    }
  }

  Future<(UserEntity, String)> register({
    required String username,
    required String name,
    required String email,
    required String password,
    String? gender,
    DateTime? dateOfBirth,
    required bool rememberMe,
  }) async {
    try {
      debugPrint('[AUTH][API] POST /auth/register email=$email');
      final response = await _dioClient.instance.post(
        '/auth/register',
        data: {
          'username': username,
          'name': name,
          'email': email,
          'password': password,
          if (gender != null && gender.trim().isNotEmpty) 'gender': gender,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
          'rememberMe': rememberMe,
        },
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
    required bool rememberMe,
  }) async {
    try {
      final normalizedProvider = provider.toLowerCase().trim();
      if (normalizedProvider != 'google') {
        throw const ApiException('Provider social login tidak didukung');
      }

      debugPrint('[AUTH][API] POST /auth/google');
      final response = await _dioClient.instance.post(
        '/auth/google',
        data: {
          'idToken': idToken,
          'rememberMe': rememberMe,
        },
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

  Future<UserEntity> updateProfile({
    required String username,
    required String email,
    String? name,
    String? gender,
    String? avatar,
    String? role,
    double? monthlyBudget,
    DateTime? dateOfBirth,
    String? socialGithub,
    String? socialInstagram,
    String? socialDiscord,
    String? socialTelegram,
    String? socialSpotify,
  }) async {
    try {
      final response = await _dioClient.instance.put(
        '/auth/profile',
        data: {
          'username': username,
          'email': email,
          if (name != null) 'name': name,
          if (gender != null) 'gender': gender,
          if (avatar != null) 'avatar': avatar,
          if (role != null) 'role': role,
          if (monthlyBudget != null) 'monthlyBudget': monthlyBudget,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
          if (socialGithub != null) 'socialGithub': socialGithub,
          if (socialInstagram != null) 'socialInstagram': socialInstagram,
          if (socialDiscord != null) 'socialDiscord': socialDiscord,
          if (socialTelegram != null) 'socialTelegram': socialTelegram,
          if (socialSpotify != null) 'socialSpotify': socialSpotify,
        },
      );

      final root = _asMap(response.data);
      final payload = root['data'] is Map ? _asMap(root['data']) : root;
      final userRaw = payload['user'] ?? payload;

      return UserEntity.fromJson(_asMap(userRaw));
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }
      debugPrint('[AUTH][API] /auth/profile failed: $error');
      throw ApiException.fromDio(error);
    }
  }

  Future<String> uploadAvatar(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response =
          await _dioClient.instance.post('/api/upload', data: formData);
      final root = _asMap(response.data);
      final payload = root['data'] is Map ? _asMap(root['data']) : root;
      final url = (payload['url'] ?? '').toString();

      if (url.isEmpty) {
        throw const ApiException('URL avatar tidak ditemukan dari server');
      }

      return UrlHelper.toAbsolute(EnvConfig.apiBaseUrl, url);
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }
      debugPrint('[AUTH][API] /api/upload failed: $error');
      throw ApiException.fromDio(error);
    }
  }

  Future<(UserEntity, String)> restoreSession() async {
    try {
      final response = await _dioClient.instance.get('/auth/me');
      return _parseAuthResponse(response);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserEntity> getPublicProfile(String userId) async {
    try {
      debugPrint('[AUTH][API] GET /auth/users/$userId');
      final response = await _dioClient.instance.get('/auth/users/$userId');
      final root = _asMap(response.data);
      final payload = root['data'] is Map ? _asMap(root['data']) : root;
      final userRaw = payload['user'] ?? root['user'] ?? payload;
      return UserEntity.fromJson(_asMap(userRaw));
    } on DioException catch (error) {
      debugPrint('[AUTH][API] /auth/users/$userId failed: $error');
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dioClient.instance.post('/auth/logout');
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
