import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/presentation/providers/chat_provider.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_detail_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).refreshAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider);

    final List<ChatConversationEntity> combined = _combineConversationsAndContacts(
      chatState.conversations,
      chatState.contacts,
    );

    final List<ChatConversationEntity> filtered = combined.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(query) ||
          item.lastMessage.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            style: GoogleFonts.inter(fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Cari chat...',
                              prefixIcon: Icon(Icons.search_rounded, size: 20),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Messages', style: AppTextStyles.heading2(context)),
                              Text(
                                '${combined.where((c) => c.unreadCount > 0).length} pesan belum dibaca',
                                style: AppTextStyles.caption(context),
                              ),
                            ],
                          ),
                  ),
                  Row(
                    children: <Widget>[
                      _AppBarIcon(
                        icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
                        onTap: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchCtrl.clear();
                              _searchQuery = '';
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _AppBarIcon(
                        icon: Icons.refresh_rounded,
                        onTap: () => ref.read(chatProvider.notifier).refreshAll(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: chatState.contacts.length,
                itemBuilder: (_, int i) {
                  final contact = chatState.contacts[i];
                  return _StoryItem(
                    name: contact.name.split(' ').first,
                    avatarUrl: contact.avatar,
                    isOnline: contact.isOnline,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
            ),
            Expanded(
              child: chatState.isLoading && filtered.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Tidak ada chat yang cocok dengan pencarian kamu.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(context),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(chatProvider.notifier).refreshAll(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (_, int i) {
                              final contact = filtered[i];
                              return _ChatTile(contact: contact)
                                  .animate()
                                  .fadeIn(delay: (50 * i).ms, duration: 300.ms)
                                  .slideX(begin: 0.1, end: 0);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<ChatConversationEntity> _combineConversationsAndContacts(
    List<ChatConversationEntity> conversations,
    List<ChatConversationEntity> contacts,
  ) {
    final byId = <String, ChatConversationEntity>{
      for (final item in conversations) item.contactId: item,
    };

    for (final contact in contacts) {
      byId.putIfAbsent(
        contact.contactId,
        () => contact,
      );
    }

    final result = byId.values.toList()
      ..sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
    return result;
  }
}

class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final bool isOnline;

  const _StoryItem({
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isOnline ? Border.all(color: AppColors.secondary, width: 2.5) : null,
            ),
            child: avatarUrl.isEmpty
                ? const CircleAvatar(child: Icon(Icons.person))
                : ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 60,
            child: Text(
              name,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatConversationEntity contact;

  const _ChatTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ChatDetailScreen(contact: contact),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: contact.unreadCount > 0
              ? AppColors.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: <Widget>[
            Stack(
              children: <Widget>[
                CircleAvatar(
                  radius: 26,
                  backgroundImage: contact.avatar.isEmpty ? null : NetworkImage(contact.avatar),
                  child: contact.avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
                if (contact.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.backgroundDark : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        contact.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight:
                              contact.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatTime(contact.lastTimestamp),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: contact.unreadCount > 0
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          contact.lastMessage.isEmpty
                              ? 'Belum ada pesan'
                              : contact.lastMessage,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: contact.unreadCount > 0
                                ? (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary)
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary),
                            fontWeight:
                                contact.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${contact.unreadCount}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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

  String _formatTime(DateTime dt) {
    if (dt.year < 2000) {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
