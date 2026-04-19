import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/navigation/app_route.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/chat_provider.dart';
import 'package:smartlife_app/presentation/providers/reminder_provider.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_detail_screen.dart';
import 'package:smartlife_app/presentation/screens/chat/chat_user_profile_screen.dart';
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
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).refreshChats();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ChatState chatState = ref.watch(chatProvider);
    final String currentUserId = ref.watch(authProvider).user?.id ?? '';
    final bool lowDataMode = HiveService.getUserScopedAppBool(
      HiveBoxes.prefLowDataMode,
      userId: currentUserId,
      fallback: false,
      fallbackToLegacy: true,
    );
    final bool isSearching = chatState.searchKeyword.trim().isNotEmpty;
    final List<ChatConversationEntity> sourceItems =
        isSearching ? chatState.searchResults : chatState.chats;
    final List<ChatConversationEntity> items = _showUnreadOnly
        ? sourceItems
            .where((ChatConversationEntity item) => item.unreadCount > 0)
            .toList()
        : sourceItems;
    final List<ChatConversationEntity> onlineUsers = chatState.chats
        .where((ChatConversationEntity item) => item.isOnline)
        .toList();
    final int unreadCount = chatState.chats.fold<int>(
      0,
      (int total, ChatConversationEntity item) => total + item.unreadCount,
    );
    final int pendingReminders = ref
        .watch(reminderProvider)
        .reminders
        .where((reminder) => !reminder.isCompleted)
        .length;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          FluidBackground(isDark: isDark),
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(chatProvider.notifier).refreshChats(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _ChatHero(
                            isDark: isDark,
                            unreadCount: unreadCount,
                            pendingReminders: pendingReminders,
                            onOpenReminders: _openReminderScreen,
                          ).animate().fadeIn(duration: 450.ms),
                          const SizedBox(height: 16),
                          _buildSearchBar(isDark)
                              .animate()
                              .fadeIn(delay: 80.ms, duration: 450.ms),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _FilterChip(
                                  isDark: isDark,
                                  icon: Icons.inbox_rounded,
                                  label: isSearching
                                      ? '${items.length} hasil'
                                      : 'Semua chat',
                                  isActive: !_showUnreadOnly,
                                  onTap: () {
                                    if (_showUnreadOnly) {
                                      setState(() => _showUnreadOnly = false);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _FilterChip(
                                  isDark: isDark,
                                  icon: Icons.mark_chat_unread_rounded,
                                  label: 'Belum dibaca',
                                  badge: unreadCount > 0 ? unreadCount : null,
                                  isActive: _showUnreadOnly,
                                  onTap: () {
                                    setState(() {
                                      _showUnreadOnly = !_showUnreadOnly;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 140.ms, duration: 450.ms),
                          if (onlineUsers.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 18),
                            Text(
                              'Sedang Online',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 88,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: onlineUsers.length,
                                itemBuilder: (context, index) {
                                  final ChatConversationEntity item =
                                      onlineUsers[index];
                                  return _OnlineUserChip(
                                    item: item,
                                    lowDataMode: lowDataMode,
                                    onTap: () => _openConversation(item),
                                  );
                                },
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 450.ms),
                          ],
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                if (chatState.isLoading && chatState.chats.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LoadingSkeleton(
                            width: double.infinity,
                            height: 92,
                            borderRadius: 24,
                          ),
                        ),
                        childCount: 6,
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      isDark: isDark,
                      isSearching: isSearching,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ChatConversationEntity item = items[index];
                          return _ConversationCard(
                            item: item,
                            lowDataMode: lowDataMode,
                            isDark: isDark,
                            onOpen: () => _openConversation(item),
                            onOpenProfile: () => _openProfile(item),
                          ).animate().fadeIn(
                                delay: (index * 40).ms,
                                duration: 350.ms,
                              );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return ModernGlassCard(
      isDark: isDark,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.search_rounded,
            size: 18,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cari orang atau percakapan...',
                border: InputBorder.none,
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            ),
          ),
          if (_searchCtrl.text.trim().isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      ref.read(chatProvider.notifier).searchUsers(value);
      setState(() {});
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    ref.read(chatProvider.notifier).searchUsers('');
    setState(() {});
  }

  Future<void> _openConversation(ChatConversationEntity item) async {
    if (!item.hasChat) {
      _openProfile(item);
      return;
    }

    await Navigator.push<void>(
      context,
      AppRoute<void>(
        builder: (_) => ChatDetailScreen(contact: item),
        beginOffset: const Offset(0.08, 0),
      ),
    );
  }

  Future<void> _openProfile(ChatConversationEntity item) async {
    await Navigator.push<void>(
      context,
      AppRoute<void>(
        builder: (_) => ChatUserProfileScreen(user: item),
        beginOffset: const Offset(0.08, 0),
      ),
    );
  }

  Future<void> _openReminderScreen() async {
    await Navigator.push<void>(
      context,
      AppRoute<void>(builder: (_) => const ReminderScreen()),
    );
  }
}

class _ChatHero extends StatelessWidget {
  final bool isDark;
  final int unreadCount;
  final int pendingReminders;
  final VoidCallback onOpenReminders;

  const _ChatHero({
    required this.isDark,
    required this.unreadCount,
    required this.pendingReminders,
    required this.onOpenReminders,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      isDark: isDark,
      borderRadius: 32,
      padding: const EdgeInsets.all(22),
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
                      'Encrypted Messages',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                        color: isDark ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Komunikasi cepat, modern, dan tetap rapi untuk aktivitas harian kamu.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              TopBarAction(
                icon: Icons.notifications_active_rounded,
                onPressed: onOpenReminders,
                isDark: isDark,
                tooltip: 'Buka pengingat',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroMetric(
                  isDark: isDark,
                  icon: Icons.mark_chat_unread_rounded,
                  label: 'Unread',
                  value: '$unreadCount',
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  isDark: isDark,
                  icon: Icons.schedule_rounded,
                  label: 'Reminders',
                  value: '$pendingReminders',
                  accent: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _HeroMetric({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final int? badge;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.isDark,
    required this.icon,
    required this.label,
    this.badge,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.gradientPrimary : null,
            color: isActive
                ? null
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white54 : AppColors.primaryDark),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white70 : AppColors.textSecondary),
                  ),
                ),
              ),
              if (badge != null && badge! > 0) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineUserChip extends StatelessWidget {
  final ChatConversationEntity item;
  final bool lowDataMode;
  final VoidCallback onTap;

  const _OnlineUserChip({
    required this.item,
    required this.lowDataMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: AvatarWidget(
                    url: item.avatar,
                    radius: 24,
                    lowDataMode: lowDataMode,
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF101A31) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ChatConversationEntity item;
  final bool lowDataMode;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onOpenProfile;

  const _ConversationCard({
    required this.item,
    required this.lowDataMode,
    required this.isDark,
    required this.onOpen,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = item.unreadCount > 0;

    return ModernGlassCard(
      isDark: isDark,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                GestureDetector(
                  onTap: onOpenProfile,
                  child: Stack(
                    children: <Widget>[
                      AvatarWidget(
                        url: item.avatar,
                        radius: 28,
                        lowDataMode: lowDataMode,
                      ),
                      if (item.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF101A31)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
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
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(item.updatedAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.lastMessage.trim().isEmpty
                            ? 'Belum ada pesan. Buka profil untuk mulai percakapan.'
                            : item.lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.5,
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w500,
                          color: hasUnread
                              ? (isDark ? Colors.white : AppColors.textPrimary)
                              : (isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: const BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Text(
                      '${item.unreadCount}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(
                    item.hasChat
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.person_search_rounded,
                    size: 16,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final DateTime now = DateTime.now();
    final bool sameDay =
        now.year == date.year && now.month == date.month && now.day == date.day;
    return sameDay
        ? AppFormatters.timeOnly(date)
        : AppFormatters.relativeDate(date);
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final bool isSearching;

  const _EmptyState({
    required this.isDark,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ModernGlassCard(
          isDark: isDark,
          borderRadius: 30,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isSearching
                    ? 'Pencarian belum menemukan hasil.'
                    : 'Belum ada percakapan aktif.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Coba kata kunci lain atau buka profil user untuk memulai chat baru.'
                    : 'Saat percakapan pertama dibuat, daftar chat akan muncul di sini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
