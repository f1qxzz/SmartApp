import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/url_helper.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/chat_provider.dart';

final _publicProfileProvider =
    FutureProvider.autoDispose.family<UserEntity?, String>((ref, userId) async {
  return ref.read(authProvider.notifier).getPublicProfile(userId);
});

class ChatUserProfileScreen extends ConsumerWidget {
  final ChatConversationEntity user;
  final bool allowOpenChat;

  const ChatUserProfileScreen({
    super.key,
    required this.user,
    this.allowOpenChat = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ChatConversationEntity liveUser = ref.watch(
      chatProvider.select((chatState) {
        for (final ChatConversationEntity item in chatState.chats) {
          if (item.userId == user.userId) {
            return item;
          }
        }
        for (final ChatConversationEntity item in chatState.searchResults) {
          if (item.userId == user.userId) {
            return item;
          }
        }
        return user;
      }),
    );
    final AsyncValue<UserEntity?> profileAsync =
        ref.watch(_publicProfileProvider(user.userId));
    final UserEntity? profile = profileAsync.asData?.value;
    final DateTime? lastSeen = _resolveLastSeen(liveUser);
    final String displayName = _resolveDisplayName(liveUser, profile);
    final String roleLabel = _roleLabel(profile?.role ?? liveUser.role);
    final Color roleColor = _roleColor(profile?.role ?? liveUser.role);
    final bool hasVerifiedBadge = _isVerified(profile?.role ?? liveUser.role);
    final String genderLabel = _genderLabel(profile?.gender ?? '');
    final IconData genderIcon = _genderIcon(profile?.gender ?? '');
    final List<_SocialMediaItem> socialItems = _buildSocialItems(profile);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Profil User',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: Stack(
        children: <Widget>[
          _ProfileBackground(isDark: isDark),
          SafeArea(
            child: StreamBuilder<DateTime>(
              initialData: DateTime.now(),
              stream: Stream<DateTime>.periodic(
                const Duration(seconds: 15),
                (_) => DateTime.now(),
              ),
              builder: (context, snapshot) {
                final DateTime now = snapshot.data ?? DateTime.now();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).padding.bottom + 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _HeroProfileCard(
                        isDark: isDark,
                        avatarUrl: liveUser.avatar.trim(),
                        displayName: displayName,
                        username: liveUser.username,
                        roleLabel: roleLabel,
                        roleColor: roleColor,
                        hasVerifiedBadge: hasVerifiedBadge,
                        lastSeenLabel: liveUser.isOnline
                            ? 'Online'
                            : _relativeLastSeen(lastSeen, now),
                        loading: profileAsync.isLoading,
                      ),
                      const SizedBox(height: 18),
                      _InfoTile(
                        icon: Icons.badge_rounded,
                        title: 'Display Name',
                        value: displayName,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _InfoTile(
                        icon: genderIcon,
                        title: 'Gender',
                        value: genderLabel,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _InfoTile(
                        icon: Icons.history_toggle_off_rounded,
                        title: 'Terakhir Dilihat',
                        value: liveUser.isOnline
                            ? 'Sedang online'
                            : _lastSeenDetail(lastSeen, now),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),
                      _SocialMediaCard(
                        isDark: isDark,
                        items: socialItems,
                      ),
                      if (profileAsync.hasError) ...<Widget>[
                        const SizedBox(height: 14),
                        _InlineNotice(
                          isDark: isDark,
                          icon: Icons.info_outline_rounded,
                          message:
                              'Detail profil tambahan belum berhasil dimuat. Tampilan menggunakan data chat yang tersedia.',
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (allowOpenChat)
                        _PrimaryActionButton(
                          label: 'Buka Percakapan',
                          icon: Icons.forum_rounded,
                          onTap: () => Navigator.of(context).pop(true),
                        )
                      else
                        _SecondaryActionButton(
                          label: 'Kembali',
                          onTap: () => Navigator.of(context).maybePop(),
                          isDark: isDark,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroProfileCard extends StatelessWidget {
  final bool isDark;
  final String avatarUrl;
  final String displayName;
  final String username;
  final String roleLabel;
  final Color roleColor;
  final bool hasVerifiedBadge;
  final String lastSeenLabel;
  final bool loading;

  const _HeroProfileCard({
    required this.isDark,
    required this.avatarUrl,
    required this.displayName,
    required this.username,
    required this.roleLabel,
    required this.roleColor,
    required this.hasVerifiedBadge,
    required this.lastSeenLabel,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDark
        ? AppColors.cardDark.withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.92);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.75),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  roleColor.withValues(alpha: 0.26),
                  roleColor.withValues(alpha: 0.08),
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: roleColor.withValues(alpha: 0.20),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.surfaceDark : Colors.white,
              ),
              child: CircleAvatar(
                backgroundColor: roleColor.withValues(alpha: 0.12),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        _initials(displayName, username),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: roleColor,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasVerifiedBadge) ...<Widget>[
                const SizedBox(width: 6),
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: roleColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '@$username',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _PillBadge(
                icon: Icons.workspace_premium_rounded,
                label: roleLabel,
                color: roleColor,
              ),
              _PillBadge(
                icon: lastSeenLabel == 'Online'
                    ? Icons.circle_rounded
                    : Icons.schedule_rounded,
                label: lastSeenLabel,
                color: lastSeenLabel == 'Online'
                    ? AppColors.success
                    : AppColors.primary,
              ),
              if (loading)
                const _PillBadge(
                  icon: Icons.sync_rounded,
                  label: 'Memuat',
                  color: AppColors.info,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.72),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialMediaCard extends StatelessWidget {
  final bool isDark;
  final List<_SocialMediaItem> items;

  const _SocialMediaCard({
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.72),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Social Media',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: items
                .map(
                  (item) => _SocialIconButton(
                    item: item,
                    isDark: isDark,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final _SocialMediaItem item;
  final bool isDark;

  const _SocialIconButton({
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = item.value.trim().isNotEmpty;

    return InkWell(
      onTap: () async {
        if (!isEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.platform} belum tersedia.'),
            ),
          );
          return;
        }

        final bool success =
            await UrlHelper.launchSocialUrl(item.platform, item.value);
        if (!context.mounted || success) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka ${item.platform}.'),
          ),
        );
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isEnabled ? 1 : 0.45,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: item.color.withValues(alpha: isDark ? 0.20 : 0.14),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: item.color.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: item.isInstagram
                ? Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: <Color>[
                          Color(0xFF405DE6),
                          Color(0xFFC13584),
                          Color(0xFFFD1D1D),
                          Color(0xFFF77737),
                          Color(0xFFFCAF45),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  )
                : FaIcon(
                    item.icon,
                    size: 20,
                    color: item.color,
                  ),
          ),
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PillBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;

  const _InlineNotice({
    required this.isDark,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _SecondaryActionButton({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : AppColors.dividerLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: isDark
              ? AppColors.cardDark.withValues(alpha: 0.76)
              : Colors.white.withValues(alpha: 0.78),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  final bool isDark;

  const _ProfileBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? <Color>[
                  const Color(0xFF0F172A),
                  const Color(0xFF16233F),
                  const Color(0xFF182944),
                ]
              : <Color>[
                  const Color(0xFFF6F9FF),
                  const Color(0xFFEFF4FF),
                  const Color(0xFFF7F9FC),
                ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -70,
            right: -40,
            child: _BackgroundOrb(
              size: 210,
              color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.16),
            ),
          ),
          Positioned(
            top: 180,
            left: -70,
            child: _BackgroundOrb(
              size: 170,
              color:
                  AppColors.secondary.withValues(alpha: isDark ? 0.18 : 0.18),
            ),
          ),
          Positioned(
            bottom: -60,
            right: 20,
            child: _BackgroundOrb(
              size: 180,
              color: AppColors.info.withValues(alpha: isDark ? 0.16 : 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialMediaItem {
  final String platform;
  final String value;
  final dynamic icon;
  final Color color;
  final bool isInstagram;

  const _SocialMediaItem({
    required this.platform,
    required this.value,
    this.icon,
    required this.color,
    this.isInstagram = false,
  });
}

DateTime? _resolveLastSeen(ChatConversationEntity user) {
  if (user.lastSeen != null) {
    return user.lastSeen;
  }
  if (user.updatedAt.year >= 2000) {
    return user.updatedAt;
  }
  return null;
}

String _resolveDisplayName(ChatConversationEntity user, UserEntity? profile) {
  final String fromProfile = (profile?.name ?? '').trim();
  if (fromProfile.isNotEmpty) {
    return fromProfile;
  }
  return user.username;
}

bool _isVerified(String role) {
  switch (role) {
    case 'owner':
    case 'developer':
    case 'staff':
    case 'admin':
      return true;
    default:
      return false;
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'owner':
      return 'Owner';
    case 'developer':
      return 'Developer';
    case 'staff':
      return 'Staff';
    case 'admin':
      return 'Admin';
    default:
      return 'Member';
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'owner':
      return const Color(0xFFF4B000);
    case 'developer':
      return const Color(0xFF596CFF);
    case 'staff':
      return const Color(0xFF2F80ED);
    case 'admin':
      return const Color(0xFF4B67D1);
    default:
      return AppColors.primary;
  }
}

String _genderLabel(String gender) {
  switch (gender.trim().toLowerCase()) {
    case 'male':
      return 'Laki-laki';
    case 'female':
      return 'Perempuan';
    case 'other':
      return 'Lainnya';
    default:
      return 'Tidak diatur';
  }
}

IconData _genderIcon(String gender) {
  switch (gender.trim().toLowerCase()) {
    case 'male':
      return Icons.male_rounded;
    case 'female':
      return Icons.female_rounded;
    case 'other':
      return Icons.transgender_rounded;
    default:
      return Icons.person_outline_rounded;
  }
}

String _relativeLastSeen(DateTime? value, DateTime now) {
  if (value == null) {
    return 'Tidak tersedia';
  }

  final Duration diff = now.difference(value);
  if (diff.inMinutes < 1) {
    return 'Barusan';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m lalu';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}j lalu';
  }
  return '${diff.inDays}h lalu';
}

String _absoluteLastSeen(DateTime? value) {
  if (value == null) {
    return 'Tidak tersedia';
  }

  final String day = value.day.toString().padLeft(2, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String year = value.year.toString();
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String _lastSeenDetail(DateTime? value, DateTime now) {
  if (value == null) {
    return 'Tidak tersedia';
  }
  return '${_relativeLastSeen(value, now)} - ${_absoluteLastSeen(value)}';
}

String _initials(String displayName, String username) {
  final List<String> nameParts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (nameParts.length >= 2) {
    return '${nameParts.first[0]}${nameParts[1][0]}'.toUpperCase();
  }

  if (nameParts.length == 1 && nameParts.first.isNotEmpty) {
    return nameParts.first.substring(0, 1).toUpperCase();
  }

  if (username.trim().isNotEmpty) {
    return username.trim().substring(0, 1).toUpperCase();
  }

  return '?';
}

List<_SocialMediaItem> _buildSocialItems(UserEntity? profile) {
  return <_SocialMediaItem>[
    _SocialMediaItem(
      platform: 'GitHub',
      value: profile?.socialGithub ?? '',
      icon: FontAwesomeIcons.github,
      color: const Color(0xFF64748B),
    ),
    _SocialMediaItem(
      platform: 'Instagram',
      value: profile?.socialInstagram ?? '',
      color: const Color(0xFFE879A6),
      isInstagram: true,
    ),
    _SocialMediaItem(
      platform: 'Discord',
      value: profile?.socialDiscord ?? '',
      icon: FontAwesomeIcons.discord,
      color: const Color(0xFF7289DA),
    ),
    _SocialMediaItem(
      platform: 'Telegram',
      value: profile?.socialTelegram ?? '',
      icon: FontAwesomeIcons.telegram,
      color: const Color(0xFF5CA9FF),
    ),
    _SocialMediaItem(
      platform: 'Spotify',
      value: profile?.socialSpotify ?? '',
      icon: FontAwesomeIcons.spotify,
      color: const Color(0xFF53D27C),
    ),
  ];
}
