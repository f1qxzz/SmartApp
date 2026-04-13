import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/config/env_config.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  bool _isLogin = true;
  bool _obscurePass = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ProviderSubscription<AuthState>? _authSubscription;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
    serverClientId: EnvConfig.googleWebClientId,
  );

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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _handleAuthFeedback(AuthState state) {
    if (!mounted) {
      return;
    }

    final errorMessage = state.errorMessage;
    if (errorMessage != null && errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      ref.read(authProvider.notifier).clearErrorMessage();
      return;
    }

    final successMessage = state.successMessage;
    if (successMessage != null &&
        successMessage.isNotEmpty &&
        state.status == AuthStatus.unauthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      ref.read(authProvider.notifier).clearSuccessMessage();
    }
  }

  void _submit() async {
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading ||
        !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (_isLogin) {
      await ref.read(authProvider.notifier).login(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
      return;
    }

    await ref.read(authProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
  }

  Future<void> _continueWithGoogle() async {
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final googleWebClientId = EnvConfig.googleWebClientId;
    if (googleWebClientId == null || googleWebClientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'GOOGLE_WEB_CLIENT_ID belum diisi. Cek .env mobile & Firebase OAuth setup.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      debugPrint('[AUTH][GOOGLE] start sign-in flow');
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('[AUTH][GOOGLE] user cancelled sign-in');
        return;
      }
      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Google Sign-In gagal mendapatkan token. Pastikan SHA-1 & OAuth Client ID sudah benar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      debugPrint('[AUTH][GOOGLE] idToken received, sending to backend');
      await ref.read(authProvider.notifier).socialLogin(
            provider: 'google',
            idToken: idToken,
          );
    } catch (error) {
      debugPrint('[AUTH][GOOGLE] sign-in failed: $error');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In gagal: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading) {
      return;
    }

    final emailController = TextEditingController(
      text: _emailCtrl.text.trim(),
    );
    final formKey = GlobalKey<FormState>();

    final String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Lupa Password',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Masukkan email akun kamu',
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Email wajib diisi';
                }
                if (!_emailRegex.hasMatch(email)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(emailController.text.trim());
              },
              child: const Text('Kirim Link Reset'),
            ),
          ],
        );
      },
    );

    emailController.dispose();

    if (result == null) {
      return;
    }

    await ref.read(authProvider.notifier).forgotPassword(
          email: result,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3A45D4),
                  Color(0xFF5B67F1),
                  Color(0xFF8B5CF6)
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Background pattern
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo + title
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scaleXY(begin: 0.8, curve: Curves.easeOut),
                      const SizedBox(height: 16),
                      Text(
                        'SmartLife',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 400.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 6),
                      Text(
                        'Kelola keuangan & komunikasi\ndalam satu aplikasi premium',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.75),
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Form card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.cardDark
                          : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tab toggle
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _TabButton(
                                  label: 'Masuk',
                                  isActive: _isLogin,
                                  onTap: () => setState(() => _isLogin = true),
                                ),
                                _TabButton(
                                  label: 'Daftar',
                                  isActive: !_isLogin,
                                  onTap: () => setState(() => _isLogin = false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            _isLogin
                                ? 'Selamat datang kembali!'
                                : 'Buat akun baru',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLogin
                                ? 'Masuk ke akun SmartLife kamu'
                                : 'Mulai perjalanan finansialmu',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_isLogin) ...[
                            InputField(
                              hint: 'Nama lengkap',
                              controller: _nameCtrl,
                              validator: (String? value) {
                                final String name = value?.trim() ?? '';
                                if (name.isEmpty) {
                                  return 'Nama wajib diisi';
                                }
                                if (name.length < 3) {
                                  return 'Nama minimal 3 karakter';
                                }
                                return null;
                              },
                              prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.primary,
                                  size: 20),
                            ),
                            const SizedBox(height: 14),
                          ],
                          InputField(
                            hint: 'Email address',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (String? value) {
                              final String email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Email wajib diisi';
                              }
                              if (!_emailRegex.hasMatch(email)) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(height: 14),
                          InputField(
                            hint: 'Password',
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            validator: (String? value) {
                              final String password = value ?? '';
                              if (password.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (password.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppColors.primary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          if (_isLogin) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : _showForgotPasswordDialog,
                                child: Text(
                                  'Lupa password?',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ] else
                            const SizedBox(height: 16),
                          CustomButton(
                            text: _isLogin ? 'Masuk' : 'Buat Akun',
                            onPressed: _submit,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: 20),
                          // Social login divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: AppColors.dividerLight),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'atau lanjut dengan',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: AppColors.dividerLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _SocialButton(
                                  label: 'Google',
                                  icon: Icons.g_mobiledata_rounded,
                                  color: const Color(0xFFEA4335),
                                  onTap: isLoading ? null : _continueWithGoogle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.gradientPrimary : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.dividerLight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
