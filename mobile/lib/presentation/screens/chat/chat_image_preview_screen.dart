import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ChatImagePreviewScreen extends StatefulWidget {
  final XFile image;

  const ChatImagePreviewScreen({super.key, required this.image});

  @override
  State<ChatImagePreviewScreen> createState() => _ChatImagePreviewScreenState();
}

class _ChatImagePreviewScreenState extends State<ChatImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _captionCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _inputSlide;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _inputSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -4),
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    ));

    _captionCtrl.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final bool typing = _captionCtrl.text.trim().isNotEmpty;
    if (typing != _isTyping) {
      setState(() => _isTyping = typing);
      if (typing) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _captionCtrl.removeListener(_handleTextChange);
    _captionCtrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Full-screen image ──
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.0,
              child: Image.file(
                File(widget.image.path),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // ── 2. Top bar (back button) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Preview',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      shadows: const <Shadow>[
                        Shadow(
                          color: Color(0x99000000),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Bottom gradient overlay (WAJIB — always visible) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200 + keyboardHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.45, 0.85, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Caption input bar ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: keyboardHeight > 0
                ? keyboardHeight + 4
                : bottomPadding + 12,
            child: AnimatedBuilder(
              animation: _inputSlide,
              builder: (context, child) => Transform.translate(
                offset: _inputSlide.value,
                child: child,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ─ Text input field ─
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _isTyping
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: _isTyping ? 0.28 : 0.18,
                                ),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _captionCtrl,
                              focusNode: _focusNode,
                              maxLines: 4,
                              minLines: 1,
                              cursorColor: Colors.white,
                              cursorWidth: 1.5,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                shadows: const <Shadow>[
                                  Shadow(
                                    color: Color(0xE6000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              decoration: InputDecoration(
                                hintText: 'Tambah keterangan...',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  shadows: const <Shadow>[
                                    Shadow(
                                      color: Color(0x99000000),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ─ Send button ─
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, _captionCtrl.text.trim());
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8C90A8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
