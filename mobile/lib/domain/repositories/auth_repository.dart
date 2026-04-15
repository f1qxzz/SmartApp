import 'dart:io';

import 'package:smartlife_app/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<(UserEntity user, String token)> login(
      {required String identifier,
      required String password,
      required bool rememberMe});
  Future<(UserEntity user, String token)> register(
      {required String username,
      required String email,
      required String password,
      String? gender,
      required bool rememberMe});
  Future<(UserEntity user, String token)> socialLogin({
    required String provider,
    required String idToken,
    required bool rememberMe,
  });
  Future<void> forgotPassword({required String email});
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });
  Future<UserEntity?> getCachedUser();
  Future<String?> getCachedToken();
  Future<void> cacheAuth(UserEntity user, String token,
      {required bool rememberMe});
  Future<void> logout();
  Future<UserEntity> getProfile();
  Future<UserEntity> updateProfile({
    required String username,
    required String email,
    String? name,
    String? gender,
    String? avatar,
    double? monthlyBudget,
  });
  Future<String> uploadAvatar(File file);
  Future<(UserEntity user, String token)> restoreSession();
}
