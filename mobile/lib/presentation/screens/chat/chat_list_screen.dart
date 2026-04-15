import 'dart:async';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/navigation/app_route.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/chat_provider.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_detail_screen.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_user_profile_screen.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/presentation/providers/reminder_provider.dart';
import 'package:smartlife_app/presentation/screens/reminder/reminder_screen.dart';
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
    final String currentUserId = ref.watch(authProvider).user?.id ?? '';
    final bool isSearchActive = _searchQuery.trim().isNotEmpty;
    final bool lowDataMode = HiveService.getUserScopedAppBool(
      HiveBoxes.prefLowDataMode,
      userId: currentUserId,
      fallback: false,
      fallbackToLegacy: true,
    );

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
                        const SizedBox(height: 16),

                        // Smart Assistant Banner
                        if (!isSearchActive)
                          _SmartAssistantBanner(isDark: isDark),

                        const SizedBox(height: 14),
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
                          padding: EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              LoadingSkeleton(width: 52, height: 52, borderRadius: 26),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LoadingSkeleton(width: 120, height: 16, borderRadius: 4),
                                    SizedBox(height: 8),
                                    LoadingSkeleton(width: double.infinity, height: 12, borderRadius: 4),
                                  ],
                                ),
                              ),
                            ],
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
                            confirmDismiss: (_) =>
                                _confirmDeleteConversation(item),
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
      AppRoute<bool>(
        builder: (_) => ChatUserProfileScreen(
          user: user,
          allowOpenChat: true,
        ),
        beginOffset: const Offset(0.06, 0),
      ),
    );

    if (shouldOpenChat != true || !mounted) {
      return;
    }

    Navigator.push(
      context,
      AppRoute<void>(
        builder: (_) => ChatDetailScreen(contact: user),
        beginOffset: const Offset(0.10, 0),
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
                              key: ValueKey(avatarUrl.isEmpty ? 'default' : avatarUrl),
                              color: isDark ? AppColors.cardDark : Colors.white,
                              child: const Icon(Icons.person_rounded),
                            )
                          : Image.network(
                              avatarUrl,
                              key: ValueKey(avatarUrl),
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
        onTap: () => Navigator.push(
          context,
          AppRoute<void>(
            builder: (_) => ChatDetailScreen(contact: item),
            beginOffset: const Offset(0.10, 0),
          ),
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              child: Row(
                children: <Widget>[
                  // Circle Avatar
                  Stack(
                    children: <Widget>[
                      InkWell(
                        onTap: onProfileTap,
                        borderRadius: BorderRadius.circular(24),
                        child: CircleAvatar(
                          key: ValueKey(item.avatar.isNotEmpty ? item.avatar : item.userId),
                          radius: 24,
                          backgroundColor: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          backgroundImage: lowDataMode || item.avatar.isEmpty
                              ? null
                              : NetworkImage(item.avatar),
                          child: lowDataMode || item.avatar.isEmpty
                              ? Icon(Icons.person_rounded,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                  size: 22)
                              : null,
                        ),
                      ),
                      if (item.isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
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
                  const SizedBox(width: 14),
                  // Content
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
                                  fontSize: 15,
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
                                    : FontWeight.w400,
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
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (item.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.gradientPrimary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
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
            // Subtle divider
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 62,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt, DateTime now) {
    if (dt.year < 2000) {
      return '';
    }
    final Duration diff = now.difference(dt);
    // Same day: show HH:mm
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    // Yesterday
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Kemarin';
    }
    if (diff.inDays < 7) {
      const List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}/${dt.year % 100}';
  }
}

class _SmartAssistantBanner extends ConsumerWidget {
  final bool isDark;

  const _SmartAssistantBanner({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderState = ref.watch(reminderProvider);
    final upcoming =
        reminderState.reminders.where((r) => !r.isCompleted).toList();

    if (upcoming.isEmpty) {
      return const SizedBox.shrink();
    }

    final nextReminder = upcoming.first;
    final isOverdue = nextReminder.isOverdue;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppRoute<void>(
          builder: (_) => const ReminderScreen(),
          beginOffset: const Offset(0, 0.06),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isOverdue
              ? LinearGradient(colors: [
                  Colors.red.withValues(alpha: 0.1),
                  Colors.red.withValues(alpha: 0.02)
                ])
              : LinearGradient(
                  begin: AppColors.gradientPrimary.begin,
                  end: AppColors.gradientPrimary.end,
                  colors: AppColors.gradientPrimary.colors
                      .map((c) => c.withValues(alpha: 0.08))
                      .toList(),
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOverdue
                ? Colors.red.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOverdue
                    ? Icons.priority_high_rounded
                    : Icons.auto_awesome_rounded,
                size: 20,
                color: isOverdue ? Colors.red : AppColors.primary,
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                    duration: 2.seconds,
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOverdue ? 'Terlewatkan!' : 'Pengingat Berikutnya',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: isOverdue ? Colors.red : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextReminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(nextReminder.dateTime),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: isDark ? Colors.white24 : Colors.black26),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return AppFormatters.timeOnly(dt);
    }
    return DateFormat('dd/MM').format(dt);
  }
}
