import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:smartlife_app/core/storage/hive_service.dart';
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
  final String? successMessage;
  final bool rememberMe;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
    this.successMessage,
    this.rememberMe = true,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? token,
    String? errorMessage,
    String? successMessage,
    bool? rememberMe,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._useCases)
      : super(
          AuthState(
            status: AuthStatus.initial,
            rememberMe: HiveService.rememberMe,
          ),
        ) {
    initialize();
  }

  final AuthUseCases _useCases;
  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9._]{3,30}$');

  void _setClientError(String message) {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: message,
    );
  }

  Future<void> initialize() async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearSuccess: true,
    );

    final token = await _useCases.getCachedToken();
    final cachedUser = await _useCases.getCachedUser();

    if (token == null || token.isEmpty || cachedUser == null) {
      try {
        final restored = await _useCases.restoreSession();
        final bool rememberMe = state.rememberMe;
        await _useCases.cacheAuth(
          restored.$1,
          restored.$2,
          rememberMe: rememberMe,
        );
        state = AuthState(
          status: AuthStatus.authenticated,
          user: restored.$1,
          token: restored.$2,
          rememberMe: rememberMe,
        );
        return;
      } catch (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
    }

    try {
      final profile = await _useCases.getProfile();
      await _useCases.cacheAuth(
        profile,
        token,
        rememberMe: state.rememberMe,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: profile,
        token: token,
        rememberMe: state.rememberMe,
      );
    } catch (_) {
      await _useCases.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(
      {required String identifier,
      required String password,
      required bool rememberMe}) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearSuccess: true,
    );

    final normalizedIdentifier = identifier.trim().toLowerCase();
    if (normalizedIdentifier.isEmpty || password.isEmpty) {
      _setClientError('Username/email dan password wajib diisi.');
      return;
    }

    if (normalizedIdentifier.length < 3) {
      _setClientError('Username/email minimal 3 karakter.');
      return;
    }

    if (password.length < 6) {
      _setClientError('Password minimal 6 karakter.');
      return;
    }

    try {
      final result = await _useCases.login(
        identifier: normalizedIdentifier,
        password: password,
        rememberMe: rememberMe,
      );
      await _useCases.cacheAuth(result.$1, result.$2, rememberMe: rememberMe);
      debugPrint('[AUTH] login success: ${result.$1.email}');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.$1,
        token: result.$2,
        successMessage: 'Login berhasil. Selamat datang kembali!',
        rememberMe: rememberMe,
      );
    } catch (error) {
      debugPrint('[AUTH] login failed: $error');
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearSuccess: true,
    );

    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim();

    if (normalizedUsername.isEmpty ||
        normalizedEmail.isEmpty ||
        password.isEmpty) {
      _setClientError('Username, email, dan password wajib diisi.');
      return;
    }

    if (!_usernameRegex.hasMatch(normalizedUsername)) {
      _setClientError(
        'Username harus 3-30 karakter (huruf kecil, angka, titik, underscore).',
      );
      return;
    }

    if (!_emailRegex.hasMatch(normalizedEmail)) {
      _setClientError('Format email tidak valid.');
      return;
    }

    if (password.length < 6) {
      _setClientError('Password minimal 6 karakter.');
      return;
    }

    try {
      final result = await _useCases.register(
        username: normalizedUsername,
        email: normalizedEmail,
        password: password,
        rememberMe: rememberMe,
      );
      await _useCases.cacheAuth(result.$1, result.$2, rememberMe: rememberMe);
      debugPrint('[AUTH] register success: ${result.$1.email}');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.$1,
        token: result.$2,
        successMessage: 'Register berhasil. Selamat datang di SmartLife!',
        rememberMe: rememberMe,
      );
    } catch (error) {
      debugPrint('[AUTH] register failed: $error');
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> socialLogin({
    required String provider,
    required String idToken,
    required bool rememberMe,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearSuccess: true,
    );

    final normalizedProvider = provider.trim().toLowerCase();
    if (normalizedProvider.isEmpty || idToken.trim().isEmpty) {
      _setClientError('Google Sign-In gagal: token tidak ditemukan.');
      return;
    }

    try {
      final result = await _useCases.socialLogin(
        provider: normalizedProvider,
        idToken: idToken,
        rememberMe: rememberMe,
      );
      await _useCases.cacheAuth(result.$1, result.$2, rememberMe: rememberMe);
      debugPrint('[AUTH] social login success: ${result.$1.email}');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.$1,
        token: result.$2,
        successMessage: 'Berhasil masuk dengan Google.',
        rememberMe: rememberMe,
      );
    } catch (error) {
      debugPrint('[AUTH] social login failed: $error');
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearSuccess: true,
    );

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      _setClientError('Email wajib diisi.');
      return;
    }

    if (!_emailRegex.hasMatch(normalizedEmail)) {
      _setClientError('Format email tidak valid.');
      return;
    }

    try {
      await _useCases.forgotPassword(email: normalizedEmail);
      debugPrint('[AUTH] forgot-password success: $normalizedEmail');
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        successMessage:
            'Jika email terdaftar, link reset password sudah dikirim.',
      );
    } catch (error) {
      debugPrint('[AUTH] forgot-password failed: $error');
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

  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  void clearSuccessMessage() {
    state = state.copyWith(clearSuccess: true);
  }

  void clearErrorMessage() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authUseCasesProvider)),
);
