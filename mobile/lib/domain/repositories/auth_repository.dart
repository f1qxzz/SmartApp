import 'package:smartlife_app/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<(UserEntity user, String token)> login({required String email, required String password});
  Future<(UserEntity user, String token)> register({required String name, required String email, required String password});
  Future<UserEntity?> getCachedUser();
  Future<String?> getCachedToken();
  Future<void> cacheAuth(UserEntity user, String token);
  Future<void> logout();
  Future<UserEntity> getProfile();
}
