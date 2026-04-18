import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/presentation/providers/user_provider.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(userProvider.notifier).fetchUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value);
    ref.read(userProvider.notifier).fetchUsers(search: value);
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
      case 'developer':
        return 'Owner / Dev';
      case 'staff':
      case 'admin':
        return 'Staff / Admin';
      default:
        return 'Regular User';
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
      case 'developer':
        return const Color(0xFFFFD700);
      case 'staff':
      case 'admin':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: Text(
                'Manajemen Tim',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              backgroundColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
              elevation: 0,
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Mesh
          Container(
            color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
          ),
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.1, duration: 4.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FFD1).withValues(alpha: 0.15),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.05, duration: 5.seconds, curve: Curves.easeInOut),
          ),
          
          Column(
            children: [
              SizedBox(height: topPadding + 60),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Hero(
                  tag: 'search_bar',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearch,
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              icon: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Icon(Icons.search_rounded, 
                                  color: isDark ? Colors.white70 : Colors.black54),
                              ),
                              hintText: 'Cari anggota tim atau email...',
                              hintStyle: GoogleFonts.inter(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

              // User List
              Expanded(
                child: state.isLoading && state.users.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () => ref.read(userProvider.notifier).fetchUsers(search: _searchQuery),
                        color: const Color(0xFF6366F1),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: state.users.length,
                          itemBuilder: (context, index) {
                            final user = state.users[index];
                            return _UserCard(
                              user: user,
                              isDark: isDark,
                              roleLabel: _roleLabel(user.role),
                              roleColor: _roleColor(user.role),
                              onTap: () => _showRoleDialog(context, user),
                            ).animate()
                             .fadeIn(delay: (50 * index).ms, duration: 400.ms)
                             .slideX(begin: 0.05);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, UserEntity user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RolePickerSheet(
        user: user,
        onRoleSelected: (role) {
          ref.read(userProvider.notifier).updateRole(user.id, role);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserEntity user;
  final bool isDark;
  final String roleLabel;
  final Color roleColor;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.isDark,
    required this.roleLabel,
    required this.roleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              highlightColor: roleColor.withValues(alpha: 0.1),
              splashColor: roleColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: roleColor.withValues(alpha: 0.15),
                        border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 1.5),
                        image: user.avatar.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(user.avatar),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: user.avatar.isEmpty
                          ? Center(
                              child: Text(
                                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                style: GoogleFonts.poppins(
                                  color: roleColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name.isEmpty ? user.username : user.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Badge Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: roleColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRoleIcon(user.role), 
                            size: 12, 
                            color: roleColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            roleLabel,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    if (role == 'owner' || role == 'developer') return Icons.star_rounded;
    if (role == 'staff' || role == 'admin') return Icons.shield_rounded;
    return Icons.person_rounded;
  }
}

class _RolePickerSheet extends StatelessWidget {
  final UserEntity user;
  final Function(String) onRoleSelected;

  const _RolePickerSheet({required this.user, required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              )
            )
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white30 : Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, size: 24, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah Akses',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '@${user.username}',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),
              _roleOption(context, 'owner', 'Owner / Dev', 'Akses penuh sistem, analitik & manajemen.', const Color(0xFFFFD700), Icons.star_rounded),
              _roleOption(context, 'staff', 'Staff / Admin', 'Akses moderasi chat & kelola pustaka.', const Color(0xFF6366F1), Icons.shield_rounded),
              _roleOption(context, 'user', 'Regular User', 'Akses standar pengguna aplikasi.', const Color(0xFF10B981), Icons.person_rounded),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleOption(BuildContext context, String role, String title, String desc, Color color, IconData icon) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = user.role == role;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onRoleSelected(role),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? color.withValues(alpha: 0.1) : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
              border: Border.all(
                color: isSelected ? color.withValues(alpha: 0.5) : (isDark ? Colors.white10 : Colors.black12),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) 
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle_rounded, color: color, size: 24)
                      .animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
