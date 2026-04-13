import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/chat_provider.dart';
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
  late String _chatId;

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
  }

  @override
  void dispose() {
    ref.read(chatProvider.notifier).setTyping(
          toUserId: widget.contact.userId,
          isTyping: false,
        );
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final String currentUserId = authState.user?.id ?? '';
    final List<ChatMessageEntity> messages = _chatId.isEmpty
        ? const []
        : ref.read(chatProvider.notifier).messagesOfChat(_chatId);
    final bool isTyping =
        ref.read(chatProvider.notifier).isTypingFrom(widget.contact.userId);

    ref.listen<ChatState>(chatProvider, (previous, next) {
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

    return Scaffold(
      body: Column(
        children: <Widget>[
          _buildAppBar(isDark, isTyping),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada pesan',
                      style: AppTextStyles.body(context),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (_, int i) {
                      if (i == messages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, left: 40),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: widget.contact.avatar.isEmpty
                                    ? null
                                    : NetworkImage(widget.contact.avatar),
                                child: widget.contact.avatar.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              const TypingIndicator(),
                            ],
                          ).animate().fadeIn(duration: 200.ms),
                        );
                      }

                      final ChatMessageEntity msg = messages[i];
                      return ChatBubble(
                        text: msg.text,
                        isMe: msg.senderId == currentUserId,
                        timestamp: msg.createdAt,
                        avatarUrl: msg.senderId == currentUserId
                            ? null
                            : widget.contact.avatar,
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  ),
          ),
          _buildInputBar(isDark, chatState),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark, bool isTyping) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 8,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Stack(
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.contact.avatar.isEmpty
                    ? null
                    : NetworkImage(widget.contact.avatar),
                child: widget.contact.avatar.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              if (widget.contact.isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.contact.username,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  isTyping
                      ? 'mengetik...'
                      : widget.contact.isOnline
                          ? 'Online sekarang'
                          : 'Offline',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isTyping
                        ? AppColors.secondary
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textTertiary),
                    fontWeight: isTyping ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, ChatState chatState) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _msgCtrl,
                onChanged: (value) {
                  ref.read(chatProvider.notifier).setTyping(
                        toUserId: widget.contact.userId,
                        isTyping: value.trim().isNotEmpty,
                      );
                },
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Ketik pesan...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: chatState.isLoading ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x555B67F1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }

    _msgCtrl.clear();
    ref.read(chatProvider.notifier).setTyping(
          toUserId: widget.contact.userId,
          isTyping: false,
        );

    try {
      final sent = await ref.read(chatProvider.notifier).sendMessage(
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
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
