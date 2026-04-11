import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();
  bool _sendingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(chatProvider.notifier).loadMessages(widget.contact.contactId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
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
    final List<ChatMessageEntity> messages =
        ref.read(chatProvider.notifier).messagesOf(widget.contact.contactId);
    final bool isTyping = ref.read(chatProvider.notifier).isTypingFrom(widget.contact.contactId);

    return Scaffold(
      body: Column(
        children: <Widget>[
          _buildAppBar(isDark, isTyping),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          child:
                              widget.contact.avatar.isEmpty ? const Icon(Icons.person) : null,
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
                  imageUrl: msg.image,
                  isMe: msg.senderId == currentUserId,
                  timestamp: msg.timestamp,
                  isRead: msg.readStatus,
                  avatarUrl: msg.senderId == currentUserId ? null : widget.contact.avatar,
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
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
                backgroundImage:
                    widget.contact.avatar.isEmpty ? null : NetworkImage(widget.contact.avatar),
                child: widget.contact.avatar.isEmpty ? const Icon(Icons.person) : null,
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
                  widget.contact.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textTertiary),
                    fontWeight: isTyping ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _ActionButton(icon: Icons.videocam_rounded, onTap: () {}),
          const SizedBox(width: 6),
          _ActionButton(icon: Icons.call_rounded, onTap: () {}),
          const SizedBox(width: 6),
          _ActionButton(icon: Icons.more_vert_rounded, onTap: () {}),
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
          GestureDetector(
            onTap: _sendingImage ? null : _pickAndSendImage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _sendingImage ? Icons.hourglass_empty_rounded : Icons.attach_file_rounded,
                size: 20,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      onChanged: (value) {
                        ref.read(chatProvider.notifier).setTyping(
                              toUserId: widget.contact.contactId,
                              isTyping: value.trim().isNotEmpty,
                            );
                      },
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
                    ),
                    onPressed: () {},
                  ),
                ],
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
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
          toUserId: widget.contact.contactId,
          isTyping: false,
        );

    await ref.read(chatProvider.notifier).sendMessage(
          receiverId: widget.contact.contactId,
          text: text,
        );
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) {
      return;
    }

    setState(() => _sendingImage = true);
    try {
      await ref.read(chatProvider.notifier).sendImage(
            receiverId: widget.contact.contactId,
            imageFile: File(picked.path),
          );
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _sendingImage = false);
      }
    }
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}
