import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/domain/repositories/auth_repository.dart';

class AuthUseCases {
  AuthUseCases(this._repository);

  final AuthRepository _repository;

  Future<(UserEntity, String)> login(
      {required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }

  Future<(UserEntity, String)> register(
      {required String name, required String email, required String password}) {
    return _repository.register(name: name, email: email, password: password);
  }

  Future<(UserEntity, String)> socialLogin({
    required String provider,
    required String idToken,
  }) {
    return _repository.socialLogin(
      provider: provider,
      idToken: idToken,
    );
  }

  Future<void> forgotPassword({required String email}) {
    return _repository.forgotPassword(email: email);
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) {
    return _repository.resetPassword(
      email: email,
      token: token,
      newPassword: newPassword,
    );
  }

  Future<void> cacheAuth(UserEntity user, String token) =>
      _repository.cacheAuth(user, token);

  Future<UserEntity?> getCachedUser() => _repository.getCachedUser();

  Future<String?> getCachedToken() => _repository.getCachedToken();

  Future<UserEntity> getProfile() => _repository.getProfile();

  Future<void> logout() => _repository.logout();
}
