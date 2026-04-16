import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9._]{3,30}$');

  bool _isLogin = true;
  bool _obscurePass = true;
  String _selectedGender = '';
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  DateTime? _selectedDOB;
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
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  void _handleAuthFeedback(AuthState state) {
    if (!mounted) {
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
      return;
    }

    final successMessage = state.successMessage;
    if (successMessage != null && successMessage.isNotEmpty) {
      AppAlert.show(
        context,
        title: state.status == AuthStatus.authenticated
            ? 'Selamat Datang!'
            : 'Berhasil!',
        message: successMessage,
        isError: false,
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
            identifier: _usernameCtrl.text.trim().toLowerCase(),
            password: _passCtrl.text,
            rememberMe: ref.read(authProvider).rememberMe,
          );
      return;
    }

    await ref.read(authProvider.notifier).register(
          username: _usernameCtrl.text.trim().toLowerCase(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          gender: _selectedGender,
          dateOfBirth: _selectedDOB,
          rememberMe: ref.read(authProvider).rememberMe,
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
      AppAlert.show(
        context,
        title: 'Konfigurasi Belum Siap',
        message: 'GOOGLE_WEB_CLIENT_ID belum diisi. Silakan cek file .env Anda.',
        isError: true,
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
        AppAlert.show(
          context,
          title: 'Gagal Mendapatkan Token',
          message: 'Google Sign-In gagal mendapatkan idToken. Periksa SHA-1 di Firebase Console.',
          isError: true,
        );
        return;
      }

      debugPrint('[AUTH][GOOGLE] idToken received, sending to backend');
      await ref.read(authProvider.notifier).socialLogin(
            provider: 'google',
            idToken: idToken,
            rememberMe: ref.read(authProvider).rememberMe,
          );
    } on PlatformException catch (error) {
      debugPrint('[AUTH][GOOGLE] sign-in failed: $error');
      if (!mounted) {
        return;
      }

      String message = 'Google Sign-In gagal (${error.code}).';
      if (error.code == 'sign_in_failed') {
        message = 'Google Sign-In gagal. Periksa kembali SHA-1/SHA-256 dan file google-services.json terbaru.';
      } else if (error.code == 'network_error') {
        message = 'Koneksi internet bermasalah. Silakan coba lagi nanti.';
      }

      AppAlert.show(
        context,
        title: 'Koneksi Google Bermasalah',
        message: message,
        isError: true,
      );
    } catch (error) {
      debugPrint('[AUTH][GOOGLE] sign-in failed: $error');
      if (!mounted) {
        return;
      }

      AppAlert.show(
        context,
        title: 'Sign-In Error',
        message: 'Terjadi kesalahan saat masuk dengan Google: $error',
        isError: true,
      );
    }
  }

  Future<void> _selectDOB() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDOB) {
      setState(() {
        _selectedDOB = picked;
        _dobCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
      });
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
    final rememberMe = authState.rememberMe;

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
                  Color(0xFF4C5372),
                  Color(0xFF7C7E9D),
                  Color(0xFF949AB1)
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
                color: Colors.white.withValues(alpha: 0.06),
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
                color: Colors.white.withValues(alpha: 0.05),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
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
                          color: Colors.white.withValues(alpha: 0.75),
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
                          color: Colors.black.withValues(alpha: 0.2),
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
                          InputField(
                            hint: _isLogin ? 'Username atau Email' : 'Username',
                            controller: _usernameCtrl,
                            keyboardType: _isLogin
                                ? TextInputType.emailAddress
                                : TextInputType.text,
                            validator: (String? value) {
                              final String input =
                                  value?.trim().toLowerCase() ?? '';
                              if (input.isEmpty) {
                                return _isLogin
                                    ? 'Username atau email wajib diisi'
                                    : 'Username wajib diisi';
                              }
                              if (input.length < 3) {
                                return _isLogin
                                    ? 'Minimal 3 karakter'
                                    : 'Username minimal 3 karakter';
                              }
                              if (!_isLogin &&
                                  !_usernameRegex.hasMatch(input)) {
                                return 'Username 3-30 karakter (a-z, 0-9, . _)';
                              }
                              return null;
                            },
                            prefixIcon: Icon(
                                _isLogin
                                    ? Icons.person_outline_rounded
                                    : Icons.alternate_email_rounded,
                                color: AppColors.primary,
                                size: 20),
                          ),
                          const SizedBox(height: 14),
                          if (!_isLogin) ...[
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
                            DropdownButtonFormField<String>(
                              initialValue: _selectedGender.isEmpty
                                  ? null
                                  : _selectedGender,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Pilih Gender',
                                prefixIcon: const Icon(
                                  Icons.wc_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon:
                                  const Icon(Icons.keyboard_arrow_down_rounded),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem<String>(
                                  value: 'male',
                                  child: Text('Laki-laki'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'female',
                                  child: Text('Perempuan'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'other',
                                  child: Text('Lainnya'),
                                ),
                              ],
                              onChanged: (String? value) {
                                setState(() => _selectedGender = value ?? '');
                              },
                              validator: (String? value) {
                                if (_isLogin) {
                                  return null;
                                }
                                if (value == null || value.trim().isEmpty) {
                                  return 'Gender wajib dipilih';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: _selectDOB,
                              child: AbsorbPointer(
                                child: InputField(
                                  hint: 'Tanggal Lahir',
                                  controller: _dobCtrl,
                                  prefixIcon: const Icon(
                                    Icons.cake_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  validator: (value) {
                                    if (_isLogin) return null;
                                    if (_selectedDOB == null) {
                                      return 'Tanggal lahir wajib diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
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
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) {
                                  ref
                                      .read(authProvider.notifier)
                                      .setRememberMe(value ?? true);
                                },
                              ),
                              Expanded(
                                child: Text(
                                  'Remember me',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
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
                              const Expanded(
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
                              const Expanded(
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
                      color: AppColors.primary.withValues(alpha: 0.3),
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
