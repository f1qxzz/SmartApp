import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/domain/repositories/auth_repository.dart';

class AuthUseCases {
  AuthUseCases(this._repository);

  final AuthRepository _repository;

  Future<(UserEntity, String)> login(
      {required String identifier, required String password, required bool rememberMe}) {
    return _repository.login(
      identifier: identifier,
      password: password,
      rememberMe: rememberMe,
    );
  }

  Future<(UserEntity, String)> register(
      {required String username,
      required String email,
      required String password,
      required bool rememberMe}) {
    return _repository.register(
      username: username,
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
  }

  Future<(UserEntity, String)> socialLogin({
    required String provider,
    required String idToken,
    required bool rememberMe,
  }) {
    return _repository.socialLogin(
      provider: provider,
      idToken: idToken,
      rememberMe: rememberMe,
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

  Future<void> cacheAuth(UserEntity user, String token, {required bool rememberMe}) =>
      _repository.cacheAuth(user, token, rememberMe: rememberMe);

  Future<UserEntity?> getCachedUser() => _repository.getCachedUser();

  Future<String?> getCachedToken() => _repository.getCachedToken();

  Future<UserEntity> getProfile() => _repository.getProfile();

  Future<void> logout() => _repository.logout();

  Future<(UserEntity, String)> restoreSession() => _repository.restoreSession();
}
