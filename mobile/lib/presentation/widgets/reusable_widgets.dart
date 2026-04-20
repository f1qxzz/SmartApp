import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smartlife_app/core/navigation/app_route.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final double? width;
  final Gradient? gradient;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.gradient,
    this.textColor,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isEnabled ? (_) => _controller.forward() : null,
      onTapUp: _isEnabled
          ? (_) {
              _controller.reverse();
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: _isEnabled ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, Widget? child) => Transform.scale(
          scale: _isEnabled ? _scaleAnim.value : 1,
          child: child,
        ),
        child: Opacity(
          opacity: _isEnabled ? 1 : 0.65,
          child: Container(
            width: widget.width ?? double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: widget.isOutlined
                  ? null
                  : (widget.gradient ?? AppColors.gradientPrimary),
              color: widget.isOutlined
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceElevatedDark
                      : Colors.white)
                  : null,
              borderRadius: BorderRadius.circular(18),
              border: widget.isOutlined
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    )
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isOutlined
                          ? AppColors.primary
                          : AppColors.primary)
                      .withValues(alpha: widget.isOutlined ? 0.04 : 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: <Widget>[
                  if (!widget.isOutlined)
                    Positioned(
                      top: -40,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.isOutlined
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              if (widget.icon != null) ...<Widget>[
                                widget.icon!,
                                const SizedBox(width: 10),
                              ],
                              Text(
                                widget.text,
                                style: AppTextStyles.button.copyWith(
                                  color: widget.textColor ??
                                      (widget.isOutlined
                                          ? AppColors.primary
                                          : Colors.white),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InputField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;

  const InputField({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.inputFormatters,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Focus(
      onFocusChange: (bool focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isFocused
                ? AppColors.primary.withValues(alpha: 0.8)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.outlineLight.withValues(alpha: 0.5)),
            width: _isFocused ? 1.5 : 1,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          readOnly: widget.readOnly,
          inputFormatters: widget.inputFormatters,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            fillColor: Colors.transparent,
            filled: true,
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: IconTheme(
                      data: IconThemeData(
                        color: _isFocused
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      child: widget.prefixIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 48, minHeight: 48),
            suffixIcon: widget.suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final String imageUrl;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;
  final String senderRole;
  final String? avatarUrl;
  final String type;
  final String attachmentUrl;
  final Function(Offset position)? onLongPress;
  final Map<String, String>? reactions;
  final ChatMessageEntity? replyToMessage;
  final VoidCallback? onReply;

  const ChatBubble({
    super.key,
    required this.text,
    this.imageUrl = '',
    required this.isMe,
    required this.timestamp,
    this.isRead = false,
    this.avatarUrl,
    this.senderRole = 'user',
    this.type = 'text',
    this.attachmentUrl = '',
    this.onLongPress,
    this.reactions,
    this.replyToMessage,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String normalizedType = type.trim().toLowerCase();
    final String normalizedAttachment = attachmentUrl.trim().toLowerCase();
    final bool isImageMessage = normalizedType == 'image' ||
        _looksLikeImageAttachment(normalizedAttachment);
    final bool isVoiceMessage = normalizedType == 'voice' ||
        normalizedType == 'audio' ||
        _looksLikeVoiceAttachment(normalizedAttachment);
    final bool isDocumentMessage = normalizedType == 'document' ||
        _looksLikeDocumentAttachment(normalizedAttachment);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            AvatarWidget(
              url: avatarUrl ?? '',
              radius: 16,
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: _SwipeToReply(
              onReply: onReply,
              child: GestureDetector(
                onLongPressStart: onLongPress != null
                    ? (details) => onLongPress!(details.globalPosition)
                    : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      clipBehavior: isImageMessage ? Clip.antiAlias : Clip.none,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width *
                            (isImageMessage || isDocumentMessage ? 0.70 : 0.74),
                      ),
                      padding: isImageMessage
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                      margin: EdgeInsets.only(
                        bottom: (reactions != null && reactions!.isNotEmpty)
                            ? 8
                            : 0,
                      ),
                      decoration: BoxDecoration(
                        gradient: isMe ? AppColors.gradientPrimary : null,
                        color: isMe
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(24),
                          topRight: const Radius.circular(24),
                          bottomLeft: Radius.circular(isMe ? 24 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 24),
                        ),
                        border: Border.all(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.15)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05)),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isMe
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : Colors.black
                                    .withValues(alpha: isDark ? 0.2 : 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (!isMe &&
                              (senderRole == 'owner' ||
                                  senderRole == 'staff' ||
                                  senderRole == 'developer' ||
                                  senderRole == 'admin'))
                            Padding(
                              padding: EdgeInsets.only(
                                top: isImageMessage ? 10 : 0,
                                left: isImageMessage ? 12 : 1,
                                bottom: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (senderRole == 'owner' ||
                                      senderRole == 'developer') ...[
                                    const Icon(Icons.verified_rounded,
                                        color: Color(0xFFFFD700), size: 14),
                                    const SizedBox(width: 4),
                                  ] else if (senderRole == 'staff' ||
                                      senderRole == 'admin') ...[
                                    const Icon(Icons.verified_rounded,
                                        color: Color(0xFF6366F1), size: 14),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    senderRole.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: senderRole == 'owner' ||
                                              senderRole == 'developer'
                                          ? const Color(0xFFFFD700)
                                          : const Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (replyToMessage != null)
                            _ReplyPreview(
                              message: replyToMessage!,
                              isMe: isMe,
                              isDark: isDark,
                            ),
                          if (isImageMessage)
                            _ImageContent(
                              imageUrl: attachmentUrl.isEmpty
                                  ? imageUrl
                                  : attachmentUrl,
                              isMe: isMe,
                              isDark: isDark,
                              text: text,
                              timestamp: timestamp,
                              isRead: isRead,
                            ),
                          if (isVoiceMessage)
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: VoiceMessagePlayer(
                                url: attachmentUrl,
                                isMe: isMe,
                                timestamp: timestamp,
                                isRead: isRead,
                              ),
                            ),
                          if (isDocumentMessage)
                            _DocumentContent(
                              fileName: text,
                              url: attachmentUrl,
                              isMe: isMe,
                              isDark: isDark,
                              timestamp: timestamp,
                              isRead: isRead,
                            ),
                          if (!isImageMessage &&
                              !isVoiceMessage &&
                              !isDocumentMessage)
                            _TextContent(
                              text: text,
                              isMe: isMe,
                              isDark: isDark,
                              timestamp: timestamp,
                              isRead: isRead,
                            ),
                        ],
                      ),
                    ),
                    if (reactions != null && reactions!.isNotEmpty)
                      Positioned(
                        bottom: -10,
                        right: isMe ? -4 : null,
                        left: isMe ? null : -4,
                        child: _ReactionBadge(
                          reactions: reactions!,
                          isMe: isMe,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms).scale(
                  begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 10),
            AvatarWidget(
              url: avatarUrl ?? '',
              radius: 16,
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8)),
          ],
        ],
      ),
    );
  }

  bool _looksLikeImageAttachment(String normalizedAttachment) {
    if (normalizedAttachment.isEmpty) {
      return false;
    }
    return normalizedAttachment.contains('.jpg') ||
        normalizedAttachment.contains('.jpeg') ||
        normalizedAttachment.contains('.png') ||
        normalizedAttachment.contains('.webp') ||
        normalizedAttachment.contains('.gif') ||
        normalizedAttachment.contains('/image/upload/') ||
        normalizedAttachment.contains('image/');
  }

  bool _looksLikeVoiceAttachment(String normalizedAttachment) {
    if (normalizedAttachment.isEmpty) {
      return false;
    }
    return normalizedAttachment.contains('.m4a') ||
        normalizedAttachment.contains('.mp3') ||
        normalizedAttachment.contains('.wav') ||
        normalizedAttachment.contains('.aac') ||
        normalizedAttachment.contains('.ogg') ||
        normalizedAttachment.contains('.webm') ||
        normalizedAttachment.contains('.mp4') ||
        normalizedAttachment.contains('audio/');
  }

  bool _looksLikeDocumentAttachment(String normalizedAttachment) {
    if (normalizedAttachment.isEmpty) {
      return false;
    }
    return normalizedAttachment.contains('.pdf') ||
        normalizedAttachment.contains('.doc') ||
        normalizedAttachment.contains('.docx') ||
        normalizedAttachment.contains('.xls') ||
        normalizedAttachment.contains('.xlsx') ||
        normalizedAttachment.contains('.ppt') ||
        normalizedAttachment.contains('.pptx') ||
        normalizedAttachment.contains('.txt') ||
        normalizedAttachment.contains('.csv');
  }
}

class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;

  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.isMe,
    required this.timestamp,
    required this.isRead,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (widget.url.startsWith('http')) {
        await _audioPlayer.play(UrlSource(widget.url));
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.url));
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String minutes = twoDigits(d.inMinutes.remainder(60));
    final String seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.isMe ? Colors.white : AppColors.chatPrimary;
    final Color metaColor =
        widget.isMe ? Colors.white70 : AppColors.textTertiary;

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white : AppColors.chatPrimary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _togglePlay,
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMe ? AppColors.chatPrimary : Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 0),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 0),
                    activeTrackColor: color,
                    inactiveTrackColor: color.withValues(alpha: 0.3),
                    thumbColor: color,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble(),
                    value: _position.inMilliseconds
                        .clamp(0, _duration.inMilliseconds)
                        .toDouble(),
                    onChanged: (value) async {
                      final position = Duration(milliseconds: value.toInt());
                      await _audioPlayer.seek(position);
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_isPlaying ? _position : _duration),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(widget.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: metaColor,
                          ),
                        ),
                        if (widget.isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            widget.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 12,
                            color:
                                widget.isRead ? Colors.white : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceCard extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final IconData icon;
  final Color color;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const FinanceCard({
    super.key,
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.icon,
    required this.color,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey<String>(id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.delete_sweep_rounded,
              color: AppColors.error, size: 28),
        ),
        onDismissed: (_) => onDelete?.call(),
        child: ModernGlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 24,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppFormatters.dateShort(date),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '-${AppFormatters.currency(amount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  final double totalSpent;
  final double budget;
  final double income;

  const BalanceCard({
    super.key,
    required this.totalSpent,
    required this.budget,
    required this.income,
  });

  @override
  Widget build(BuildContext context) {
    final double pct =
        budget <= 0 ? 0 : (totalSpent / budget).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.9),
                  AppColors.primaryDark.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Total Pengeluaran'.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'Bulan Ini',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppFormatters.currency(totalSpent),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Budget: ${AppFormatters.currency(budget)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.02, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatItem(
                        label: 'Budget',
                        value: AppFormatters.compactCurrency(budget),
                        icon: Icons.flag_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatItem(
                        label: 'Sisa',
                        value:
                            AppFormatters.compactCurrency(budget - totalSpent),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3147) : const Color(0xFFE5E7EB),
      highlightColor:
          isDark ? const Color(0xFF3D4160) : const Color(0xFFF3F4F6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List<AnimationController>.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(reverse: true),
    );
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final AnimationController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          3,
          (int i) => AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) => Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              width: 8,
              height: 8 + _controllers[i].value * 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.4 + _controllers[i].value * 0.6,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.6),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppAlert {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = false,
    Duration? duration,
  }) async {
    HapticFeedback.heavyImpact();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: (isError ? AppColors.error : AppColors.success)
                            .withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isError ? AppColors.error : AppColors.primary)
                              .withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                (isError ? AppColors.error : AppColors.success)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isError
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_outline_rounded,
                            color:
                                isError ? AppColors.error : AppColors.success,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomButton(
                          text: 'Lanjutkan',
                          onPressed: () => Navigator.of(context).pop(),
                          gradient: isError
                              ? const LinearGradient(colors: [
                                  Color(0xFFF43F5E),
                                  Color(0xFFBE123C)
                                ])
                              : AppColors.gradientPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A premium floating toast notification with glassmorphism, slide-up animation,
/// progress bar countdown, and swipe-to-dismiss.
class SmartToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    dismiss();
    HapticFeedback.mediumImpact();

    final overlay = Overlay.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _SmartToastWidget(
        message: message,
        isError: isError,
        isDark: isDark,
        duration: duration,
        icon: icon,
        onDismiss: () {
          entry.remove();
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _SmartToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isDark;
  final Duration duration;
  final IconData? icon;
  final VoidCallback onDismiss;

  const _SmartToastWidget({
    required this.message,
    required this.isError,
    required this.isDark,
    required this.duration,
    required this.onDismiss,
    this.icon,
  });

  @override
  State<_SmartToastWidget> createState() => _SmartToastWidgetState();
}

class _SmartToastWidgetState extends State<_SmartToastWidget>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final AnimationController _progressController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _slideController.forward();
    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dismissWithAnimation();
      }
    });
  }

  void _dismissWithAnimation() async {
    await _slideController.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final bgColor = widget.isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.92)
        : const Color(0xFF0F172A).withValues(alpha: 0.92);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.down,
              onDismissed: (_) => widget.onDismiss(),
              child: FractionallySizedBox(
                widthFactor: 0.88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.icon ??
                                        (widget.isError
                                            ? Icons.error_outline_rounded
                                            : Icons
                                                .check_circle_outline_rounded),
                                    color: accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    widget.message,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, _) {
                              return Container(
                                height: 2.5,
                                width: double.infinity,
                                color: Colors.white.withValues(alpha: 0.05),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: 1 - _progressController.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor,
                                          accentColor.withValues(alpha: 0.4),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              );
                            },
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
    );
  }
}

class ReactionMenu {
  static void show(
    BuildContext context, {
    required Offset position,
    required Function(String emoji) onReactionSelected,
    VoidCallback? onDelete,
    bool isMe = true,
  }) {
    HapticFeedback.mediumImpact();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.1),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final double curve = Curves.easeOutBack.transform(anim1.value);
        return Stack(
          children: [
            Positioned(
              top: position.dy - 70,
              left: isMe ? null : position.dx,
              right: isMe
                  ? (MediaQuery.of(context).size.width - position.dx - 40)
                  : null,
              child: Transform.scale(
                scale: curve,
                alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
                child: Opacity(
                  opacity: anim1.value,
                  child: Material(
                    color: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? const Color(0xFF1E2235).withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...['👍', '❤️', '😂', '😮', '😢', '🙏']
                                  .map((emoji) {
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onReactionSelected(emoji);
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                );
                              }),
                              if (onDelete != null) ...[
                                Container(
                                  height: 24,
                                  width: 1,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  color: Colors.white24,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                    onDelete();
                                  },
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback? onReply;

  const _SwipeToReply({required this.child, this.onReply});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _offset = 0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (widget.onReply == null) return;
        setState(() {
          _offset += details.delta.dx;
          // Only allow swipe to the right
          if (_offset < 0) _offset = 0;
          if (_offset > 70) _offset = 70;

          if (_offset >= 60 && !_triggered) {
            _triggered = true;
            HapticFeedback.mediumImpact();
          } else if (_offset < 60) {
            _triggered = false;
          }
        });
      },
      onHorizontalDragEnd: (details) {
        if (_triggered) {
          widget.onReply?.call();
        }
        setState(() {
          _offset = 0;
          _triggered = false;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          if (_offset > 0)
            Positioned(
              left: -40 + (_offset * 0.5),
              child: Opacity(
                opacity: (_offset / 70).clamp(0, 1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.reply_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_offset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMe;
  final bool isDark;

  const _ReplyPreview({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.black.withValues(alpha: 0.1)
            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white38 : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.senderUsername,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.text.trim().isEmpty ? 'Media' : message.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.7)
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionBadge extends StatelessWidget {
  final Map<String, String> reactions;
  final bool isMe;
  final bool isDark;

  const _ReactionBadge({
    required this.reactions,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Unique emojis
    final emojis = reactions.values.toSet().toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emojis.join(' '),
            style: const TextStyle(fontSize: 12),
          ),
          if (reactions.length > 1) ...[
            const SizedBox(width: 4),
            Text(
              '${reactions.length}',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageContent extends StatelessWidget {
  final String imageUrl;
  final String text;
  final bool isMe;
  final bool isDark;
  final DateTime timestamp;
  final bool isRead;

  const _ImageContent({
    required this.imageUrl,
    required this.text,
    required this.isMe,
    required this.isDark,
    required this.timestamp,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasCaption = text.trim().isNotEmpty;
    final String timeStr = _formatTime(timestamp);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          AppRoute<void>(
            builder: (_) => _FullScreenImage(imageUrl: imageUrl),
            beginOffset: const Offset(0, 0.05),
          ),
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area with gradient overlay
            ClipRRect(
              borderRadius: hasCaption
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : BorderRadius.circular(16),
              child: Stack(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 320,
                      minHeight: 120,
                      minWidth: 180,
                    ),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              final double? progress =
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null;
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                child: Center(
                                  child: SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      value: progress,
                                      color: isMe
                                          ? Colors.white70
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 160,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black26,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Gagal memuat gambar',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(imageUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.error)),
                          ),
                  ),

                  // Gradient overlay at bottom for timestamp readability
                  if (!hasCaption)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Timestamp overlay on image (only when no caption)
                  if (!hasCaption)
                    Positioned(
                      right: 8,
                      bottom: 6,
                      child: _buildTimeBadge(timeStr, onImage: true),
                    ),
                ],
              ),
            ),

            // Caption area (below image, inside bubble)
            if (hasCaption)
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 7, 11, 2),
                child: Text(
                  text,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.4,
                    color: isMe
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
              ),

            // Timestamp row (below caption, inside bubble)
            if (hasCaption)
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 3, 8, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    _buildTimeBadge(timeStr, onImage: false),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(String timeStr, {required bool onImage}) {
    final Color timeColor = onImage
        ? Colors.white.withValues(alpha: 0.92)
        : (isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textTertiary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: onImage ? FontWeight.w500 : FontWeight.w400,
            color: timeColor,
            shadows: onImage
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 3),
          Icon(
            isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 14,
            color: onImage
                ? (isRead
                    ? const Color(0xFF53BDEB)
                    : Colors.white.withValues(alpha: 0.85))
                : (isRead ? Colors.white : Colors.white70),
            shadows: onImage
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TextContent extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool isDark;
  final DateTime timestamp;
  final bool isRead;

  const _TextContent({
    required this.text,
    required this.isMe,
    required this.isDark,
    required this.timestamp,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final String timeStr = _formatTime(timestamp);

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: isMe
                ? Colors.white
                : (isDark ? Colors.white : AppColors.primaryDark),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeStr,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.6)
                    : (isDark ? Colors.white38 : Colors.black26),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                isRead ? Icons.done_all_rounded : Icons.done_rounded,
                size: 14,
                color:
                    isRead ? Colors.white : Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentContent extends StatelessWidget {
  final String fileName;
  final String url;
  final bool isMe;
  final bool isDark;
  final DateTime timestamp;
  final bool isRead;

  const _DocumentContent({
    required this.fileName,
    required this.url,
    required this.isMe,
    required this.isDark,
    required this.timestamp,
    required this.isRead,
  });

  Future<void> _launchURL() async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color metaColor = isMe ? Colors.white70 : AppColors.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _launchURL,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withValues(alpha: 0.1)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white : AppColors.chatPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: isMe ? AppColors.chatPrimary : Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Klik untuk membuka',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: metaColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: metaColor,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 13,
                      color: isRead ? Colors.white : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color? color;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.blur = 12,
    this.color,
    this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color ??
                (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.3),
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ModernGlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final double borderRadius;
  final bool? isDark;

  const ModernGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.blur = 30,
    this.opacity = 0.08,
    this.borderRadius = 28,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool resolvedIsDark =
        isDark ?? Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    final Color baseColor = resolvedIsDark
        ? AppColors.surfaceDark.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.9);

    final Color borderSideColor = resolvedIsDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.6);

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: resolvedIsDark ? 0.3 : 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: radius,
              border: Border.all(
                color: borderSideColor,
                width: 1.2,
              ),
            ),
            child: Stack(
              children: <Widget>[
                // Soft gradient spot top-right
                Positioned(
                  top: -60,
                  right: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary
                              .withValues(alpha: resolvedIsDark ? 0.08 : 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding ?? const EdgeInsets.all(24),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool? isDark;
  final String? tooltip;

  const TopBarAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isDark,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final bool resolvedIsDark =
        isDark ?? Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: resolvedIsDark
                    ? <Color>[
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.03),
                      ]
                    : <Color>[
                        Colors.white.withValues(alpha: 0.98),
                        const Color(0xFFF1F7FF).withValues(alpha: 0.92),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: resolvedIsDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.92),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: resolvedIsDark ? 0.10 : 0.08,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: resolvedIsDark
                  ? AppColors.textPrimaryDark
                  : AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}

class AvatarWidget extends StatelessWidget {
  final String url;
  final double radius;
  final bool lowDataMode;
  final Color? backgroundColor;

  const AvatarWidget({
    super.key,
    required this.url,
    this.radius = 24,
    this.lowDataMode = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String trimmedUrl = url.trim();
    final ImageProvider<Object>? imageProvider =
        !lowDataMode && trimmedUrl.isNotEmpty ? NetworkImage(trimmedUrl) : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ??
          (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.surfaceLight),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(
              Icons.person_rounded,
              size: radius,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            )
          : null,
    );
  }
}

class AppAssetIcon extends StatelessWidget {
  final String path;
  final double size;
  final bool? isDark;
  final Color? borderColor;
  final Color? backgroundColor;

  const AppAssetIcon({
    super.key,
    required this.path,
    this.size = 24,
    this.isDark,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool resolvedIsDark =
        isDark ?? Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((size + 8) / 2),
        color: backgroundColor ??
            (resolvedIsDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.86)),
        border: Border.all(
          color: borderColor ??
              (resolvedIsDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : AppColors.primary.withValues(alpha: 0.20)),
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: Image.asset(
          path,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class ModernGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  final double? width;

  const ModernGlassButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isEnabled = onTap != null && !isLoading;
    final Color foregroundColor = isPrimary
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.primaryDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                onTap?.call();
              }
            : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: isEnabled ? 1 : 0.6,
          child: GlassContainer(
            width: width,
            borderRadius: 18,
            blur: 14,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            color: isPrimary
                ? AppColors.primary.withValues(alpha: 0.85)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(foregroundColor),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, color: foregroundColor, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FluidBackground extends StatelessWidget {
  final List<Color>? orbColors;
  final bool? isDark;

  const FluidBackground({super.key, this.orbColors, this.isDark});

  @override
  Widget build(BuildContext context) {
    final bool resolvedIsDark =
        isDark ?? Theme.of(context).brightness == Brightness.dark;
    final List<Color> colors = orbColors ??
        const <Color>[
          Color(0xFF4F46E5), // Indigo
          Color(0xFF10B981), // Emerald
          Color(0xFF0EA5E9), // Sky
        ];

    return RepaintBoundary(
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: resolvedIsDark
                    ? const <Color>[
                        Color(0xFF081325),
                        Color(0xFF0F1C34),
                        Color(0xFF132645),
                      ]
                    : const <Color>[
                        Color(0xFFFAFCFF),
                        Color(0xFFF4F8FF),
                        Color(0xFFEAF3FF),
                      ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: <Color>[
                      colors.first.withValues(
                        alpha: resolvedIsDark ? 0.10 : 0.06,
                      ),
                      Colors.transparent,
                      colors[1 % colors.length].withValues(
                        alpha: resolvedIsDark ? 0.05 : 0.04,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.white.withValues(
                      alpha: resolvedIsDark ? 0.02 : 0.38,
                    ),
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: resolvedIsDark ? 0.14 : 0.03,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.9),
                    radius: 1.3,
                    colors: <Color>[
                      colors.first.withValues(
                        alpha: resolvedIsDark ? 0.16 : 0.10,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          _Orb(
            size: 470,
            color: colors[0].withValues(alpha: resolvedIsDark ? 0.14 : 0.10),
            duration: 12.seconds,
            beginOffset: const Offset(-0.2, -0.1),
            endOffset: const Offset(0.35, 0.2),
          ),
          _Orb(
            size: 420,
            color: colors[1].withValues(alpha: resolvedIsDark ? 0.12 : 0.09),
            duration: 18.seconds,
            beginOffset: const Offset(0.5, 0.46),
            endOffset: const Offset(-0.28, -0.2),
          ),
          if (colors.length > 2)
            _Orb(
              size: 330,
              color: colors[2].withValues(alpha: resolvedIsDark ? 0.10 : 0.07),
              duration: 14.seconds,
              beginOffset: const Offset(0.12, 0.62),
              endOffset: const Offset(-0.42, 0.24),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: resolvedIsDark ? 0 : 0.018,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Offset beginOffset;
  final Offset endOffset;

  const _Orb({
    required this.size,
    required this.color,
    required this.duration,
    required this.beginOffset,
    required this.endOffset,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedAlign(
        duration: duration,
        alignment: Alignment(beginOffset.dx, beginOffset.dy),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
                begin: 0.8,
                end: 1.2,
                duration: duration,
                curve: Curves.easeInOut)
            .move(
              begin: Offset.zero,
              end: Offset(
                (endOffset.dx - beginOffset.dx) * 100,
                (endOffset.dy - beginOffset.dy) * 100,
              ),
              duration: duration,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}
