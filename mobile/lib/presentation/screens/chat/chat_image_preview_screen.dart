import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';

class ChatImagePreviewScreen extends StatefulWidget {
  final XFile image;

  const ChatImagePreviewScreen({super.key, required this.image});

  @override
  State<ChatImagePreviewScreen> createState() => _ChatImagePreviewScreenState();
}

class _ChatImagePreviewScreenState extends State<ChatImagePreviewScreen>
    with TickerProviderStateMixin {
  final TextEditingController _captionCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeIn = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
    ));

    _captionCtrl.addListener(_handleTextChange);
    _enterCtrl.forward();
  }

  void _handleTextChange() {
    final bool typing = _captionCtrl.text.trim().isNotEmpty;
    if (typing != _isTyping) {
      setState(() => _isTyping = typing);
    }
  }

  @override
  void dispose() {
    _captionCtrl.removeListener(_handleTextChange);
    _captionCtrl.dispose();
    _focusNode.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double topPadding = MediaQuery.of(context).padding.top;

    // ── Theme-aware colors ──
    final Color scaffoldBg =
        isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF0F2F8);
    final Color topBarOverlay = isDark
        ? const Color(0xFF0A0E1A).withValues(alpha: 0.80)
        : Colors.white.withValues(alpha: 0.85);
    final Color topBarText = isDark ? Colors.white : AppColors.textPrimary;
    final Color topBarIcon = isDark ? Colors.white : AppColors.textPrimary;
    final Color backBtnBg = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    // Bottom bar
    final Color bottomBarBg = isDark
        ? const Color(0xFF111827).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);
    final Color inputBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF1F3F9);
    final Color inputBgFocused = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE8ECFA);
    final Color inputBorder = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : AppColors.dividerLight;
    final Color inputBorderFocused = isDark
        ? AppColors.primaryLight.withValues(alpha: 0.50)
        : AppColors.primary.withValues(alpha: 0.35);
    final Color captionTextColor =
        isDark ? Colors.white : AppColors.textPrimary;
    final Color hintColor =
        isDark ? Colors.white.withValues(alpha: 0.45) : AppColors.textTertiary;
    final Color cursorColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final Color bottomDivider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            // ══════════════════════════════════════════════
            // 1. TOP BAR — frosted glass, theme-aware
            // ══════════════════════════════════════════════
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: EdgeInsets.only(
                    top: topPadding + 8,
                    left: 8,
                    right: 16,
                    bottom: 14,
                  ),
                  decoration: BoxDecoration(
                    color: topBarOverlay,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Back button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: backBtnBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: topBarIcon,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Preview',
                        style: GoogleFonts.poppins(
                          color: topBarText,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Crop / edit icon placeholder
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () {
                            // Future: crop/edit functionality
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: backBtnBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.crop_rounded,
                              color: topBarIcon.withValues(alpha: 0.70),
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ══════════════════════════════════════════════
            // 2. IMAGE — takes remaining space
            // ══════════════════════════════════════════════
            Expanded(
              child: Container(
                color: scaffoldBg,
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(widget.image.path),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ══════════════════════════════════════════════
            // 3. BOTTOM CAPTION BAR — solid, always visible
            // ══════════════════════════════════════════════
            SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bottomBarBg,
                          border: Border(
                            top: BorderSide(
                              color: bottomDivider,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 14,
                              right: 14,
                              top: 10,
                              bottom: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // ── Caption text field ──
                                Expanded(
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isTyping
                                          ? inputBgFocused
                                          : inputBg,
                                      borderRadius:
                                          BorderRadius.circular(24),
                                      border: Border.all(
                                        color: _isTyping
                                            ? inputBorderFocused
                                            : inputBorder,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _captionCtrl,
                                      focusNode: _focusNode,
                                      maxLines: 4,
                                      minLines: 1,
                                      cursorColor: cursorColor,
                                      cursorWidth: 1.5,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      style: GoogleFonts.inter(
                                        color: captionTextColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Tambah keterangan...',
                                        hintStyle: GoogleFonts.inter(
                                          color: hintColor,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 11),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // ── Send button ──
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    Navigator.pop(
                                      context,
                                      _captionCtrl.text.trim(),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.gradientPrimary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: isDark ? 0.45 : 0.30),
                                          blurRadius: 14,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 21,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
