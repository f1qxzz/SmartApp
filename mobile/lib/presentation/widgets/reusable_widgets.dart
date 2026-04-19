import 'package:audioplayers/audioplayers.dart';
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
            height: 54,
            decoration: BoxDecoration(
              gradient: widget.isOutlined
                  ? null
                  : (widget.gradient ?? AppColors.gradientPrimary),
              color: widget.isOutlined
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceDark
                      : Colors.white)
                  : null,
              borderRadius: BorderRadius.circular(15),
              border: widget.isOutlined
                  ? Border.all(color: AppColors.primary, width: 1.4)
                  : Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: widget.isOutlined
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: <Widget>[
                  if (!widget.isOutlined)
                    Positioned(
                      top: -24,
                      right: -8,
                      child: Container(
                        width: 86,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(34),
                        ),
                      ),
                    ),
                  Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              if (widget.icon != null) ...<Widget>[
                                widget.icon!,
                                const SizedBox(width: 8),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFocused
                ? AppColors.primary.withValues(alpha: 0.70)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.dividerLight),
            width: _isFocused ? 1.2 : 1,
          ),
          boxShadow: _isFocused
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            fillColor: Colors.transparent,
            filled: true,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 52, minHeight: 52),
            suffixIcon: widget.suffixIcon,
            border: InputBorder.none,
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                        (isImageMessage || isDocumentMessage ? 0.74 : 0.78),
                  ),
                  padding: isImageMessage
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  margin: EdgeInsets.only(
                    bottom: (reactions != null && reactions!.isNotEmpty) ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.chatPrimary
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 20),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.black.withValues(alpha: 0.05),
                            width: 1,
                          ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isImageMessage ? 0.08 : (isMe ? 0.08 : 0.05)),
                        blurRadius: isMe ? 8 : 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (!isMe && (senderRole == 'owner' || senderRole == 'staff' || senderRole == 'developer' || senderRole == 'admin'))
                        Padding(
                          padding: EdgeInsets.only(
                            top: isImageMessage ? 10 : 0,
                            left: isImageMessage ? 12 : 1,
                            bottom: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (senderRole == 'owner' || senderRole == 'developer') ...[
                                const Icon(Icons.verified_rounded, color: Color(0xFFFFD700), size: 14),
                                const SizedBox(width: 4),
                              ] else if (senderRole == 'staff' || senderRole == 'admin') ...[
                                const Icon(Icons.verified_rounded, color: Color(0xFF6366F1), size: 14),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                senderRole.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: senderRole == 'owner' || senderRole == 'developer'
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
                          imageUrl: attachmentUrl.isEmpty ? imageUrl : attachmentUrl,
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
                      if (!isImageMessage && !isVoiceMessage && !isDocumentMessage)
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
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        ),
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
      await _audioPlayer.play(UrlSource(widget.url));
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
    final Color metaColor = widget.isMe ? Colors.white70 : AppColors.textTertiary;

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
                            color: widget.isRead ? Colors.white : Colors.white70,
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

    return Dismissible(
      key: ValueKey<String>(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 24),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.dividerLight,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      '$category - ${_formatDate(date)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  '-${AppFormatters.currency(amount)}',
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${AppFormatters.weekDayShort(d)}, ${d.day} ${months[d.month - 1]}';
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
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.36),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -36,
              left: -16,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Total Pengeluaran',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Bulan Ini',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppFormatters.currency(totalSpent),
                    style: AppTextStyles.moneyLarge(context),
                  ),
                  const SizedBox(height: 20),
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
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct > 0.8 ? AppColors.accentLight : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _StatItem(
                          label: 'Budget',
                          value: AppFormatters.compactCurrency(income),
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatItem(
                          label: 'Sisa',
                          value: AppFormatters.compactCurrency(
                              income - totalSpent),
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.accentLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
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
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
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
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: (isError ? AppColors.error : AppColors.success)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                            color: isError ? AppColors.error : AppColors.success,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        CustomButton(
                          text: 'Lanjutkan',
                          onPressed: () => Navigator.of(context).pop(),
                          gradient: isError
                              ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFF991B1B)])
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
    final accentColor = widget.isError
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);
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
                                            : Icons.check_circle_outline_rounded),
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
                                      color: Colors.white.withValues(alpha: 0.92),
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
              right: isMe ? (MediaQuery.of(context).size.width - position.dx - 40) : null,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
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
                              ...['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onReactionSelected(emoji);
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
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
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
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
              color: isMe ? Colors.white.withValues(alpha: 0.9) : AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.text.trim().isEmpty ? 'Media' : message.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isMe ? Colors.white.withValues(alpha: 0.7) : (isDark ? Colors.white70 : AppColors.textSecondary),
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
                    child: Image.network(
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
                                color: isMe ? Colors.white70 : AppColors.primary,
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
                                color: isDark ? Colors.white38 : Colors.black26,
                                size: 32,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Gagal memuat gambar',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.black26,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
        : (isMe
            ? Colors.white.withValues(alpha: 0.7)
            : AppColors.textTertiary);

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
    final Widget metaRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isMe ? Colors.white70 : AppColors.textTertiary,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 14,
            color: isRead ? Colors.white : Colors.white70,
          ),
        ],
      ],
    );

    // Use Wrap so Flutter naturally shrinks the bubble width to fit content
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      runSpacing: 2,
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            height: 1.4,
            color: isMe
                ? Colors.white
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: metaRow,
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
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
            color: color ?? (isDark 
                ? Colors.white.withValues(alpha: 0.07) 
                : Colors.white.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
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
