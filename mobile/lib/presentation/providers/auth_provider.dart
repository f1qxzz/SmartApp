import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/domain/usecases/auth_usecases.dart';
import 'package:smartlife_app/presentation/providers/app_providers.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? token,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._useCases)
      : super(const AuthState(status: AuthStatus.initial)) {
    initialize();
  }

  final AuthUseCases _useCases;

  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final token = await _useCases.getCachedToken();
    final cachedUser = await _useCases.getCachedUser();

    if (token == null || token.isEmpty || cachedUser == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final profile = await _useCases.getProfile();
      await _useCases.cacheAuth(profile, token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: profile,
        token: token,
      );
    } catch (_) {
      await _useCases.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final result = await _useCases.login(email: email, password: password);
      await _useCases.cacheAuth(result.$1, result.$2);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.$1,
        token: result.$2,
      );
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final result = await _useCases.register(name: name, email: email, password: password);
      await _useCases.cacheAuth(result.$1, result.$2);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.$1,
        token: result.$2,
      );
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _useCases.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authUseCasesProvider)),
);
