import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';

class ChatUserProfileScreen extends StatefulWidget {
  final ChatConversationEntity user;
  final bool allowOpenChat;

  const ChatUserProfileScreen({
    super.key,
    required this.user,
    this.allowOpenChat = true,
  });

  @override
  State<ChatUserProfileScreen> createState() => _ChatUserProfileScreenState();
}

class _ChatUserProfileScreenState extends State<ChatUserProfileScreen> {
  Timer? _clockTicker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    super.dispose();
  }

  DateTime? get _lastSeen {
    if (widget.user.lastSeen != null) {
      return widget.user.lastSeen;
    }
    if (widget.user.updatedAt.year >= 2000) {
      return widget.user.updatedAt;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? lastSeen = _lastSeen;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil User'),
      ),
      body: Stack(
        children: <Widget>[
          _ProfileBackground(isDark: isDark),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.dividerLight,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.22 : 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: widget.user.avatar.trim().isEmpty
                            ? null
                            : NetworkImage(widget.user.avatar),
                        child: widget.user.avatar.trim().isEmpty
                            ? const Icon(Icons.person, size: 34)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.user.username,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: (widget.user.isOnline
                                  ? AppColors.success
                                  : AppColors.primary)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: widget.user.isOnline
                                  ? AppColors.success
                                  : AppColors.primaryDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.user.isOnline
                                  ? 'Online sekarang'
                                  : 'Terakhir dilihat ${_relativeLastSeen(lastSeen)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _InfoTile(
                  icon: Icons.schedule_rounded,
                  title: 'Jam Sekarang',
                  value: _formatClock(_now),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Terakhir Dilihat',
                  value: _absoluteLastSeen(lastSeen),
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.message_rounded,
                  title: 'Pesan Terakhir',
                  value: widget.user.lastMessage.trim().isEmpty
                      ? 'Belum ada pesan'
                      : widget.user.lastMessage,
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                if (widget.allowOpenChat)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.forum_rounded),
                      label: const Text('Buka Percakapan'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Kembali'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatClock(DateTime value) {
    final String h = value.hour.toString().padLeft(2, '0');
    final String m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _absoluteLastSeen(DateTime? value) {
    if (value == null) {
      return 'Tidak tersedia';
    }
    final String date =
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    return '$date ${_formatClock(value)}';
  }

  String _relativeLastSeen(DateTime? value) {
    if (value == null) {
      return 'tidak tersedia';
    }
    final Duration diff = _now.difference(value);
    if (diff.inMinutes < 1) {
      return 'barusan';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    }
    return '${diff.inDays}h lalu';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.dividerLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
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

class _ProfileBackground extends StatelessWidget {
  final bool isDark;

  const _ProfileBackground({required this.isDark});

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
                  AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                  AppColors.secondary.withValues(alpha: isDark ? 0.16 : 0.10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
