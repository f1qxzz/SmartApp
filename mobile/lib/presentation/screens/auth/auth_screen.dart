import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:smartlife_app/core/config/env_config.dart';
import 'package:smartlife_app/core/navigation/app_route.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/screens/auth/forgot_password_screen.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthFlowStep { intro, welcome, login, register }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9._]{3,30}$');

  _AuthFlowStep _currentStep = _AuthFlowStep.intro;
  bool _obscureLoginPass = true;
  bool _obscureRegisterPass = true;
  bool _agreeToTerms = false;
  bool _isGoogleLoading = false;
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();
  final TextEditingController _loginIdentifierCtrl = TextEditingController();
  final TextEditingController _loginPassCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _registerEmailCtrl = TextEditingController();
  final TextEditingController _registerPassCtrl = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>['email'],
    serverClientId: EnvConfig.googleWebClientId,
  );
  ProviderSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthState>(
      authProvider,
      (AuthState? previous, AuthState next) {
        _handleAuthFeedback(next);
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _loginIdentifierCtrl.dispose();
    _loginPassCtrl.dispose();
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _registerEmailCtrl.dispose();
    _registerPassCtrl.dispose();
    super.dispose();
  }

  void _handleAuthFeedback(AuthState state) {
    if (!mounted) {
      return;
    }
    final ModalRoute<dynamic>? currentRoute = ModalRoute.of(context);
    if (currentRoute != null && !currentRoute.isCurrent) {
      return;
    }

    final errorMessage = state.errorMessage;
    if (errorMessage != null && errorMessage.isNotEmpty) {
      AppAlert.show(
        context,
        title: 'Ups! Terjadi Kesalahan',
        message: errorMessage,
        isError: true,
      );
      ref.read(authProvider.notifier).clearErrorMessage();
    }

    final successMessage = state.successMessage;
    if (successMessage != null && successMessage.isNotEmpty) {
      AppAlert.show(
        context,
        title: 'Berhasil!',
        message: successMessage,
        isError: false,
      );
      ref.read(authProvider.notifier).clearSuccessMessage();
    }
  }

  void _openStep(_AuthFlowStep step) {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() => _currentStep = step);
  }

  String? _validateIdentifier(String? value) {
    final String identifier = value?.trim().toLowerCase() ?? '';
    if (identifier.isEmpty) {
      return 'Username atau email wajib diisi';
    }

    if (identifier.contains('@')) {
      if (!_emailRegex.hasMatch(identifier)) {
        return 'Format email tidak valid';
      }
      return null;
    }

    if (!_usernameRegex.hasMatch(identifier)) {
      return 'Gunakan username valid 3-30 karakter';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) {
      return 'Email wajib diisi';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) {
      return 'Password wajib diisi';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  String? _validateLoginPassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) {
      return 'Password wajib diisi';
    }
    return null;
  }

  String? _validateFullName(String? value) {
    final String name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    if (name.length < 3) {
      return 'Nama lengkap minimal 3 karakter';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final String username = value?.trim().toLowerCase() ?? '';
    if (username.isEmpty) {
      return 'Username wajib diisi';
    }
    if (!_usernameRegex.hasMatch(username)) {
      return 'Username 3-30 karakter, huruf kecil, angka, titik, atau underscore';
    }
    return null;
  }

  Future<void> _submit() async {
    final AuthState authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (_currentStep == _AuthFlowStep.login) {
      if (!_loginFormKey.currentState!.validate()) {
        return;
      }

      await ref.read(authProvider.notifier).login(
            identifier: _loginIdentifierCtrl.text.trim().toLowerCase(),
            password: _loginPassCtrl.text,
            rememberMe: ref.read(authProvider).rememberMe,
          );
      return;
    }

    if (_currentStep == _AuthFlowStep.register) {
      if (!_registerFormKey.currentState!.validate()) {
        return;
      }

      if (!_agreeToTerms) {
        AppAlert.show(
          context,
          title: 'Konfirmasi Diperlukan',
          message: 'Anda perlu menyetujui syarat penggunaan sebelum daftar.',
          isError: true,
        );
        return;
      }

      await ref.read(authProvider.notifier).register(
            fullName: _fullNameCtrl.text.trim(),
            username: _usernameCtrl.text.trim().toLowerCase(),
            email: _registerEmailCtrl.text.trim().toLowerCase(),
            password: _registerPassCtrl.text,
            rememberMe: ref.read(authProvider).rememberMe,
          );
    }
  }

  void _openForgotPasswordScreen() {
    final AuthState authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading) {
      return;
    }

    final String loginIdentifier = _loginIdentifierCtrl.text.trim();
    final String defaultEmail = loginIdentifier.contains('@')
        ? loginIdentifier
        : _registerEmailCtrl.text.trim();

    Navigator.of(context).push(
      AppRoute<void>(
        builder: (_) => ForgotPasswordScreen(initialEmail: defaultEmail),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final AuthState authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading || _isGoogleLoading) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return;
      }

      final GoogleSignInAuthentication authentication =
          await account.authentication;
      final String idToken = authentication.idToken?.trim() ?? '';

      if (idToken.isEmpty) {
        if (!mounted) {
          return;
        }

        AppAlert.show(
          context,
          title: 'Google Sign-In Gagal',
          message:
              'Token Google tidak ditemukan. Pastikan konfigurasi Google Sign-In sudah benar.',
          isError: true,
        );
        return;
      }

      await ref.read(authProvider.notifier).socialLogin(
            provider: 'google',
            idToken: idToken,
            rememberMe: ref.read(authProvider).rememberMe,
          );
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppAlert.show(
        context,
        title: 'Google Sign-In Gagal',
        message: error.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);
    final bool isLoading = authState.status == AuthStatus.loading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _currentStep == _AuthFlowStep.intro
          ? SystemUiOverlayStyle.light
          : (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark),
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _currentStep == _AuthFlowStep.intro
              ? _AuthIntroScreen(
                  key: const ValueKey<String>('auth-intro'),
                  onSignIn: () => _openStep(_AuthFlowStep.login),
                  onSignUp: () => _openStep(_AuthFlowStep.register),
                )
              : _buildFormLayout(
                  isDark: isDark,
                  isLoading: isLoading,
                  rememberMe: authState.rememberMe,
                ),
        ),
      ),
    );
  }

  Widget _buildFormLayout({
    required bool isDark,
    required bool isLoading,
    required bool rememberMe,
  }) {
    return LayoutBuilder(
      key: ValueKey<String>('auth-form-$_currentStep'),
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 900;

        return Stack(
          children: [
            _AuthFormBackground(isDark: isDark),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 40 : 20,
                        vertical: isWide ? 28 : 18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWide ? 720 : 520,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _buildCurrentFormScreen(
                              isWide: isWide,
                              isLoading: isLoading,
                              rememberMe: rememberMe,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentFormScreen({
    required bool isWide,
    required bool isLoading,
    required bool rememberMe,
    required bool isDark,
  }) {
    switch (_currentStep) {
      case _AuthFlowStep.intro:
        return const SizedBox.shrink();
      case _AuthFlowStep.welcome:
        return _AuthWelcomeScreen(
          key: const ValueKey<String>('auth-welcome'),
          isWide: isWide,
          isDark: isDark,
          onBack: () => _openStep(_AuthFlowStep.intro),
          onOpenLogin: () => _openStep(_AuthFlowStep.login),
          onOpenRegister: () => _openStep(_AuthFlowStep.register),
        );
      case _AuthFlowStep.login:
        return _AuthFormScreen(
          key: const ValueKey<String>('auth-login'),
          isWide: isWide,
          isDark: isDark,
          title: 'Welcome back',
          description:
              'Lanjutkan kembali aktivitas Anda dengan akses cepat ke dashboard, finance planner, chat, dan SmartLife AI.',
          formKey: _loginFormKey,
          onBack: () => _openStep(_AuthFlowStep.intro),
          children: [
            _AuthFieldLabel(label: 'Username atau Email', isDark: isDark),
            const SizedBox(height: 8),
            InputField(
              hint: '@username atau nama@email.com',
              controller: _loginIdentifierCtrl,
              keyboardType: TextInputType.text,
              validator: _validateIdentifier,
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 18),
            _AuthFieldLabel(label: 'Password', isDark: isDark),
            const SizedBox(height: 8),
            InputField(
              hint: 'Masukkan password',
              controller: _loginPassCtrl,
              obscureText: _obscureLoginPass,
              validator: _validateLoginPassword,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscureLoginPass = !_obscureLoginPass);
                },
              ),
            ),
            const SizedBox(height: 18),
            _UtilityRowLogin(
              isDark: isDark,
              rememberMe: rememberMe,
              onRememberChanged: (value) {
                ref.read(authProvider.notifier).setRememberMe(value ?? true);
              },
              onForgotPassword: isLoading ? null : _openForgotPasswordScreen,
            ),
            const SizedBox(height: 22),
            CustomButton(
              text: 'Sign in',
              onPressed: _submit,
              isLoading: isLoading,
              gradient: const LinearGradient(
                colors: [Color(0xFF4B67D1), Color(0xFF6D8DFF)],
              ),
            ),
            const SizedBox(height: 18),
            _AuthDividerText(label: 'atau', isDark: isDark),
            const SizedBox(height: 18),
            _GoogleAuthButton(
              isLoading: _isGoogleLoading,
              onPressed: isLoading ? null : _handleGoogleSignIn,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            _AuthBottomSwitch(
              isDark: isDark,
              prompt: 'Belum punya akun?',
              actionLabel: 'Daftar',
              onTap: () => _openStep(_AuthFlowStep.register),
            ),
          ],
        );
      case _AuthFlowStep.register:
        return _AuthFormScreen(
          key: const ValueKey<String>('auth-register'),
          isWide: isWide,
          isDark: isDark,
          title: 'Get Started',
          description:
              'Buat akun SmartLife untuk mulai mengatur keuangan, percakapan, dan insight harian dalam satu pengalaman yang terasa rapi dan cerdas.',
          formKey: _registerFormKey,
          onBack: () => _openStep(_AuthFlowStep.intro),
          children: [
            _AuthFieldLabel(label: 'Full Name', isDark: isDark),
            const SizedBox(height: 8),
            InputField(
              hint: 'Masukkan nama lengkap',
              controller: _fullNameCtrl,
              validator: _validateFullName,
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 18),
            _AuthFieldLabel(label: 'Username', isDark: isDark),
            const SizedBox(height: 8),
            InputField(
              hint: 'username.smartlife',
              controller: _usernameCtrl,
              validator: _validateUsername,
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 18),
            _AuthFieldLabel(label: 'Email', isDark: isDark),
            const SizedBox(height: 8),
            InputField(
              hint: 'nama@email.com',
              controller: _registerEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 18),
            _AuthFieldLabel(label: 'Password', isDark: isDark),
            const SizedBox(height: 8),
            InputField(
              hint: 'Minimal 6 karakter',
              controller: _registerPassCtrl,
              obscureText: _obscureRegisterPass,
              validator: _validatePassword,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                onPressed: () {
                  setState(
                    () => _obscureRegisterPass = !_obscureRegisterPass,
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            _UtilityRowRegister(
              isDark: isDark,
              agreeToTerms: _agreeToTerms,
              onAgreeChanged: (value) {
                setState(() => _agreeToTerms = value ?? false);
              },
            ),
            const SizedBox(height: 22),
            CustomButton(
              text: 'Sign up',
              onPressed: _submit,
              isLoading: isLoading,
              gradient: const LinearGradient(
                colors: [Color(0xFF4B67D1), Color(0xFF6D8DFF)],
              ),
            ),
            const SizedBox(height: 18),
            _AuthDividerText(label: 'atau', isDark: isDark),
            const SizedBox(height: 18),
            _GoogleAuthButton(
              isLoading: _isGoogleLoading,
              onPressed: isLoading ? null : _handleGoogleSignIn,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            _AuthBottomSwitch(
              isDark: isDark,
              prompt: 'Sudah punya akun?',
              actionLabel: 'Masuk',
              onTap: () => _openStep(_AuthFlowStep.login),
            ),
          ],
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════
// INTRO SCREEN — Full-screen immersive blue gradient + orbs
// ═══════════════════════════════════════════════════════════

class _AuthIntroScreen extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const _AuthIntroScreen({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Dynamic Mesh Background ──
        const _MeshBackground(),

        // ── Subtle Grid Overlay ──
        const _GridOverlay(),

        // ── Floating 3D orbs ──
        const _FloatingOrbs(),

        // ── Content ──
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 28,
              right: 28,
              top: 32,
              bottom: bottomPadding > 0 ? 8 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 3),

                // Logo with Glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF4B67D1).withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: 3.seconds,
                          curve: Curves.easeInOut,
                        ),
                    Image.asset(
                      'assets/images/app_logo_transparent.png',
                      height: 110,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        );
                      },
                    ),
                  ],
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(
                        begin: -5,
                        end: 5,
                        duration: 4.seconds,
                        curve: Curves.easeInOut)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 100.ms)
                    .scale(
                        begin: const Offset(0.7, 0.7),
                        curve: Curves.easeOutBack),

                const SizedBox(height: 32),

                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded,
                          color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'SmartLife',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.95),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 300.ms)
                    .slideX(begin: -0.1),

                const SizedBox(height: 18),

                // Title Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        'WELCOME TO',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 3.0,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 400.ms)
                        .slideX(begin: -0.2),
                    const SizedBox(height: 16),
                    Text(
                      'The Future of',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 500.ms)
                        .slideY(begin: 0.05),
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFF90C2FF),
                          Color(0xFF4B67D1)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'SmartLife',
                        style: GoogleFonts.poppins(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 0.9,
                          letterSpacing: -3.5,
                        ),
                      ),
                    ).animate().fadeIn(duration: 700.ms, delay: 600.ms).scale(
                        begin: const Offset(0.95, 0.95),
                        curve: Curves.easeOutCubic),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'The ultimate superapp experience. Nikmati seamless integration antara personal finance, real-time chat, dan AI-powered insights. Elevate your daily productivity.',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 500.ms)
                    .slideY(begin: 0.06),

                const Spacer(flex: 2),

                // ── Sign in button ──
                CustomButton(
                  text: 'Sign in',
                  onPressed: onSignIn,
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE0E9FF)],
                  ),
                  textColor: const Color(0xFF1A3178),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 850.ms)
                    .slideY(begin: 0.15),

                const SizedBox(height: 14),

                // ── Sign up button ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onSignUp,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              'Create account',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1000.ms)
                    .slideY(begin: 0.15),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FLOATING 3D ORBS — parallax layered bubbles
// ═══════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════
// MESH BACKGROUND — Animated flowing color blobs
// ═══════════════════════════════════════════════════════════

class _MeshBackground extends StatefulWidget {
  const _MeshBackground();

  @override
  State<_MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<_MeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final double t = _ctrl.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Dark base
            Container(color: const Color(0xFF0A0F1E)),

            // Moving Blobs
            _Blob(
              size: 500,
              color: const Color(0xFF1A3178),
              offset: Offset(
                math.sin(t * 2 * math.pi) * 100,
                math.cos(t * 2 * math.pi) * 150 - 50,
              ),
              opacity: 0.6,
            ),
            _Blob(
              size: 400,
              color: const Color(0xFF2B4DB8),
              offset: Offset(
                math.cos(t * 2 * math.pi + 1) * 120 + 100,
                math.sin(t * 2 * math.pi + 1) * 80 + 200,
              ),
              opacity: 0.4,
            ),
            _Blob(
              size: 350,
              color: const Color(0xFF4B67D1),
              offset: Offset(
                math.sin(t * 2 * math.pi + 2) * 150 - 150,
                math.cos(t * 2 * math.pi + 2) * 100 + 400,
              ),
              opacity: 0.35,
            ),
            _Blob(
              size: 450,
              color: const Color(0xFF1E2D50),
              offset: Offset(
                math.cos(t * 2 * math.pi + 3) * 180 + 50,
                math.sin(t * 2 * math.pi + 3) * 120 - 300,
              ),
              opacity: 0.5,
            ),

            // Blur layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  final Offset offset;
  final double opacity;

  const _Blob({
    required this.size,
    required this.color,
    required this.offset,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GRID OVERLAY — Subtle technical pattern
// ═══════════════════════════════════════════════════════════

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(
          color: Colors.white.withValues(alpha: 0.04),
          spacing: 25,
        ),
        child: Container(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingOrbs extends StatefulWidget {
  const _FloatingOrbs();

  @override
  State<_FloatingOrbs> createState() => _FloatingOrbsState();
}

class _FloatingOrbsState extends State<_FloatingOrbs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final double t = _ctrl.value;
        final double slowSin = math.sin(t * 2 * math.pi);
        final double fastSin = math.sin(t * 2 * math.pi + 1.2);
        final double tinySin = math.sin(t * 2 * math.pi + 2.8);

        return Stack(
          children: [
            Positioned(
              top: 40 + slowSin * 12,
              right: -30 + slowSin * 6,
              child: const _GlassOrb(
                  size: 200,
                  gradientColors: [Color(0xFF7A9BFF), Color(0xFF4B67D1)],
                  opacity: 0.5),
            ),
            Positioned(
              top: 160 + fastSin * 16,
              left: 20 + fastSin * 8,
              child: const _GlassOrb(
                  size: 130,
                  gradientColors: [Color(0xFF9DB8FF), Color(0xFF6480E0)],
                  opacity: 0.45),
            ),
            Positioned(
              top: 60 + tinySin * 10,
              left: -20 + tinySin * 5,
              child: const _GlassOrb(
                  size: 80,
                  gradientColors: [Color(0xFFB8CBFF), Color(0xFF8EA7FF)],
                  opacity: 0.40),
            ),
            Positioned(
              top: 300 + slowSin * 8,
              right: 60 + fastSin * 10,
              child: const _GlassOrb(
                  size: 60,
                  gradientColors: [Color(0xFFCBD8FF), Color(0xFF7996F5)],
                  opacity: 0.35),
            ),
            Positioned(
              top: 240 + tinySin * 14,
              right: -10 + tinySin * 6,
              child: const _GlassOrb(
                  size: 100,
                  gradientColors: [Color(0xFF8AA3FF), Color(0xFF5572D4)],
                  opacity: 0.30),
            ),
          ],
        );
      },
    );
  }
}

class _GlassOrb extends StatelessWidget {
  final double size;
  final List<Color> gradientColors;
  final double opacity;

  const _GlassOrb({
    required this.size,
    required this.gradientColors,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              gradientColors.map((c) => c.withValues(alpha: opacity)).toList(),
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.25),
            blurRadius: size * 0.5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.center,
            colors: [
              Colors.white.withValues(alpha: 0.30),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FORM BACKGROUND — Theme-aware (light/dark)
// ═══════════════════════════════════════════════════════════

class _AuthFormBackground extends StatelessWidget {
  final bool isDark;

  const _AuthFormBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF0F172A), Color(0xFF0F172A)]
                  : const [Color(0xFFF4F7FF), Color(0xFFE8EEFF)],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF1A2B5A), Color(0xFF223A74)]
                    : const [Color(0xFF3454B0), Color(0xFF5577E0)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                (isDark ? const Color(0xFF4468CC) : const Color(0xFF7A9BFF))
                    .withValues(alpha: 0.40),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: -30,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                (isDark ? const Color(0xFF3B5CC0) : const Color(0xFF9DB8FF))
                    .withValues(alpha: 0.35),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          top: 50,
          right: 80,
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                (isDark ? const Color(0xFF5B7AE0) : const Color(0xFFB4C8FF))
                    .withValues(alpha: 0.40),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        if (!isDark)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AuthGridPainter(
                  lineColor: const Color(0xFF94A3B8).withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WELCOME SCREEN — Modern premium design
// ═══════════════════════════════════════════════════════════

class _AuthWelcomeScreen extends StatelessWidget {
  final bool isWide;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onOpenLogin;
  final VoidCallback onOpenRegister;

  const _AuthWelcomeScreen({
    super.key,
    required this.isWide,
    required this.isDark,
    required this.onBack,
    required this.onOpenLogin,
    required this.onOpenRegister,
  });

  @override
  Widget build(BuildContext context) {
    final Color subtleBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF4F7FF);
    final Color borderColor =
        isDark ? const Color(0xFF33486F) : const Color(0xFFDCE6FF);
    final Color titleColor =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF223A74);
    final Color descColor =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF6B7FA6);
    final Color featureTextColor =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF4B67D1);

    return _AuthScreenFrame(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Wave emoji badge ──
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF253660), Color(0xFF1E2D50)]
                    : const [Color(0xFFF0F4FF), Color(0xFFDCE6FF)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.waving_hand_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

          const SizedBox(height: 24),

          // ── Title with premium styling ──
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Mulai perjalanan\n',
                  style: GoogleFonts.outfit(
                    fontSize: isWide ? 36 : 30,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5,
                    height: 1.1,
                    color: titleColor,
                  ),
                ),
                TextSpan(
                  text: 'SmartLife ',
                  style: GoogleFonts.poppins(
                    fontSize: isWide ? 40 : 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    height: 1.1,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF4B67D1), Color(0xFF6D8DFF)],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                  ),
                ),
                TextSpan(
                  text: 'Anda.',
                  style: GoogleFonts.outfit(
                    fontSize: isWide ? 36 : 30,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5,
                    height: 1.1,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 250.ms)
              .slideY(begin: 0.06),

          const SizedBox(height: 14),

          // ── Description ──
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 520 : 380),
            child: Text(
              'Kelola keuangan harian, ngobrol dengan tim secara realtime, dan dapatkan insight cerdas dari AI — semuanya dalam satu aplikasi modern yang dirancang untuk hidupmu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.7,
                fontWeight: FontWeight.w500,
                color: descColor,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 400.ms)
              .slideY(begin: 0.04),

          const SizedBox(height: 22),

          // ── Feature pills ──
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeaturePill(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Finance Planner',
                bg: subtleBg,
                border: borderColor,
                textColor: featureTextColor,
              ),
              _FeaturePill(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Realtime Chat',
                bg: subtleBg,
                border: borderColor,
                textColor: featureTextColor,
              ),
              _FeaturePill(
                icon: Icons.auto_awesome_rounded,
                label: 'SmartLife AI',
                bg: subtleBg,
                border: borderColor,
                textColor: featureTextColor,
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 550.ms)
              .slideY(begin: 0.06),

          const SizedBox(height: 32),

          // ── Divider ──
          Row(
            children: [
              Expanded(child: Container(height: 1, color: borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'LANJUTKAN DENGAN',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: descColor.withValues(alpha: 0.58),
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: borderColor)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 650.ms),

          const SizedBox(height: 24),

          // ── Sign in ──
          CustomButton(
            text: 'Masuk ke Akun',
            onPressed: onOpenLogin,
            gradient: const LinearGradient(
              colors: [Color(0xFF4B67D1), Color(0xFF6D8DFF)],
            ),
            icon: Icon(Icons.login_rounded,
                color: Colors.white.withValues(alpha: 0.90), size: 20),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 700.ms)
              .slideY(begin: 0.08),

          const SizedBox(height: 12),

          // ── Sign up ──
          CustomButton(
            text: 'Buat Akun Baru',
            onPressed: onOpenRegister,
            isOutlined: true,
            icon: Icon(Icons.person_add_alt_rounded,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
                size: 20),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 800.ms)
              .slideY(begin: 0.08),

          const SizedBox(height: 18),

          // ── Back ──
          Center(child: _BottomBackArrow(onTap: onBack, isDark: isDark))
              .animate()
              .fadeIn(duration: 400.ms, delay: 900.ms),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color border;
  final Color textColor;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.border,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FORM SCREEN — Login / Register card
// ═══════════════════════════════════════════════════════════

class _AuthFormScreen extends StatelessWidget {
  final bool isWide;
  final bool isDark;
  final String title;
  final String description;
  final GlobalKey<FormState> formKey;
  final VoidCallback onBack;
  final List<Widget> children;

  const _AuthFormScreen({
    super.key,
    required this.isWide,
    required this.isDark,
    required this.title,
    required this.description,
    required this.formKey,
    required this.onBack,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthScreenFrame(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isWide ? 34 : 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF223A74),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.65,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF6B7FA6),
            ),
          ),
          const SizedBox(height: 26),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
          const SizedBox(height: 18),
          Center(child: _BottomBackArrow(onTap: onBack, isDark: isDark)),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.06);
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED WIDGETS — Theme-aware
// ═══════════════════════════════════════════════════════════

class _AuthScreenFrame extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _AuthScreenFrame({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF253660), Color(0xFF1A2B50), Color(0xFF16233F)]
              : const [Color(0xFFFFFFFF), Color(0xFFE8EEFF), Color(0xFFD7E3FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : const Color(0xFF3755A8).withValues(alpha: 0.10),
            blurRadius: 42,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF16233F), Color(0xFF111D35)]
                : const [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _BottomBackArrow extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _BottomBackArrow({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2D50) : const Color(0xFFF9FBFF),
          shape: BoxShape.circle,
          border: Border.all(
              color:
                  isDark ? const Color(0xFF33486F) : const Color(0xFFD8E3FF)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.20)
                  : const Color(0xFF3658AA).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.keyboard_arrow_left_rounded,
          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF31508D),
          size: 22,
        ),
      ),
    );
  }
}

class _AuthDividerText extends StatelessWidget {
  final String label;
  final bool isDark;

  const _AuthDividerText({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color divColor =
        isDark ? const Color(0xFF33486F) : const Color(0xFFDCE6FF);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: divColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textSecondaryDark.withValues(alpha: 0.60)
                  : const Color(0xFF8A9BC1),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: divColor)),
      ],
    );
  }
}

class _GoogleAuthButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isDark;

  const _GoogleAuthButton(
      {required this.isLoading, required this.onPressed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: 'Lanjut dengan Google',
      onPressed: onPressed,
      isLoading: isLoading,
      isOutlined: true,
      icon: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2D50) : const Color(0xFFF3F6FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color:
                  isDark ? const Color(0xFF33486F) : const Color(0xFFDCE6FF)),
        ),
        child: Text(
          'G',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.primaryLight : const Color(0xFF4B67D1),
          ),
        ),
      ),
    );
  }
}

class _UtilityRowLogin extends StatelessWidget {
  final bool rememberMe;
  final bool isDark;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback? onForgotPassword;

  const _UtilityRowLogin(
      {required this.rememberMe,
      required this.isDark,
      required this.onRememberChanged,
      required this.onForgotPassword});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onRememberChanged(!rememberMe),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 0.92,
                    child: Checkbox(
                      value: rememberMe,
                      onChanged: onRememberChanged,
                      activeColor: const Color(0xFF4B67D1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      side: BorderSide(
                          color: isDark
                              ? const Color(0xFF4A5F8F)
                              : const Color(0xFFB6C7EF)),
                    ),
                  ),
                  Flexible(
                    child: Text('Ingat saya',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF6B7FA6))),
                  ),
                ],
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onForgotPassword,
          child: Text('Lupa password?',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.primaryLight
                      : const Color(0xFF4B67D1))),
        ),
      ],
    );
  }
}

class _UtilityRowRegister extends StatelessWidget {
  final bool agreeToTerms;
  final bool isDark;
  final ValueChanged<bool?> onAgreeChanged;

  const _UtilityRowRegister(
      {required this.agreeToTerms,
      required this.isDark,
      required this.onAgreeChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onAgreeChanged(!agreeToTerms),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 0.92,
              child: Checkbox(
                value: agreeToTerms,
                onChanged: onAgreeChanged,
                activeColor: const Color(0xFF4B67D1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                side: BorderSide(
                    color: isDark
                        ? const Color(0xFF4A5F8F)
                        : const Color(0xFFB6C7EF)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF6B7FA6),
                        height: 1.5),
                    children: [
                      const TextSpan(text: 'Saya setuju dengan '),
                      TextSpan(
                          text: 'syarat dan kebijakan SmartLife',
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.primaryLight
                                  : const Color(0xFF4B67D1),
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBottomSwitch extends StatelessWidget {
  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;
  final bool isDark;

  const _AuthBottomSwitch(
      {required this.prompt,
      required this.actionLabel,
      required this.onTap,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(prompt,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.70)
                      : const Color(0xFF7A8EB8))),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(actionLabel,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.primaryLight
                        : const Color(0xFF4B67D1))),
          ),
        ],
      ),
    );
  }
}

class _AuthFieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _AuthFieldLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color:
              isDark ? AppColors.textSecondaryDark : const Color(0xFF31508D)),
    );
  }
}

class _AuthGridPainter extends CustomPainter {
  final Color lineColor;

  _AuthGridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
