import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/chat_provider.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_user_profile_screen.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_image_preview_screen.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final ChatConversationEntity contact;

  const ChatDetailScreen({super.key, required this.contact});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _clockTicker;
  DateTime _currentTime = DateTime.now();
  late String _chatId;
  bool _isRecording = false;
  String? _recordingPath;
  int _recordDuration = 0;
  Timer? _recordTimer;
  bool _showMic = true;

  @override
  void initState() {
    super.initState();
    _chatId = widget.contact.chatId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_chatId.isNotEmpty) {
        await ref.read(chatProvider.notifier).loadMessages(_chatId);
        _scrollToBottom();
      }
    });
    _clockTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _recordTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ChatState chatState = ref.watch(chatProvider);
    final AuthState authState = ref.watch(authProvider);
    final String currentUserId = authState.user?.id ?? '';
    final bool lowDataMode =
        (HiveService.appBox.get(HiveBoxes.prefLowDataMode) as bool?) ?? false;
    final List<ChatMessageEntity> messages = _chatId.isEmpty
        ? const <ChatMessageEntity>[]
        : ref.read(chatProvider.notifier).messagesOfChat(_chatId);
    final bool isTyping =
        ref.read(chatProvider.notifier).isTypingFrom(widget.contact.userId);

    ref.listen<ChatState>(chatProvider, (ChatState? previous, ChatState next) {
      if (!mounted) {
        return;
      }

      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty &&
          previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          return;
        }
        _handleBackPressed();
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            _ChatDetailBackground(isDark: isDark),
            Column(
              children: <Widget>[
                _buildAppBar(context, isDark, isTyping, lowDataMode),
                Expanded(
                  child: messages.isEmpty
                      ? _EmptyChatDetail(isDark: isDark)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          itemCount: messages.length + (isTyping ? 1 : 0),
                          itemBuilder: (_, int index) {
                            if (index == messages.length) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, left: 40),
                                child: Row(
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: lowDataMode ||
                                              widget.contact.avatar.isEmpty
                                          ? null
                                          : NetworkImage(widget.contact.avatar),
                                      child: lowDataMode ||
                                              widget.contact.avatar.isEmpty
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const TypingIndicator(),
                                  ],
                                ).animate().fadeIn(duration: 220.ms),
                              );
                            }

                            final ChatMessageEntity msg = messages[index];
                            return ChatBubble(
                              text: msg.text,
                              type: msg.type,
                              attachmentUrl: msg.attachmentUrl,
                              isMe: msg.senderId == currentUserId,
                              timestamp: msg.createdAt,
                              avatarUrl:
                                  msg.senderId == currentUserId || lowDataMode
                                      ? null
                                      : widget.contact.avatar,
                              onLongPress: () => _showDeleteOptions(msg),
                            )
                                .animate()
                                .fadeIn(duration: 210.ms)
                                .slideY(begin: 0.08, end: 0);
                          },
                        ),
                ),
                _buildInputBar(context, isDark, chatState.isLoading),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    bool isDark,
    bool isTyping,
    bool lowDataMode,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 14,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.dividerLight,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: _handleBackPressed,
          ),
          InkWell(
            onTap: _openUserProfilePage,
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundImage: lowDataMode || widget.contact.avatar.isEmpty
                      ? null
                      : NetworkImage(widget.contact.avatar),
                  child: lowDataMode || widget.contact.avatar.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                if (widget.contact.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.contact.username,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  isTyping
                      ? 'sedang mengetik...'
                      : widget.contact.isOnline
                          ? 'Online sekarang'
                          : 'Terakhir aktif ${_formatLastSeen(widget.contact.lastSeen ?? widget.contact.updatedAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isTyping
                        ? AppColors.secondary
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                    fontWeight: isTyping ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.schedule_rounded, size: 13),
                const SizedBox(width: 4),
                Text(
                  _formatClock(_currentTime),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildActionMenu(context),
        ],
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          _confirmDeleteConversation();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Hapus Percakapan', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert_rounded),
    );
  }

  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Percakapan?'),
        content: const Text('Semua pesan dalam percakapan ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(chatProvider.notifier).deleteConversation(_chatId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark, bool isLoading) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : AppColors.dividerLight,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (!_isRecording)
            IconButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.add_photo_alternate_rounded,
                  color: AppColors.primary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (!_isRecording) const SizedBox(width: 8),
          Expanded(
            child: _isRecording
                ? Row(
                    children: [
                      const Icon(Icons.mic_rounded, color: Colors.red, size: 20)
                          .animate(onPlay: (controller) => controller.repeat())
                          .fade(duration: 500.ms)
                          .then()
                          .fade(duration: 500.ms),
                      const SizedBox(width: 8),
                      Text(
                        'Perekaman ${_formatDuration(_recordDuration)}',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Lepas untuk kirim',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      onChanged: (String value) {
                        setState(() => _showMic = value.trim().isEmpty);
                        ref.read(chatProvider.notifier).setTyping(
                              toUserId: widget.contact.userId,
                              isTyping: value.trim().isNotEmpty,
                            );
                      },
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          _showMic
              ? GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: _stopRecording,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                )
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: isLoading ? null : _sendMessage,
                    child: Opacity(
                      opacity: isLoading ? 0.6 : 1,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color(0x557C7E9D),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final String text = _msgCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }

    _msgCtrl.clear();
    ref.read(chatProvider.notifier).setTyping(
          toUserId: widget.contact.userId,
          isTyping: false,
        );

    try {
      final ChatMessageEntity sent =
          await ref.read(chatProvider.notifier).sendMessage(
                text: text,
                chatId: _chatId.isEmpty ? null : _chatId,
                receiverId: widget.contact.userId,
              );

      if (_chatId.isEmpty && sent.chatId.isNotEmpty) {
        setState(() => _chatId = sent.chatId);
        await ref.read(chatProvider.notifier).loadMessages(_chatId);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesan')),
      );
      return;
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollCtrl.hasClients) {
        return;
      }
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatClock(DateTime value) {
    final String h = value.hour.toString().padLeft(2, '0');
    final String m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatLastSeen(DateTime value) {
    if (value.year < 2000) {
      return 'tidak tersedia';
    }
    final Duration diff = _currentTime.difference(value);
    if (diff.inMinutes < 1) {
      return 'barusan';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    }
    return '${value.day}/${value.month} ${_formatClock(value)}';
  }

  Future<void> _openUserProfilePage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ChatUserProfileScreen(
          user: widget.contact,
          allowOpenChat: false,
        ),
      ),
    );
  }

  void _handleBackPressed() {
    _stopTyping();
    if (!mounted) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _stopTyping() {
    ref.read(chatProvider.notifier).setTyping(
          toUserId: widget.contact.userId,
          isTyping: false,
        );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source);
    if (file == null) return;

    if (!mounted) return;

    final String? caption = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatImagePreviewScreen(image: file),
      ),
    );

    if (caption == null) return; // User cancelled

    try {
      final String url = await ref.read(chatProvider.notifier).uploadFile(File(file.path));
      await ref.read(chatProvider.notifier).sendMessage(
            text: caption,
            chatId: _chatId.isEmpty ? null : _chatId,
            receiverId: widget.contact.userId,
            type: 'image',
            attachmentUrl: url,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim gambar')),
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final Directory appDir = await getTemporaryDirectory();
        final String path = p.join(appDir.path, 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a');
        
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _recorder.start(config, path: path);
        
        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _recordDuration = 0;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordTimer?.cancel();
      final String? path = await _recorder.stop();
      
      setState(() {
        _isRecording = false;
      });

      if (path != null && _recordingPath != null && _recordDuration > 0) {
        final File file = File(path);
        final String url = await ref.read(chatProvider.notifier).uploadFile(file);
        
        await ref.read(chatProvider.notifier).sendMessage(
              text: '',
              chatId: _chatId.isEmpty ? null : _chatId,
              receiverId: widget.contact.userId,
              type: 'voice',
              attachmentUrl: url,
            );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() => _isRecording = false);
    }
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _showDeleteOptions(ChatMessageEntity msg) {
    if (msg.senderId != ref.read(authProvider).user?.id) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Hapus Pesan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(msg);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessageEntity msg) async {
    await ref.read(chatProvider.notifier).deleteMessage(msg.id, msg.chatId);
  }
}

class _ChatDetailBackground extends StatelessWidget {
  final bool isDark;

  const _ChatDetailBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10),
                  AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.07),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyChatDetail extends StatelessWidget {
  final bool isDark;

  const _EmptyChatDetail({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.dividerLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.mark_chat_unread_outlined,
                size: 30,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 10),
              Text(
                'Belum ada pesan, mulai percakapan sekarang.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
