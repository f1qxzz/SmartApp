import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String initialEmail;

  const ResetPasswordScreen({
    super.key,
    required this.initialEmail,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _tokenCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      AppAlert.show(
        context,
        title: 'Password Tidak Cocok',
        message: 'Konfirmasi password harus sama dengan password baru.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    
    await ref.read(authProvider.notifier).resetPassword(
      email: _emailCtrl.text.trim(),
      token: _tokenCtrl.text.trim(),
      newPassword: _newPassCtrl.text,
    );

    if (mounted && ref.read(authProvider).errorMessage == null) {
      // Success is handled by the provider setting a successMessage
      // and redirecting to unauthenticated (Login) state.
      // We manually pop if we are in a Navigator stack.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(isDark),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Reset Password',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn().slideX(begin: -0.1),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan kode OTP 6-digit yang kami kirimkan ke email Anda dan atur password baru.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        
                        const SizedBox(height: 40),
                        
                        // Form Card
                        _buildFormCard(isDark, isLoading),
                        
                        const Spacer(),
                        const SizedBox(height: 24),
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

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
            : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isDark, bool isLoading) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Email Terdaftar', isDark),
                const SizedBox(height: 8),
                InputField(
                  controller: _emailCtrl,
                  hint: 'email@Anda.com',
                  readOnly: true, // Usually we don't change email during reset
                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.primary),
                ),
                
                const SizedBox(height: 20),
                _buildLabel('Kode OTP 6-Digit', isDark),
                const SizedBox(height: 8),
                InputField(
                  controller: _tokenCtrl,
                  hint: '000000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20, color: AppColors.primary),
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Masukkan 6 digit kode' : null,
                ),
                
                const SizedBox(height: 20),
                _buildLabel('Password Baru', isDark),
                const SizedBox(height: 8),
                InputField(
                  controller: _newPassCtrl,
                  hint: 'Minimal 6 karakter',
                  obscureText: _obscurePass,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Password minimal 6 karakter' : null,
                ),
                
                const SizedBox(height: 20),
                _buildLabel('Konfirmasi Password', isDark),
                const SizedBox(height: 8),
                InputField(
                  controller: _confirmPassCtrl,
                  hint: 'Ulangi password baru',
                  obscureText: _obscureConfirm,
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Perbarui Password',
                  onPressed: _submit,
                  isLoading: isLoading,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4B67D1), Color(0xFF6D8DFF)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white60 : AppColors.textSecondary,
      ),
    );
  }
}
