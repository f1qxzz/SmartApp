import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/navigation/app_route.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/screens/auth/reset_password_screen.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    final String email = _emailCtrl.text.trim().toLowerCase();

    await ref.read(authProvider.notifier).forgotPassword(email: email);
    final AuthState nextState = ref.read(authProvider);

    if (!mounted) {
      return;
    }

    final String? errorMessage = nextState.errorMessage;
    if (errorMessage != null && errorMessage.isNotEmpty) {
      await AppAlert.show(
        context,
        title: 'Gagal Mengirim Kode',
        message: errorMessage,
        isError: true,
      );
      ref.read(authProvider.notifier).clearErrorMessage();
      return;
    }

    ref.read(authProvider.notifier).clearSuccessMessage();
    await AppAlert.show(
      context,
      title: 'Kode Reset Terkirim',
      message:
          'Kami sudah mengirim kode 6 digit ke email kamu. Lanjutkan ke halaman reset password.',
      isError: false,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      AppRoute<void>(
        builder: (_) => ResetPasswordScreen(initialEmail: email),
      ),
    );
  }

  void _openResetPage() {
    final String email = _emailCtrl.text.trim();
    Navigator.of(context).push(
      AppRoute<void>(
        builder: (_) => ResetPasswordScreen(initialEmail: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);
    final bool isLoading = authState.status == AuthStatus.loading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          FluidBackground(
            isDark: isDark,
            orbColors: const <Color>[
              Color(0xFF4B67D1),
              Color(0xFF6D8DFF),
              Color(0xFF22D3EE),
            ],
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: false,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Lupa Password',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ).animate().fadeIn().slideX(begin: -0.08),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan email akun kamu untuk menerima kode reset password melalui email.',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                          ),
                        ).animate().fadeIn(delay: 120.ms),
                        const SizedBox(height: 24),
                        _StepChips(isDark: isDark),
                        const SizedBox(height: 24),
                        ModernGlassCard(
                          isDark: isDark,
                          padding: const EdgeInsets.all(22),
                          borderRadius: 26,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Email Terdaftar',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF31508D),
                                  ),
                                ),
                                const SizedBox(height: 9),
                                InputField(
                                  hint: 'nama@email.com',
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(
                                      alpha: isDark ? 0.14 : 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.info.withValues(
                                        alpha: isDark ? 0.28 : 0.22,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.mark_email_read_outlined,
                                        size: 18,
                                        color: AppColors.info,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Cek folder Inbox/Spam setelah mengirim kode.',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            height: 1.35,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),
                                CustomButton(
                                  text: 'Kirim Kode Reset',
                                  onPressed: isLoading ? null : _submit,
                                  isLoading: isLoading,
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      Color(0xFF4B67D1),
                                      Color(0xFF6D8DFF),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.05),
                        const Spacer(),
                        Center(
                          child: TextButton(
                            onPressed: isLoading ? null : _openResetPage,
                            child: Text(
                              'Sudah punya kode? Masukkan kode reset',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : const Color(0xFF4B67D1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepChips extends StatelessWidget {
  final bool isDark;

  const _StepChips({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _stepChip(
          icon: Icons.looks_one_rounded,
          label: 'Kirim kode email',
          active: true,
        ),
        _stepChip(
          icon: Icons.looks_two_rounded,
          label: 'Masukkan kode & reset',
          active: false,
        ),
      ],
    );
  }

  Widget _stepChip({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    final Color accent = active ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.72)),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? accent.withValues(alpha: 0.32)
              : Colors.white.withValues(alpha: isDark ? 0.12 : 0.85),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon,
              size: 14, color: active ? accent : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active
                  ? (isDark ? Colors.white : const Color(0xFF334155))
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}
