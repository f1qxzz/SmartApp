import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/presentation/providers/chat_provider.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_detail_screen.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_user_profile_screen.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  Timer? _clockTicker;
  String _searchQuery = '';
  bool _showUnreadOnly = false;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).refreshChats();
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
    _searchDebounce?.cancel();
    _clockTicker?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ChatState chatState = ref.watch(chatProvider);
    final bool isSearchActive = _searchQuery.trim().isNotEmpty;
    final bool lowDataMode =
        (HiveService.appBox.get(HiveBoxes.prefLowDataMode) as bool?) ?? false;

    final List<ChatConversationEntity> sourceItems =
        isSearchActive ? chatState.searchResults : chatState.chats;
    final List<ChatConversationEntity> items = _showUnreadOnly
        ? sourceItems
            .where((ChatConversationEntity chat) => chat.unreadCount > 0)
            .toList()
        : sourceItems;
    final List<ChatConversationEntity> onlineUsers =
        chatState.chats.where((chat) => chat.isOnline).toList();

    return Scaffold(
      body: Stack(
        children: <Widget>[
          _ChatBackground(isDark: isDark),
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(chatProvider.notifier).refreshChats(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 14,
                      left: 20,
                      right: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Messages',
                                    style: AppTextStyles.heading2(context),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${chatState.chats.length} percakapan',
                                    style: AppTextStyles.caption(context),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sekarang ${_formatClock(_currentTime)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _HeaderIcon(
                              icon: Icons.close_rounded,
                              isVisible: isSearchActive,
                              onTap: _clearSearch,
                            ),
                            const SizedBox(width: 8),
                            _HeaderIcon(
                              icon: Icons.refresh_rounded,
                              onTap: () => ref
                                  .read(chatProvider.notifier)
                                  .refreshChats(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : AppColors.dividerLight,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.25 : 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Cari username untuk mulai chat...',
                              border: InputBorder.none,
                              filled: false,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
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
                        const SizedBox(height: 14),
                        _ChatStatsStrip(
                          totalChats: chatState.chats.length,
                          onlineCount: onlineUsers.length,
                          searchLabel: isSearchActive
                              ? '${items.length} hasil'
                              : 'Semua chat',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            _FilterToggleChip(
                              icon: Icons.mark_chat_unread_rounded,
                              label: 'Belum dibaca',
                              isActive: _showUnreadOnly,
                              onTap: () {
                                setState(() {
                                  _showUnreadOnly = !_showUnreadOnly;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterToggleChip(
                              icon: Icons.forum_rounded,
                              label:
                                  isSearchActive ? 'Mode Cari' : 'Semua Chat',
                              isActive: !_showUnreadOnly,
                              onTap: () {
                                if (_showUnreadOnly) {
                                  setState(() {
                                    _showUnreadOnly = false;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        if (onlineUsers.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 16),
                          Text(
                            'Online Sekarang',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 92,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: onlineUsers.length,
                              itemBuilder: (_, int index) {
                                final chat = onlineUsers[index];
                                return _OnlineUserChip(
                                  username: chat.username,
                                  avatarUrl: chat.avatar,
                                  lowDataMode: lowDataMode,
                                  onTap: () => _openUserProfilePage(chat),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (chatState.isLoading && items.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: LoadingSkeleton(
                            width: double.infinity,
                            height: 84,
                            borderRadius: 16,
                          ),
                        ),
                        childCount: 5,
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : AppColors.dividerLight,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                isSearchActive
                                    ? Icons.search_off_rounded
                                    : Icons.chat_bubble_outline_rounded,
                                size: 30,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isSearchActive
                                    ? 'Username tidak ditemukan.'
                                    : 'Belum ada percakapan.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, int index) {
                          final item = items[index];
                          return Dismissible(
                            key: Key('chat_${item.chatId}_${item.userId}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDeleteConversation(item),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.delete_forever_rounded,
                                  color: Colors.red),
                            ),
                            child: _ConversationCard(
                              item: item,
                              lowDataMode: lowDataMode,
                              now: _currentTime,
                              onProfileTap: () => _openUserProfilePage(item),
                            )
                                .animate()
                                .fadeIn(
                                  delay: (40 * index).ms,
                                  duration: 300.ms,
                                )
                                .slideX(begin: 0.05, end: 0),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _searchQuery = '');
    ref.read(chatProvider.notifier).searchUsers('');
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();

    if (value.trim().isEmpty) {
      ref.read(chatProvider.notifier).searchUsers('');
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      ref.read(chatProvider.notifier).searchUsers(value);
    });
  }

  String _formatClock(DateTime value) {
    final String h = value.hour.toString().padLeft(2, '0');
    final String m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openUserProfilePage(ChatConversationEntity user) async {
    final bool? shouldOpenChat = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ChatUserProfileScreen(
          user: user,
          allowOpenChat: true,
        ),
      ),
    );

    if (shouldOpenChat != true || !mounted) {
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChatDetailScreen(contact: user),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<bool?> _confirmDeleteConversation(ChatConversationEntity item) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Percakapan?'),
        content: Text(
            'Hapus percakapan dengan ${item.username}? Semua pesan akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await ref
                  .read(chatProvider.notifier)
                  .deleteConversation(item.chatId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ChatBackground extends StatelessWidget {
  final bool isDark;

  const _ChatBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                  AppColors.secondary.withValues(alpha: isDark ? 0.16 : 0.08),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isVisible;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : AppColors.dividerLight,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ChatStatsStrip extends StatelessWidget {
  final int totalChats;
  final int onlineCount;
  final String searchLabel;
  final bool isDark;

  const _ChatStatsStrip({
    required this.totalChats,
    required this.onlineCount,
    required this.searchLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTag(
            icon: Icons.forum_rounded,
            text: '$totalChats chat',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTag(
            icon: Icons.circle,
            iconColor: AppColors.secondary,
            text: '$onlineCount online',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTag(
            icon: Icons.search_rounded,
            text: searchLabel,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatTag extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;
  final bool isDark;

  const _StatTag({
    required this.icon,
    this.iconColor,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.09)
              : AppColors.dividerLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: icon == Icons.circle ? 10 : 14,
            color: iconColor ?? AppColors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterToggleChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.gradientPrimary : null,
            color:
                isActive ? null : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.dividerLight),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineUserChip extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final bool lowDataMode;
  final VoidCallback? onTap;

  const _OnlineUserChip({
    required this.username,
    required this.avatarUrl,
    this.lowDataMode = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: <Widget>[
            Stack(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF7C7E9D), Color(0xFF949AB1)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: lowDataMode || avatarUrl.isEmpty
                          ? Container(
                              color: isDark ? AppColors.cardDark : Colors.white,
                              child: const Icon(Icons.person_rounded),
                            )
                          : Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color:
                                    isDark ? AppColors.cardDark : Colors.white,
                                child: const Icon(Icons.person_rounded),
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ChatConversationEntity item;
  final bool lowDataMode;
  final DateTime now;
  final VoidCallback onProfileTap;

  const _ConversationCard({
    required this.item,
    this.lowDataMode = false,
    required this.now,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ChatDetailScreen(contact: item),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.unreadCount > 0
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.dividerLight),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  InkWell(
                    onTap: onProfileTap,
                    borderRadius: BorderRadius.circular(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: lowDataMode || item.avatar.isEmpty
                            ? Container(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
                                child: const Icon(Icons.person_rounded),
                              )
                            : Image.network(
                                item.avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceLight,
                                  child: const Icon(Icons.person_rounded),
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (item.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            width: 2,
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: item.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(item.updatedAt, now),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: item.unreadCount > 0
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary),
                            fontWeight: item.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.lastMessage.isEmpty
                                ? 'Mulai percakapan baru'
                                : item.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: item.unreadCount > 0
                                  ? (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary)
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                              fontWeight: item.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.unreadCount}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
      ),
    );
  }

  String _formatTime(DateTime dt, DateTime now) {
    if (dt.year < 2000) {
      return '';
    }
    final Duration diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return 'now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d';
    }
    return '${dt.day}/${dt.month}';
  }
}
