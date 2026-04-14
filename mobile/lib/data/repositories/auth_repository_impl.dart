import 'dart:io';

import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/storage/session_auth_cache.dart';
import 'package:smartlife_app/data/services/auth_service.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._authService);

  final AuthService _authService;

  @override
  Future<(UserEntity user, String token)> login(
      {required String identifier,
      required String password,
      required bool rememberMe}) {
    return _authService.login(
      identifier: identifier,
      password: password,
      rememberMe: rememberMe,
    );
  }

  @override
  Future<(UserEntity user, String token)> register({
    required String username,
    required String email,
    required String password,
    String? gender,
    required bool rememberMe,
  }) {
    return _authService.register(
      username: username,
      email: email,
      password: password,
      gender: gender,
      rememberMe: rememberMe,
    );
  }

  @override
  Future<(UserEntity user, String token)> socialLogin({
    required String provider,
    required String idToken,
    required bool rememberMe,
  }) {
    return _authService.socialLogin(
      provider: provider,
      idToken: idToken,
      rememberMe: rememberMe,
    );
  }

  @override
  Future<void> forgotPassword({required String email}) {
    return _authService.forgotPassword(email: email);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) {
    return _authService.resetPassword(
      email: email,
      token: token,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> cacheAuth(UserEntity user, String token,
      {required bool rememberMe}) async {
    SessionAuthCache.setAuth(token: token, user: user);
    await HiveService.saveRememberMe(rememberMe);
    if (rememberMe) {
      await HiveService.saveToken(token);
      await HiveService.saveUser(user.toJson());
      return;
    }

    await HiveService.clearToken();
    await HiveService.clearUser();
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    if (SessionAuthCache.user != null) {
      return SessionAuthCache.user;
    }

    if (!HiveService.rememberMe) {
      return null;
    }

    final raw = HiveService.user;
    if (raw == null) {
      return null;
    }
    return UserEntity.fromJson(raw);
  }

  @override
  Future<String?> getCachedToken() async {
    if (SessionAuthCache.token != null) {
      return SessionAuthCache.token;
    }
    if (!HiveService.rememberMe) {
      return null;
    }
    return HiveService.token;
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      SessionAuthCache.clear();
      await HiveService.clearAuth();
    }
  }

  @override
  Future<UserEntity> getProfile() {
    return _authService.me();
  }

  @override
  Future<UserEntity> updateProfile({
    required String username,
    required String email,
    String? gender,
    String? avatar,
  }) {
    return _authService.updateProfile(
      username: username,
      email: email,
      gender: gender,
      avatar: avatar,
    );
  }

  @override
  Future<String> uploadAvatar(File file) {
    return _authService.uploadAvatar(file);
  }

  @override
  Future<(UserEntity user, String token)> restoreSession() {
    return _authService.restoreSession();
  }
}
