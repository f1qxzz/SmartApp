import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/data/services/auth_service.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._authService);

  final AuthService _authService;

  @override
  Future<(UserEntity user, String token)> login({required String email, required String password}) {
    return _authService.login(email: email, password: password);
  }

  @override
  Future<(UserEntity user, String token)> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _authService.register(name: name, email: email, password: password);
  }

  @override
  Future<void> cacheAuth(UserEntity user, String token) async {
    await HiveService.saveToken(token);
    await HiveService.saveUser(user.toJson());
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final raw = HiveService.user;
    if (raw == null) {
      return null;
    }
    return UserEntity.fromJson(raw);
  }

  @override
  Future<String?> getCachedToken() async {
    return HiveService.token;
  }

  @override
  Future<void> logout() {
    return HiveService.clearAuth();
  }

  @override
  Future<UserEntity> getProfile() {
    return _authService.me();
  }
}
