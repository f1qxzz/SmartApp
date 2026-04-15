import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smartlife_app/core/config/env_config.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/url_helper.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/theme_provider.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const List<(String value, String label, IconData icon)>
      _genderOptions = <(String, String, IconData)>[
    ('male', 'Laki-laki', Icons.male_rounded),
    ('female', 'Perempuan', Icons.female_rounded),
    ('other', 'Lainnya', Icons.transgender_rounded),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _budgetCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  ProviderSubscription<AuthState>? _authSubscription;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String _selectedGender = '';
  String _syncedSignature = '';
  DateTime _lastSyncedAt = DateTime.now();
  bool _dailyReminderEnabled = false;
  bool _chatNotificationsEnabled = true;
  bool _lowDataModeEnabled = false;
  String _preferenceUserId = '';

  @override
  void initState() {
    super.initState();
    _syncFromUser(ref.read(authProvider).user, force: true);
    _loadLocalPreferences(userId: ref.read(authProvider).user?.id);

    _authSubscription = ref.listenManual<AuthState>(
      authProvider,
      (AuthState? previous, AuthState next) {
        _syncFromUser(next.user);
        final previousUserId = (previous?.user?.id ?? '').trim();
        final nextUserId = (next.user?.id ?? '').trim();
        if (previousUserId != nextUserId) {
          _loadLocalPreferences(userId: next.user?.id, refreshUi: true);
        }

        if (!mounted) {
          return;
        }

        final String? errorMessage = next.errorMessage;
        if (errorMessage != null &&
            errorMessage.isNotEmpty &&
            previous?.errorMessage != errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(authProvider.notifier).clearErrorMessage();
          return;
        }

        final String? successMessage = next.successMessage;
        if (successMessage != null &&
            successMessage.isNotEmpty &&
            previous?.successMessage != successMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(authProvider.notifier).clearSuccessMessage();
        }
      },
    );
  }

  void _loadLocalPreferences({
    String? userId,
    bool refreshUi = false,
  }) {
    final scopedUserId = (userId ?? '').trim();
    final dailyReminderEnabled = HiveService.getUserScopedAppBool(
      HiveBoxes.prefDailyReminder,
      userId: scopedUserId,
      fallback: false,
      fallbackToLegacy: true,
    );
    final chatNotificationsEnabled = HiveService.getUserScopedAppBool(
      HiveBoxes.prefChatNotifications,
      userId: scopedUserId,
      fallback: true,
    );
    final lowDataModeEnabled = HiveService.getUserScopedAppBool(
      HiveBoxes.prefLowDataMode,
      userId: scopedUserId,
      fallback: false,
      fallbackToLegacy: true,
    );

    final changed = _preferenceUserId != scopedUserId ||
        _dailyReminderEnabled != dailyReminderEnabled ||
        _chatNotificationsEnabled != chatNotificationsEnabled ||
        _lowDataModeEnabled != lowDataModeEnabled;

    _preferenceUserId = scopedUserId;
    _dailyReminderEnabled = dailyReminderEnabled;
    _chatNotificationsEnabled = chatNotificationsEnabled;
    _lowDataModeEnabled = lowDataModeEnabled;

    if (refreshUi && changed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final avatarProvider = _resolveAvatar(user);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          _ProfileBackground(isDark: isDark),
          RefreshIndicator(
            onRefresh: _refreshProfile,
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: mediaQuery.padding.top + 14,
                bottom: mediaQuery.padding.bottom + 100,
              ),
              children: <Widget>[
                _TopBar(
                  onRefresh: _refreshProfile,
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                _HeroProfileCard(
                  user: user,
                  avatarProvider: avatarProvider,
                  onTapChangePhoto: _isUploadingPhoto || _isSaving
                      ? null
                      : _pickAndCropProfilePhoto,
                  isUploadingPhoto: _isUploadingPhoto,
                  genderLabel: _genderLabel(_toGenderValue(user.gender)),
                  genderIcon: _genderIcon(_toGenderValue(user.gender)),
                  lastSyncedLabel: _formatLastSynced(_lastSyncedAt),
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                _EditProfileCard(
                  formKey: _formKey,
                  usernameCtrl: _usernameCtrl,
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  budgetCtrl: _budgetCtrl,
                  selectedGender: _selectedGender,
                  onSelectGender: (value) =>
                      setState(() => _selectedGender = value),
                  genderOptions: _genderOptions,
                  isSaving: _isSaving,
                  onSave: _isSaving || _isUploadingPhoto ? null : _saveProfile,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _AccountInsightCard(
                  user: user,
                  genderLabel: _genderLabel(_toGenderValue(user.gender)),
                  genderIcon: _genderIcon(_toGenderValue(user.gender)),
                  isDark: isDark,
                  onCopyUsername: () => _copyToClipboard(
                    label: 'Username',
                    value: user.username,
                  ),
                  onCopyEmail: () => _copyToClipboard(
                    label: 'Email',
                    value: user.email,
                  ),
                ),
                const SizedBox(height: 14),
                _PreferenceCard(
                  isDark: isDark,
                  dailyReminderEnabled: _dailyReminderEnabled,
                  chatNotificationsEnabled: _chatNotificationsEnabled,
                  lowDataModeEnabled: _lowDataModeEnabled,
                  onDailyReminderChanged: _setDailyReminder,
                  onChatNotificationsChanged: _setChatNotifications,
                  onLowDataModeChanged: _setLowDataMode,
                  onToggleTheme: () =>
                      ref.read(appThemeModeProvider.notifier).toggle(),
                ),
                const SizedBox(height: 14),
                _LogoutCard(
                  onLogout: _isSaving || _isUploadingPhoto
                      ? null
                      : () async {
                          await ref.read(authProvider.notifier).logout();
                        },
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                const _AppCredit(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshProfile() async {
    await ref.read(authProvider.notifier).refreshProfile();
    if (mounted) {
      setState(() {
        _lastSyncedAt = DateTime.now();
      });
    }
  }

  void _syncFromUser(UserEntity? user, {bool force = false}) {
    if (user == null) {
      return;
    }

    final signature = _userSignature(user);
    if (!force && signature == _syncedSignature) {
      return;
    }

    _syncedSignature = signature;
    _usernameCtrl.text = user.username;
    _nameCtrl.text = user.name;
    _emailCtrl.text = user.email;
    _budgetCtrl.text = user.monthlyBudget.toStringAsFixed(0);
    _selectedGender = _toGenderValue(user.gender);
    _lastSyncedAt = DateTime.now();

    if (mounted) {
      setState(() {});
    }
  }

  String _userSignature(UserEntity user) {
    return <String>[
      user.id,
      user.username,
      user.name,
      user.email,
      user.gender,
      user.avatar,
      user.monthlyBudget.toString(),
    ].join('|');
  }

  String _toGenderValue(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value == 'male' || value == 'female' || value == 'other') {
      return value;
    }
    if (value == 'laki-laki' || value == 'pria') {
      return 'male';
    }
    if (value == 'perempuan' || value == 'wanita') {
      return 'female';
    }
    return '';
  }

  String _genderLabel(String value) {
    switch (value) {
      case 'male':
        return 'Laki-laki';
      case 'female':
        return 'Perempuan';
      case 'other':
        return 'Lainnya';
      default:
        return '-';
    }
  }

  IconData _genderIcon(String value) {
    switch (value) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      case 'other':
        return Icons.transgender_rounded;
      default:
        return Icons.wc_rounded;
    }
  }

  String _formatLastSynced(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 5) {
      return 'Baru saja';
    }
    if (diff.inMinutes < 1) {
      return '${diff.inSeconds} detik lalu';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} menit lalu';
    }
    return '${diff.inHours} jam lalu';
  }

  ImageProvider<Object>? _resolveAvatar(UserEntity user) {
    final avatar = user.avatar.trim();
    if (avatar.isEmpty) {
      return null;
    }

    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return NetworkImage(avatar);
    }

    if (avatar.startsWith('/')) {
      final absoluteUrl = UrlHelper.toAbsolute(EnvConfig.apiBaseUrl, avatar);
      return NetworkImage(absoluteUrl);
    }

    final localFile = File(avatar);
    if (localFile.existsSync()) {
      return FileImage(localFile);
    }

    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih gender terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            username: _usernameCtrl.text.trim().toLowerCase(),
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            gender: _selectedGender,
            monthlyBudget: double.tryParse(_budgetCtrl.text) ?? 0,
          );
      await _refreshProfile();
    } catch (_) {
      // handled by auth listener
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAndCropProfilePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 82,
      );

      if (pickedFile == null) {
        return;
      }

      final File? croppedAvatar = await _cropAvatar(pickedFile);
      if (croppedAvatar == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proses potong foto gagal atau dibatalkan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isUploadingPhoto = true);
      try {
        await ref.read(authProvider.notifier).changeAvatar(croppedAvatar);
        await _refreshProfile();
      } catch (_) {
        // handled by auth listener
      } finally {
        if (mounted) {
          setState(() => _isUploadingPhoto = false);
        }
      }
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka galeri: ${error.message ?? error.code}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat mengganti foto profile.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<File?> _cropAvatar(XFile pickedFile) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: 'Sesuaikan Foto Profil',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            hideBottomControls: false,
            cropStyle: CropStyle.rectangle,
            aspectRatioPresets: const <CropAspectRatioPresetData>[
              CropAspectRatioPreset.square,
              _InstagramStoryAspectRatioPreset(),
            ],
          ),
          IOSUiSettings(
            title: 'Sesuaikan Foto Profil',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            cropStyle: CropStyle.rectangle,
            aspectRatioPresets: const <CropAspectRatioPresetData>[
              CropAspectRatioPreset.square,
              _InstagramStoryAspectRatioPreset(),
            ],
          ),
        ],
      );

      if (croppedFile == null) {
        return null;
      }
      return File(croppedFile.path);
    } on PlatformException catch (error) {
      debugPrint('[PROFILE][CROP][ERROR] ${error.code}: ${error.message}');
      return null;
    } catch (error) {
      debugPrint('[PROFILE][CROP][ERROR] $error');
      return null;
    }
  }

  Future<void> _copyToClipboard({
    required String label,
    required String value,
  }) async {
    final clean = value.trim();
    if (clean.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: clean));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label berhasil disalin')),
    );
  }

  Future<void> _setDailyReminder(bool value) async {
    setState(() => _dailyReminderEnabled = value);
    await HiveService.putUserScopedAppValue(
      HiveBoxes.prefDailyReminder,
      value,
      userId: ref.read(authProvider).user?.id,
    );
  }

  Future<void> _setLowDataMode(bool value) async {
    setState(() => _lowDataModeEnabled = value);
    await HiveService.putUserScopedAppValue(
      HiveBoxes.prefLowDataMode,
      value,
      userId: ref.read(authProvider).user?.id,
    );
  }

  Future<void> _setChatNotifications(bool value) async {
    setState(() => _chatNotificationsEnabled = value);
    await HiveService.putUserScopedAppValue(
      HiveBoxes.prefChatNotifications,
      value,
      userId: ref.read(authProvider).user?.id,
    );
  }
}

class _InstagramStoryAspectRatioPreset implements CropAspectRatioPresetData {
  const _InstagramStoryAspectRatioPreset();

  @override
  (int, int)? get data => (9, 16);

  @override
  String get name => 'Instagram Story 9:16';
}

class _ProfileBackground extends StatelessWidget {
  final bool isDark;

  const _ProfileBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          ),
        ),
        Positioned(
          top: -140,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.14),
                  AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: isDark ? 0.10 : 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final bool isDark;

  const _TopBar({
    required this.onRefresh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text('Profile Saya', style: AppTextStyles.heading2(context)),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Sinkronkan profile',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
    );
  }
}

class _HeroProfileCard extends StatelessWidget {
  final UserEntity user;
  final ImageProvider<Object>? avatarProvider;
  final VoidCallback? onTapChangePhoto;
  final bool isUploadingPhoto;
  final String genderLabel;
  final IconData genderIcon;
  final String lastSyncedLabel;
  final bool isDark;

  const _HeroProfileCard({
    required this.user,
    required this.avatarProvider,
    required this.onTapChangePhoto,
    required this.isUploadingPhoto,
    required this.genderLabel,
    required this.genderIcon,
    required this.lastSyncedLabel,
    required this.isDark,
  });

  String _avatarInitial(String username) {
    final clean = username.trim();
    if (clean.isEmpty) {
      return '?';
    }
    return clean.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.85),
                AppColors.secondary.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.26 : 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
          Row(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  CircleAvatar(
                    key: ValueKey(user.avatar.isNotEmpty ? user.avatar : user.id),
                    radius: 42,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? Text(
                            _avatarInitial(user.username),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: onTapChangePhoto,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isUploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.primary,
                                size: 16,
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
                    Text(
                      user.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _TagPill(
                icon: Icons.verified_user_rounded,
                label: 'Akun Aktif',
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              ),
              const SizedBox(width: 8),
              _TagPill(
                icon: genderIcon,
                label: genderLabel,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Terakhir sinkron: $lastSyncedLabel',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class _TagPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _TagPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController budgetCtrl;
  final String selectedGender;
  final ValueChanged<String> onSelectGender;
  final List<(String value, String label, IconData icon)> genderOptions;
  final bool isSaving;
  final VoidCallback? onSave;
  final bool isDark;

  const _EditProfileCard({
    required this.formKey,
    required this.usernameCtrl,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.budgetCtrl,
    required this.selectedGender,
    required this.onSelectGender,
    required this.genderOptions,
    required this.isSaving,
    required this.onSave,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Edit Informasi Profile',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Perubahan otomatis tersimpan ke server setelah tombol simpan ditekan.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nama Lengkap',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Masukkan nama lengkap',
                prefixIcon: Icon(Icons.person_rounded, size: 20),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Nama wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Username',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: usernameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Masukkan username',
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
              ),
              validator: (value) {
                final input = value?.trim().toLowerCase() ?? '';
                if (input.isEmpty) {
                  return 'Username wajib diisi';
                }
                final usernameRegex = RegExp(r'^[a-z0-9._]{3,30}$');
                if (!usernameRegex.hasMatch(input)) {
                  return 'Username 3-30 karakter (a-z, 0-9, . _)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Email',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: emailCtrl,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Masukkan email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) {
                  return 'Email wajib diisi';
                }
                final emailRegex =
                    RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
                if (!emailRegex.hasMatch(input)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Budget Bulanan (Rp)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: budgetCtrl,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Masukkan target budget bulanan',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded, size: 20),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Budget wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Gender',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genderOptions.map((option) {
                final bool selected = selectedGender == option.$1;
                return GestureDetector(
                  onTap: () => onSelectGender(option.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.gradientPrimary : null,
                      color: selected
                          ? null
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : AppColors.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          option.$3,
                          size: 14,
                          color: selected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          option.$2,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Simpan Perubahan',
              isLoading: isSaving,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountInsightCard extends StatelessWidget {
  final UserEntity user;
  final String genderLabel;
  final IconData genderIcon;
  final bool isDark;
  final VoidCallback onCopyUsername;
  final VoidCallback onCopyEmail;

  const _AccountInsightCard({
    required this.user,
    required this.genderLabel,
    required this.genderIcon,
    required this.isDark,
    required this.onCopyUsername,
    required this.onCopyEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Ringkasan Akun',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Username',
            value: user.username,
            isDark: isDark,
            actionIcon: Icons.copy_rounded,
            onActionTap: onCopyUsername,
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
            isDark: isDark,
            actionIcon: Icons.copy_rounded,
            onActionTap: onCopyEmail,
          ),
          _InfoRow(
            icon: genderIcon,
            label: 'Gender',
            value: genderLabel,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.actionIcon,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (actionIcon != null && onActionTap != null) ...<Widget>[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    actionIcon,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final bool isDark;
  final bool dailyReminderEnabled;
  final bool chatNotificationsEnabled;
  final bool lowDataModeEnabled;
  final ValueChanged<bool> onDailyReminderChanged;
  final ValueChanged<bool> onChatNotificationsChanged;
  final ValueChanged<bool> onLowDataModeChanged;
  final VoidCallback onToggleTheme;

  const _PreferenceCard({
    required this.isDark,
    required this.dailyReminderEnabled,
    required this.chatNotificationsEnabled,
    required this.onDailyReminderChanged,
    required this.onChatNotificationsChanged,
    required this.lowDataModeEnabled,
    required this.onLowDataModeChanged,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Preferensi Aplikasi',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: dailyReminderEnabled,
            onChanged: onDailyReminderChanged,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primaryDark,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.45),
            title: Text(
              'Reminder Harian',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Simpan preferensi pengingat aktivitas aplikasi.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            value: chatNotificationsEnabled,
            onChanged: onChatNotificationsChanged,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primaryDark,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.45),
            title: Text(
              'Notifikasi Chat',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Terima pemberitahuan saat ada pesan chat baru masuk.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            value: lowDataModeEnabled,
            onChanged: onLowDataModeChanged,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primaryDark,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.45),
            title: Text(
              'Mode Hemat Data',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Kurangi media berat saat jaringan sedang lambat.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            value: isDark,
            onChanged: (bool _) => onToggleTheme(),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primaryDark,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.45),
            title: Text(
              'Mode Gelap (Dark Mode)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Ubah tema aplikasi menjadi gelap untuk kenyamanan mata.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
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

class _LogoutCard extends StatelessWidget {
  final VoidCallback? onLogout;
  final bool isDark;

  const _LogoutCard({
    required this.onLogout,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: OutlinedButton.icon(
        onPressed: onLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Keluar dari Akun'),
      ),
    );
  }
}

class _AppCredit extends StatelessWidget {
  const _AppCredit();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          'SmartLife App',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v1.0.0 • SmartLife Intelligence',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
