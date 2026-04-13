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
      ref.read(chatProvider.notifier).refreshChats();
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
    final bool isSearchActive = _searchQuery.trim().isNotEmpty;

    final List<ChatConversationEntity> items =
        isSearchActive ? chatState.searchResults : chatState.chats;

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
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.inter(fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Cari username...',
                              prefixIcon: Icon(Icons.search_rounded, size: 20),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Messages',
                                  style: AppTextStyles.heading2(context)),
                              Text(
                                '${chatState.chats.length} chat tersedia',
                                style: AppTextStyles.caption(context),
                              ),
                            ],
                          ),
                  ),
                  Row(
                    children: <Widget>[
                      _AppBarIcon(
                        icon: _isSearching
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        onTap: _toggleSearch,
                      ),
                      const SizedBox(width: 8),
                      _AppBarIcon(
                        icon: Icons.refresh_rounded,
                        onTap: () =>
                            ref.read(chatProvider.notifier).refreshChats(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: chatState.chats
                    .where((chat) => chat.isOnline)
                    .map(
                      (chat) => _StoryItem(
                        username: chat.username,
                        avatarUrl: chat.avatar,
                        isOnline: chat.isOnline,
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
            ),
            Expanded(
              child: chatState.isLoading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              isSearchActive
                                  ? 'User tidak ditemukan.'
                                  : 'Belum ada pesan',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(context),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(chatProvider.notifier).refreshChats(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: items.length,
                            itemBuilder: (_, int i) {
                              final item = items[i];
                              return _ChatTile(item: item)
                                  .animate()
                                  .fadeIn(delay: (50 * i).ms, duration: 300.ms)
                                  .slideX(begin: 0.08, end: 0);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchCtrl.clear();
        _searchQuery = '';
        ref.read(chatProvider.notifier).searchUsers('');
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    ref.read(chatProvider.notifier).searchUsers(value);
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
  final String username;
  final String avatarUrl;
  final bool isOnline;

  const _StoryItem({
    required this.username,
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
              border: isOnline
                  ? Border.all(color: AppColors.secondary, width: 2.5)
                  : null,
            ),
            child: avatarUrl.isEmpty
                ? const CircleAvatar(child: Icon(Icons.person))
                : ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              username,
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
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
  final ChatConversationEntity item;

  const _ChatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ChatDetailScreen(contact: item),
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
          color: item.unreadCount > 0
              ? AppColors.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: <Widget>[
            Stack(
              children: <Widget>[
                CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      item.avatar.isEmpty ? null : NetworkImage(item.avatar),
                  child: item.avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
                if (item.isOnline)
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
                          color:
                              isDark ? AppColors.backgroundDark : Colors.white,
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
                        item.username,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: item.unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatTime(item.updatedAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: item.unreadCount > 0
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
                          item.lastMessage.isEmpty
                              ? 'Belum ada pesan'
                              : item.lastMessage,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: item.unreadCount > 0
                                ? (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary)
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary),
                            fontWeight: item.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.unreadCount}',
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
