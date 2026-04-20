import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import 'package:smartlife_app/core/navigation/app_route.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/chat_provider.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_user_profile_screen.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_image_preview_screen.dart';
import 'package:smartlife_app/presentation/providers/ai_provider.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:flutter/foundation.dart' as foundation;

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
  late String _chatId;
  bool _isRecording = false;
  String? _recordingPath;
  DateTime? _recordingStartedAt;
  bool _isSendingVoice = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  bool _showMic = true;
  bool _showEmojiPicker = false;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<String, GlobalKey> _messageItemKeys = <String, GlobalKey>{};
  List<ChatMessageEntity> _latestMessages = const <ChatMessageEntity>[];
  bool _isSearchMode = false;
  String _searchQuery = '';
  List<String> _searchMatchMessageIds = const <String>[];
  int _activeSearchMatchIndex = -1;

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
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });

    _msgCtrl.addListener(() {
      final bool shouldShowMic = _msgCtrl.text.trim().isEmpty;
      if (_showMic != shouldShowMic) {
        setState(() => _showMic = shouldShowMic);
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ChatState chatState = ref.watch(chatProvider);
    final AuthState authState = ref.watch(authProvider);
    final String currentUserId = authState.user?.id ?? '';
    final bool lowDataMode = HiveService.getUserScopedAppBool(
      HiveBoxes.prefLowDataMode,
      userId: currentUserId,
      fallback: false,
      fallbackToLegacy: true,
    );
    final List<ChatMessageEntity> messages = _chatId.isEmpty
        ? const <ChatMessageEntity>[]
        : ref.read(chatProvider.notifier).messagesOfChat(_chatId);
    _latestMessages = messages;
    _pruneMessageItemKeys(messages);
    _syncSearchMatches(messages);
    final bool isTyping = chatState.typingFrom[widget.contact.userId] == true;

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
            FluidBackground(isDark: isDark),
            Column(
              children: <Widget>[
                _buildAppBar(context, isDark, isTyping, lowDataMode),
                Expanded(
                  child: messages.isEmpty
                      ? _EmptyChatDetail(isDark: isDark)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          reverse:
                              true, // New: latest messages at the bottom, growing upwards
                          cacheExtent: 1000,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                          itemCount: messages.length + (isTyping ? 1 : 0),
                          itemBuilder: (_, int index) {
                            // If reversed, the typing indicator (if it exists) should be at the bottom (index 0)
                            if (isTyping && index == 0) {
                              return RepaintBoundary(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 4, left: 40, bottom: 8),
                                  child: Row(
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage: lowDataMode ||
                                                widget.contact.avatar.isEmpty
                                            ? null
                                            : NetworkImage(
                                                widget.contact.avatar),
                                        child: lowDataMode ||
                                                widget.contact.avatar.isEmpty
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      const TypingIndicator(),
                                    ],
                                  ).animate().fadeIn(duration: 220.ms),
                                ),
                              );
                            }

                            final int messageIndex = messages.length -
                                1 -
                                (isTyping ? index - 1 : index);
                            if (messageIndex < 0 ||
                                messageIndex >= messages.length) {
                              return const SizedBox();
                            }
                            final ChatMessageEntity msg =
                                messages[messageIndex];

                            final bool isMatched =
                                _matchesSearch(msg, _searchQuery);
                            final bool isActiveMatch =
                                _currentSearchMatchId == msg.id;

                            return RepaintBoundary(
                              child: Container(
                                key: _messageItemKey(msg.id),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: isActiveMatch
                                      ? AppColors.primary.withValues(
                                          alpha: isDark ? 0.15 : 0.09,
                                        )
                                      : (isMatched
                                          ? AppColors.primary.withValues(
                                              alpha: isDark ? 0.08 : 0.04,
                                            )
                                          : Colors.transparent),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isActiveMatch
                                      ? Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.5),
                                          width: 1.2,
                                        )
                                      : null,
                                ),
                                child: ChatBubble(
                                  key: ValueKey(msg.id),
                                  text: msg.text,
                                  type: msg.type,
                                  attachmentUrl: msg.attachmentUrl,
                                  isMe: msg.senderId == currentUserId,
                                  senderRole: msg.senderRole,
                                  timestamp: msg.createdAt,
                                  avatarUrl: msg.senderId == currentUserId
                                      ? (authState.user?.avatar ?? '')
                                      : (lowDataMode
                                          ? null
                                          : widget.contact.avatar),
                                  reactions: msg.reactions,
                                  replyToMessage: msg.replyToMessage,
                                  onReply: () => ref
                                      .read(chatProvider.notifier)
                                      .setReplyMessage(msg),
                                  onLongPress: (position) =>
                                      _showReactionMenu(msg, position),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 210.ms)
                                  .slideY(begin: 0.08, end: 0),
                            );
                          },
                        ),
                ),
                _buildInputBar(context, isDark, chatState),
                Offstage(
                  offstage: !_showEmojiPicker,
                  child: SizedBox(
                    height: 250,
                    child: emoji.EmojiPicker(
                      textEditingController: _msgCtrl,
                      onEmojiSelected: (category, emoji) {},
                      config: emoji.Config(
                        bottomActionBarConfig:
                            const emoji.BottomActionBarConfig(
                                showBackspaceButton: false,
                                showSearchViewButton: false),
                        categoryViewConfig: emoji.CategoryViewConfig(
                          backgroundColor: isDark
                              ? AppColors.backgroundDark
                              : const Color(0xFFF0ECF4),
                          indicatorColor: AppColors.primary,
                          iconColorSelected: AppColors.primary,
                        ),
                        emojiViewConfig: emoji.EmojiViewConfig(
                          backgroundColor: isDark
                              ? AppColors.backgroundDark
                              : const Color(0xFFF0ECF4),
                          emojiSizeMax: 28 *
                              (foundation.defaultTargetPlatform ==
                                      TargetPlatform.iOS
                                  ? 1.30
                                  : 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _ScrollToBottomButton(
              scrollCtrl: _scrollCtrl,
              show: _scrollCtrl.hasClients &&
                  _scrollCtrl.offset <
                      _scrollCtrl.position.maxScrollExtent - 200,
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
    if (_isSearchMode) {
      return _buildSearchBar(context, isDark);
    }

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 12,
      ),
      child: ModernGlassCard(
        isDark: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        borderRadius: 24,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : AppColors.primaryDark),
              onPressed: _handleBackPressed,
            ),
            InkWell(
              onTap: _openUserProfilePage,
              borderRadius: BorderRadius.circular(20),
              child: Hero(
                tag:
                    'avatar_${widget.contact.chatId}_${widget.contact.userId}_list',
                child: Stack(
                  children: <Widget>[
                    AvatarWidget(
                      url: widget.contact.avatar,
                      radius: 20,
                      lowDataMode: lowDataMode,
                    ),
                    if (widget.contact.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.greenAccent.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _openUserProfilePage,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.contact.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color:
                                  isDark ? Colors.white : AppColors.primaryDark,
                            ),
                          ),
                        ),
                        if (widget.contact.role == 'owner' ||
                            widget.contact.role == 'developer') ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFFFFD700), size: 14),
                        ] else if (widget.contact.role == 'staff' ||
                            widget.contact.role == 'admin') ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF6366F1), size: 14),
                        ],
                      ],
                    ),
                    Text(
                      isTyping
                          ? 'typing...'
                          : (widget.contact.isOnline
                              ? 'Available'
                              : 'Encrypted'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isTyping
                            ? AppColors.primary
                            : (isDark ? Colors.white24 : Colors.black26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.search_rounded,
                  size: 20, color: isDark ? Colors.white38 : Colors.black26),
              onPressed: _openSearchMode,
            ),
            _buildActionMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    final bool isMuted = HiveService.getUserScopedAppBool(
          HiveBoxes.prefChatNotifications,
          userId: ref.read(authProvider).user?.id ?? '',
          fallback: true,
        ) ==
        false;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            _openUserProfilePage();
            break;
          case 'mute':
            final currentUserId = ref.read(authProvider).user?.id ?? '';
            await HiveService.putUserScopedAppValue(
              HiveBoxes.prefChatNotifications,
              isMuted,
              userId: currentUserId,
            );
            if (mounted) setState(() {});
            break;
          case 'search':
            _openSearchMode();
            break;
          case 'summarize':
            _handleSummarize();
            break;
          case 'delete':
            _confirmDeleteConversation();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Text('Lihat Profil'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'mute',
          child: Row(
            children: [
              Icon(
                  isMuted
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: AppColors.primary,
                  size: 20),
              const SizedBox(width: 12),
              Text(isMuted ? 'Bunyikan Notifikasi' : 'Bisukan Notifikasi'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'search',
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Text('Cari Pesan'),
            ],
          ),
        ),
        if (ref.read(authProvider).user?.role == 'owner' ||
            ref.read(authProvider).user?.role == 'staff' ||
            ref.read(authProvider).user?.role == 'developer')
          const PopupMenuItem(
            value: 'summarize',
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Text('Ringkas Percakapan'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Hapus Percakapan', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
    );
  }

  void _handleSummarize() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: GlassContainer(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(),
        ),
      ),
    );

    final summary = await ref.read(aiProvider.notifier).summarizeChat(_chatId);

    if (mounted) Navigator.pop(context); // Close loading

    if (summary == null || summary.isEmpty) return;

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ringkasan AI',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      summary,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ).animate().scaleXY(
              begin: 0.9,
              end: 1,
              curve: Curves.easeOutBack,
              duration: 300.ms,
            ),
      );
    }
  }

  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Percakapan?'),
        content: const Text(
            'Semua pesan dalam percakapan ini akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              final rootNavigator = Navigator.of(this.context);
              Navigator.pop(context);
              await ref.read(chatProvider.notifier).deleteConversation(_chatId);
              if (mounted) rootNavigator.pop();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(ChatMessageEntity msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pesan?'),
        content: const Text('Pilih opsi penghapusan pesan.'),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(msg, false);
            },
            child: const Text('Hapus untuk saya',
                style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(msg, true);
            },
            child: const Text('Hapus untuk semua',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessageEntity msg, bool forEveryone) async {
    await ref
        .read(chatProvider.notifier)
        .deleteMessage(msg.id, msg.chatId, forEveryone: forEveryone);
  }

  Widget _buildInputBar(
      BuildContext context, bool isDark, ChatState chatState) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chatState.replyMessage != null)
              _buildReplyBar(context, isDark, chatState.replyMessage!),
            ModernGlassCard(
              isDark: isDark,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderRadius: 32,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isRecording
                    ? _buildRecordingOverlay(isDark)
                    : Row(
                        key: const ValueKey('normal_input'),
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          IconButton(
                            onPressed: _toggleEmojiPicker,
                            icon: Icon(Icons.emoji_emotions_outlined,
                                color:
                                    isDark ? Colors.white38 : Colors.black26),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline_rounded,
                                color:
                                    isDark ? Colors.white38 : Colors.black26),
                            onPressed: _showAttachmentMenu,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _msgCtrl,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 5,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primaryDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Encrypt a message...',
                                border: InputBorder.none,
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color:
                                      isDark ? Colors.white24 : Colors.black26,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onLongPressStart: (_) {
                              if (_msgCtrl.text.trim().isEmpty) {
                                HapticFeedback.heavyImpact();
                                _startRecording();
                              }
                            },
                            onLongPressEnd: (_) {
                              if (_isRecording) {
                                _stopAndSendRecording();
                              }
                            },
                            onTap: () {
                              if (_msgCtrl.text.trim().isNotEmpty) {
                                _sendMessage();
                              } else {
                                _startRecording();
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _msgCtrl.text.trim().isNotEmpty
                                    ? Icons.send_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 20,
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
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 12,
      ),
      child: ModernGlassCard(
        isDark: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        borderRadius: 24,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: _closeSearchMode,
            ),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari pesan...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty &&
                _searchMatchMessageIds.isNotEmpty) ...[
              Text(
                '${_activeSearchMatchIndex + 1}/${_searchMatchMessageIds.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
                onPressed: _goToPreviousSearchMatch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
                onPressed: _goToNextSearchMatch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: _clearSearchQuery,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay(bool isDark) {
    return Row(
      key: const ValueKey('recording_overlay'),
      children: [
        IconButton(
          onPressed: _cancelRecording,
          icon: const Icon(Icons.delete_outline_rounded,
              color: Colors.red, size: 22),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.mic_rounded, color: Colors.red, size: 20)
            .animate(onPlay: (ctrl) => ctrl.repeat())
            .fade(duration: 500.ms)
            .then()
            .fade(duration: 500.ms),
        const SizedBox(width: 12),
        Text(
          _formatDuration(_recordDuration),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.primaryDark,
          ),
        ),
        const Spacer(),
        if (_isSendingVoice)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          GestureDetector(
            onTap: _stopAndSendRecording,
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
      ],
    );
  }

  void _toggleEmojiPicker() {
    HapticFeedback.lightImpact();
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
      setState(() => _showEmojiPicker = false);
      return;
    }

    _focusNode.unfocus();
    setState(() => _showEmojiPicker = true);
  }

  Future<void> _sendMessage() async {
    final String text = _msgCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }

    _msgCtrl.clear();
    setState(() => _showMic = true);
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
                replyToId: ref.read(chatProvider).replyMessage?.id,
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

  GlobalKey _messageItemKey(String messageId) {
    return _messageItemKeys.putIfAbsent(messageId, () => GlobalKey());
  }

  void _pruneMessageItemKeys(List<ChatMessageEntity> messages) {
    final Set<String> activeIds = messages.map((m) => m.id).toSet();
    _messageItemKeys.removeWhere((key, _) => !activeIds.contains(key));
  }

  String? get _currentSearchMatchId {
    if (_activeSearchMatchIndex < 0 ||
        _activeSearchMatchIndex >= _searchMatchMessageIds.length) {
      return null;
    }
    return _searchMatchMessageIds[_activeSearchMatchIndex];
  }

  bool _matchesSearch(ChatMessageEntity message, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return false;
    }

    final body = message.text.toLowerCase();
    final quotedText = (message.replyToMessage?.text ?? '').toLowerCase();
    return body.contains(normalizedQuery) ||
        quotedText.contains(normalizedQuery);
  }

  List<String> _collectSearchMatches(
    List<ChatMessageEntity> messages,
    String normalizedQuery,
  ) {
    if (normalizedQuery.isEmpty) {
      return const <String>[];
    }
    return messages
        .where((m) => _matchesSearch(m, normalizedQuery))
        .map((m) => m.id)
        .toList(growable: false);
  }

  void _syncSearchMatches(List<ChatMessageEntity> messages) {
    if (!_isSearchMode || _searchQuery.isEmpty) {
      return;
    }

    final recalculated = _collectSearchMatches(messages, _searchQuery);
    if (foundation.listEquals(recalculated, _searchMatchMessageIds)) {
      return;
    }

    final activeMatchId = _currentSearchMatchId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final nextActiveIndex = activeMatchId == null
          ? (recalculated.isEmpty ? -1 : 0)
          : recalculated.indexOf(activeMatchId);

      setState(() {
        _searchMatchMessageIds = recalculated;
        _activeSearchMatchIndex = recalculated.isEmpty
            ? -1
            : (nextActiveIndex >= 0 ? nextActiveIndex : 0);
      });
    });
  }

  void _openSearchMode() {
    if (!_isSearchMode) {
      setState(() => _isSearchMode = true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _searchFocusNode.requestFocus();
    });

    _applySearch(_searchCtrl.text, jumpToFirst: true);
  }

  void _closeSearchMode() {
    _searchFocusNode.unfocus();
    _searchCtrl.clear();
    setState(() {
      _isSearchMode = false;
      _searchQuery = '';
      _searchMatchMessageIds = const <String>[];
      _activeSearchMatchIndex = -1;
    });
  }

  void _clearSearchQuery() {
    _searchCtrl.clear();
    _onSearchChanged('');
  }

  void _onSearchChanged(String rawValue) {
    _applySearch(rawValue, jumpToFirst: true);
  }

  void _applySearch(String rawValue, {required bool jumpToFirst}) {
    final normalizedQuery = rawValue.trim().toLowerCase();
    final matches = _collectSearchMatches(_latestMessages, normalizedQuery);
    final activeId = _currentSearchMatchId;

    int nextActiveIndex = -1;
    if (matches.isNotEmpty) {
      if (!jumpToFirst && activeId != null) {
        final existingIndex = matches.indexOf(activeId);
        if (existingIndex >= 0) {
          nextActiveIndex = existingIndex;
        }
      }
      if (nextActiveIndex < 0) {
        nextActiveIndex = 0;
      }
    }

    setState(() {
      _searchQuery = normalizedQuery;
      _searchMatchMessageIds = matches;
      _activeSearchMatchIndex = nextActiveIndex;
    });

    if (nextActiveIndex >= 0) {
      _jumpToSearchMatch(nextActiveIndex, withSetState: false);
    }
  }

  void _goToPreviousSearchMatch() {
    if (_searchMatchMessageIds.isEmpty) {
      return;
    }

    final previousIndex = _activeSearchMatchIndex <= 0
        ? _searchMatchMessageIds.length - 1
        : _activeSearchMatchIndex - 1;
    _jumpToSearchMatch(previousIndex);
  }

  void _goToNextSearchMatch() {
    if (_searchMatchMessageIds.isEmpty) {
      return;
    }

    final nextIndex =
        (_activeSearchMatchIndex + 1) % _searchMatchMessageIds.length;
    _jumpToSearchMatch(nextIndex);
  }

  void _jumpToSearchMatch(int index, {bool withSetState = true}) {
    if (index < 0 || index >= _searchMatchMessageIds.length) {
      return;
    }

    if (withSetState) {
      setState(() => _activeSearchMatchIndex = index);
    }
    _scrollToMessageById(_searchMatchMessageIds[index]);
  }

  Future<void> _scrollToMessageById(String messageId) async {
    final BuildContext? itemContext =
        _messageItemKeys[messageId]?.currentContext;
    if (itemContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      itemContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.35,
    );
  }

  Future<void> _openUserProfilePage() async {
    await Navigator.push<bool>(
      context,
      AppRoute<bool>(
        builder: (_) => ChatUserProfileScreen(
          user: widget.contact,
          allowOpenChat: false,
        ),
        beginOffset: const Offset(0.06, 0),
      ),
    );
  }

  void _handleBackPressed() {
    if (_isSearchMode) {
      _closeSearchMode();
      return;
    }

    _stopTyping();
    if (!mounted) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
          'ppt',
          'pptx'
        ],
      );

      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);

      if (!mounted) return;

      final String url = await ref.read(chatProvider.notifier).uploadFile(file);
      await ref.read(chatProvider.notifier).sendMessage(
            text: result.files.single.name,
            chatId: _chatId.isEmpty ? null : _chatId,
            receiverId: widget.contact.userId,
            type: 'document',
            attachmentUrl: url,
          );
    } catch (e) {
      if (!mounted) return;
      AppAlert.show(
        context,
        title: 'Gagal Memilih Dokumen',
        message: e.toString(),
        isError: true,
      );
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
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (file == null) return;

    if (!mounted) return;

    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      AppRoute<Map<String, dynamic>>(
        builder: (_) => ChatImagePreviewScreen(image: file),
        beginOffset: const Offset(0, 0.06),
      ),
    );

    if (result == null) return;
    final String caption = result['caption'] ?? '';
    final File finalFile = result['file'];

    try {
      // NON-BLOCKING: Instant UI update with local path
      ref.read(chatProvider.notifier).sendMediaMessage(
            file: finalFile,
            text: caption,
            chatId: _chatId,
            type: 'image',
          );

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim gambar: $e')),
      );
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording) {
      return;
    }

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin mikrofon belum diizinkan. Aktifkan izin mic di pengaturan.',
              ),
            ),
          );
        }
        return;
      }

      final Directory appDir = await getTemporaryDirectory();
      final String path = p.join(
        appDir.path,
        'recording_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _recorder.start(config, path: path);

      _recordTimer?.cancel();
      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingStartedAt = DateTime.now();
        _isSendingVoice = false;
        _recordDuration = 0;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_isRecording) {
          timer.cancel();
          return;
        }
        setState(() => _recordDuration++);
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memulai rekaman suara')),
        );
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      setState(() => _isSendingVoice = true);
      _recordTimer?.cancel();
      final String? stopPath = await _recorder.stop();
      final DateTime? startedAt = _recordingStartedAt;
      final int elapsedMs = startedAt == null
          ? _recordDuration * 1000
          : DateTime.now().difference(startedAt).inMilliseconds;

      setState(() {
        _isRecording = false;
        _recordingStartedAt = null;
        _isSendingVoice = false;
        _recordDuration = 0;
      });

      final String? path = (stopPath != null && stopPath.trim().isNotEmpty)
          ? stopPath.trim()
          : _recordingPath;
      _recordingPath = null;
      if (path == null || path.isEmpty) {
        return;
      }

      if (elapsedMs < 700) {
        final tinyFile = File(path);
        if (await tinyFile.exists()) {
          await tinyFile.delete();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rekaman terlalu singkat')),
          );
        }
        return;
      }

      final File file = File(path);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File rekaman tidak ditemukan')),
          );
        }
        return;
      }

      // Use the new non-blocking system
      ref.read(chatProvider.notifier).sendMediaMessage(
            file: file,
            chatId: _chatId,
            type: 'voice',
          );

      _scrollToBottom();
    } catch (e) {
      debugPrint('[CHAT] Error stopping and sending recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingStartedAt = null;
          _isSendingVoice = false;
          _recordingPath = null;
          _recordDuration = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim voice note')),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) {
      return;
    }

    String? stopPath;
    try {
      _recordTimer?.cancel();
      stopPath = await _recorder.stop();
    } catch (_) {}

    final Set<String> paths = <String>{
      if (stopPath != null && stopPath.trim().isNotEmpty) stopPath.trim(),
      if (_recordingPath != null && _recordingPath!.trim().isNotEmpty)
        _recordingPath!.trim(),
    };

    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
      _isSendingVoice = false;
      _recordingPath = null;
      _recordDuration = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice note dibatalkan')),
    );
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _showReactionMenu(ChatMessageEntity msg, Offset position) {
    final bool isMe = msg.senderId == ref.read(authProvider).user?.id;

    ReactionMenu.show(
      context,
      position: position,
      isMe: isMe,
      onReactionSelected: (emoji) {
        ref.read(chatProvider.notifier).addReaction(msg.id, emoji);
      },
      onDelete: isMe ? () => _confirmDeleteMessage(msg) : null,
    );
  }

  Widget _buildReplyBar(
      BuildContext context, bool isDark, ChatMessageEntity message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Membalas ${message.senderUsername}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  message.text.trim().isEmpty ? 'Media' : message.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                ref.read(chatProvider.notifier).clearReplyMessage(),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, end: 0, duration: 200.ms);
  }

  void _showAttachmentMenu() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItemView(
              icon: Icons.description_rounded,
              label: 'Dokumen',
              color: const Color(0xFF4A90E2),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
            _buildMenuItemView(
              icon: Icons.image_rounded,
              label: 'Galeri Foto',
              color: const Color(0xFF50C878),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            _buildMenuItemView(
              icon: Icons.camera_alt_rounded,
              label: 'Ambil Foto',
              color: const Color(0xFFFF6B6B),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemView({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ScrollToBottomButton extends StatefulWidget {
  final ScrollController scrollCtrl;
  final bool show;

  const _ScrollToBottomButton({required this.scrollCtrl, required this.show});

  @override
  State<_ScrollToBottomButton> createState() => _ScrollToBottomButtonState();
}

class _ScrollToBottomButtonState extends State<_ScrollToBottomButton> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollCtrl.addListener(_listener);
  }

  @override
  void dispose() {
    widget.scrollCtrl.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    final bool shouldShow = widget.scrollCtrl.hasClients &&
        widget.scrollCtrl.offset <
            widget.scrollCtrl.position.maxScrollExtent - 400;
    if (_visible != shouldShow) {
      setState(() => _visible = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      right: 20,
      bottom: _visible ? 100 : -50,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _visible ? 1 : 0,
        child: FloatingActionButton.small(
          backgroundColor: AppColors.primary,
          elevation: 4,
          onPressed: () {
            widget.scrollCtrl.animateTo(
              widget.scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
          child: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white, size: 28),
        ),
      ),
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
