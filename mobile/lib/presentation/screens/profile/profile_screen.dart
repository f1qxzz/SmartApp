import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:smartlife_app/core/config/env_config.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/url_helper.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';
import 'package:smartlife_app/presentation/providers/theme_provider.dart';
import 'package:smartlife_app/presentation/widgets/reusable_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'staff_management_screen.dart';

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
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  DateTime? _selectedDOB;
  final ImagePicker _imagePicker = ImagePicker();

  ProviderSubscription<AuthState>? _authSubscription;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _showAdvancedProfileInfo = false;
  String _selectedGender = '';
  String _syncedSignature = '';
  DateTime _lastSyncedAt = DateTime.now();
  bool _dailyReminderEnabled = false;
  bool _chatNotificationsEnabled = true;
  bool _lowDataModeEnabled = false;
  String _preferenceUserId = '';
  String _socialGithub = '';
  String _socialInstagram = '';
  String _socialDiscord = '';
  String _socialTelegram = '';
  String _socialSpotify = '';
  String _socialTikTok = '';

  @override
  void initState() {
    super.initState();
    _syncFromUser(ref.read(authProvider).user, force: true);
    _loadLocalPreferences(userId: ref.read(authProvider).user?.id);
    _loadSocialLinks(userId: ref.read(authProvider).user?.id);

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
          AppAlert.show(
            context,
            title: 'Ups! Terjadi Kesalahan',
            message: errorMessage,
            isError: true,
          );
          ref.read(authProvider.notifier).clearErrorMessage();
          return;
        }

        final String? successMessage = next.successMessage;
        if (successMessage != null &&
            successMessage.isNotEmpty &&
            previous?.successMessage != successMessage) {
          SmartToast.show(
            context,
            message: successMessage,
            isError: false,
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

  void _loadSocialLinks({String? userId}) {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _socialGithub = user.socialGithub;
      _socialInstagram = user.socialInstagram;
      _socialDiscord = user.socialDiscord;
      _socialTelegram = user.socialTelegram;
      _socialSpotify = user.socialSpotify;
      _socialTikTok = user.socialTikTok;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveSocialLinks({
    required String github,
    required String instagram,
    required String discord,
    required String telegram,
    required String spotify,
    required String tiktok,
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    _socialGithub = github;
    _socialInstagram = instagram;
    _socialDiscord = discord;
    _socialTelegram = telegram;
    _socialSpotify = spotify;
    _socialTikTok = tiktok;

    await ref.read(authProvider.notifier).updateProfile(
          username: _usernameCtrl.text.trim().isNotEmpty
              ? _usernameCtrl.text.trim()
              : user.username,
          email: _emailCtrl.text.trim().isNotEmpty
              ? _emailCtrl.text.trim()
              : user.email,
          name: _nameCtrl.text.trim().isNotEmpty
              ? _nameCtrl.text.trim()
              : user.name,
          gender: _selectedGender.isNotEmpty ? _selectedGender : user.gender,
          avatar: user.avatar,
          dateOfBirth: _normalizeDateForApi(user.dateOfBirth),
          socialGithub: github,
          socialInstagram: instagram,
          socialDiscord: discord,
          socialTelegram: telegram,
          socialSpotify: spotify,
          socialTikTok: tiktok,
        );

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _bioCtrl.dispose();
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
    final genderValue = _toGenderValue(user.gender);
    final dobSummaryLabel = _formatDateOfBirth(user.dateOfBirth);
    final bool canManageStaff = user.role == 'owner' ||
        user.role == 'developer' ||
        user.role == 'staff' ||
        user.role == 'admin' ||
        user.role == 'ace_tester';

    return Scaffold(
      body: Stack(
        children: <Widget>[
          FluidBackground(isDark: isDark),
          RefreshIndicator(
            onRefresh: _refreshProfile,
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: mediaQuery.padding.top + 10,
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
                  genderLabel: _genderLabel(genderValue),
                  genderIcon: _genderIcon(genderValue),
                  lastSyncedLabel: _formatLastSynced(_lastSyncedAt),
                  isDark: isDark,
                  socialGithub: _socialGithub,
                  socialInstagram: _socialInstagram,
                  socialDiscord: _socialDiscord,
                  socialTelegram: _socialTelegram,
                  socialSpotify: _socialSpotify,
                  socialTikTok: _socialTikTok,
                  onEditSocialLinks: () =>
                      _showEditSocialLinksBottomSheet(context),
                  onQuickUpdateName: (newName) {
                    ref.read(authProvider.notifier).updateProfile(
                          username: user.username,
                          email: user.email,
                          name: newName,
                          gender: user.gender,
                          avatar: user.avatar,
                          dateOfBirth: _normalizeDateForApi(user.dateOfBirth),
                        );
                  },
                ),
                const SizedBox(height: 18),
                _EditProfileCard(
                  formKey: _formKey,
                  usernameCtrl: _usernameCtrl,
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  bioCtrl: _bioCtrl,
                  selectedGender: _selectedGender,
                  onSelectGender: (value) =>
                      setState(() => _selectedGender = value),
                  genderOptions: _genderOptions,
                  isSaving: _isSaving,
                  onSave: _isSaving || _isUploadingPhoto ? null : _saveProfile,
                  isDark: isDark,
                  dobCtrl: _dobCtrl,
                  onSelectDOB: _selectDOB,
                ),
                const SizedBox(height: 14),
                _CompactProfileMenu(
                  isDark: isDark,
                  showAdvanced: _showAdvancedProfileInfo,
                  onToggleAdvanced: () {
                    setState(() {
                      _showAdvancedProfileInfo = !_showAdvancedProfileInfo;
                    });
                  },
                  onEditSocialLinks: () =>
                      _showEditSocialLinksBottomSheet(context),
                ),
                const SizedBox(height: 14),
                if (_showAdvancedProfileInfo) ...[
                  _AccountInsightCard(
                    user: user,
                    genderLabel: _genderLabel(_toGenderValue(user.gender)),
                    genderIcon: _genderIcon(_toGenderValue(user.gender)),
                    dobLabel: dobSummaryLabel.isEmpty
                        ? 'Belum diisi'
                        : dobSummaryLabel,
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
                  _SocialMediaCard(
                    isDark: isDark,
                    github: _socialGithub,
                    instagram: _socialInstagram,
                    discord: _socialDiscord,
                    telegram: _socialTelegram,
                    spotify: _socialSpotify,
                    tiktok: _socialTikTok,
                    onEdit: () => _showEditSocialLinksBottomSheet(context),
                  ),
                  const SizedBox(height: 14),
                ],
                if (canManageStaff && _showAdvancedProfileInfo) ...[
                  _StaffManagementCard(isDark: isDark),
                  const SizedBox(height: 14),
                ],
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
    _bioCtrl.text = user.bio;
    _selectedGender = _toGenderValue(user.gender);
    _selectedDOB = user.dateOfBirth;
    if (_selectedDOB != null) {
      _dobCtrl.text = _formatDateOfBirth(_selectedDOB);
    } else {
      _dobCtrl.text = '';
    }
    _lastSyncedAt = DateTime.now();

    if (mounted) {
      setState(() {});
    }
  }

  String _userSignature(UserEntity user) {
    return '${user.id}|${user.username}|${user.email}|${user.name}|${user.gender}|${user.avatar}|${user.dateOfBirth?.millisecondsSinceEpoch}|${user.bio}';
  }

  Future<void> _selectDOB() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDOB) {
      setState(() {
        _selectedDOB = picked;
        _dobCtrl.text = _formatDateOfBirth(picked);
      });
    }
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
    return AppFormatters.relativeDate(date);
  }

  String _formatDateOfBirth(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return '';
    }
    return AppFormatters.dateShort(
      DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day),
    );
  }

  DateTime? _normalizeDateForApi(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return null;
    }
    // Keep date stable across timezone conversions by using UTC midday.
    return DateTime.utc(
      dateOfBirth.year,
      dateOfBirth.month,
      dateOfBirth.day,
      12,
    );
  }

  ImageProvider<Object>? _resolveAvatar(UserEntity user) {
    final avatar = user.avatar.trim();
    if (avatar.isEmpty) {
      return null;
    }

    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return CachedNetworkImageProvider(avatar);
    }

    if (avatar.startsWith('/')) {
      final absoluteUrl = UrlHelper.toAbsolute(EnvConfig.apiBaseUrl, avatar);
      return CachedNetworkImageProvider(absoluteUrl);
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
      final user = ref.read(authProvider).user;
      final currentAvatar = user?.avatar;

      await ref.read(authProvider.notifier).updateProfile(
            username: _usernameCtrl.text.trim().toLowerCase(),
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            gender: _selectedGender,
            avatar: currentAvatar,
            dateOfBirth: _normalizeDateForApi(_selectedDOB),
            bio: _bioCtrl.text.trim(),
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

  void _showEditSocialLinksBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final githubCtrl = TextEditingController(text: _socialGithub);
    final instagramCtrl = TextEditingController(text: _socialInstagram);
    final discordCtrl = TextEditingController(text: _socialDiscord);
    final telegramCtrl = TextEditingController(text: _socialTelegram);
    final spotifyCtrl = TextEditingController(text: _socialSpotify);
    final tiktokCtrl = TextEditingController(text: _socialTikTok);
    bool isSaving = false;

    String normalizeValue(String value) => value.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            top: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.92,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    16 + mediaQuery.padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Edit Social Media Links',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan username atau link profil Anda.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SocialLinkField(
                          controller: githubCtrl,
                          label: 'GitHub',
                          hint: 'github.com/username',
                          icon: FontAwesomeIcons.github,
                          isDark: isDark),
                      const SizedBox(height: 12),
                      _SocialLinkField(
                          controller: instagramCtrl,
                          label: 'Instagram',
                          hint: 'instagram.com/username',
                          icon: Icons.camera_alt_rounded,
                          isDark: isDark,
                          isInstagram: true),
                      const SizedBox(height: 12),
                      _SocialLinkField(
                          controller: discordCtrl,
                          label: 'Discord',
                          hint: 'discord.gg/your-server',
                          icon: FontAwesomeIcons.discord,
                          isDark: isDark),
                      const SizedBox(height: 12),
                      _SocialLinkField(
                          controller: telegramCtrl,
                          label: 'Telegram',
                          hint: 't.me/username',
                          icon: FontAwesomeIcons.telegram,
                          isDark: isDark),
                      const SizedBox(height: 12),
                      _SocialLinkField(
                          controller: spotifyCtrl,
                          label: 'Spotify',
                          hint: 'open.spotify.com/user/...',
                          icon: FontAwesomeIcons.spotify,
                          isDark: isDark),
                      const SizedBox(height: 12),
                      _SocialLinkField(
                          controller: tiktokCtrl,
                          label: 'TikTok',
                          hint: 'tiktok.com/@username',
                          icon: FontAwesomeIcons.tiktok,
                          textInputAction: TextInputAction.done,
                          isDark: isDark),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Simpan',
                          isLoading: isSaving,
                          onPressed: isSaving
                              ? null
                              : () async {
                                  FocusScope.of(sheetContext).unfocus();

                                  final String nextGithub =
                                      normalizeValue(githubCtrl.text);
                                  final String nextInstagram =
                                      normalizeValue(instagramCtrl.text);
                                  final String nextDiscord =
                                      normalizeValue(discordCtrl.text);
                                  final String nextTelegram =
                                      normalizeValue(telegramCtrl.text);
                                  final String nextSpotify =
                                      normalizeValue(spotifyCtrl.text);
                                  final String nextTiktok =
                                      normalizeValue(tiktokCtrl.text);

                                  final bool hasChanges = nextGithub !=
                                          normalizeValue(_socialGithub) ||
                                      nextInstagram !=
                                          normalizeValue(_socialInstagram) ||
                                      nextDiscord !=
                                          normalizeValue(_socialDiscord) ||
                                      nextTelegram !=
                                          normalizeValue(_socialTelegram) ||
                                      nextSpotify !=
                                          normalizeValue(_socialSpotify) ||
                                      nextTiktok !=
                                          normalizeValue(_socialTikTok);

                                  if (!hasChanges) {
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                    return;
                                  }

                                  setModalState(() => isSaving = true);
                                  try {
                                    await _saveSocialLinks(
                                      github: nextGithub,
                                      instagram: nextInstagram,
                                      discord: nextDiscord,
                                      telegram: nextTelegram,
                                      spotify: nextSpotify,
                                      tiktok: nextTiktok,
                                    );
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                  } catch (_) {
                                    if (sheetContext.mounted) {
                                      AppAlert.show(
                                        sheetContext,
                                        title: 'Gagal Menyimpan',
                                        message:
                                            'Terjadi kendala saat menyimpan tautan sosial.',
                                        isError: true,
                                      );
                                    }
                                  } finally {
                                    if (sheetContext.mounted) {
                                      setModalState(() => isSaving = false);
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      githubCtrl.dispose();
      instagramCtrl.dispose();
      discordCtrl.dispose();
      telegramCtrl.dispose();
      spotifyCtrl.dispose();
      tiktokCtrl.dispose();
    });
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

class _TopBar extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final bool isDark;

  const _TopBar({
    required this.onRefresh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Profil',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pengaturan Akun',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kelola profil dan preferensi utama dengan cepat.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _TopBarAction(
            icon: Icons.refresh_rounded,
            onPressed: onRefresh,
            isDark: isDark,
            tooltip: 'Sinkronkan profile',
          ),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;
  final String tooltip;

  const _TopBarAction({
    required this.icon,
    required this.onPressed,
    required this.isDark,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.03),
                ]
              : <Color>[
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF4F8FF).withValues(alpha: 0.94),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.90),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isDark ? Colors.white70 : AppColors.primaryDark,
          size: 22,
        ),
      ),
    );
  }
}

class _HeroProfileCard extends ConsumerStatefulWidget {
  final UserEntity user;
  final ImageProvider<Object>? avatarProvider;
  final VoidCallback? onTapChangePhoto;
  final bool isUploadingPhoto;
  final String genderLabel;
  final IconData genderIcon;
  final String lastSyncedLabel;
  final bool isDark;
  final Function(String) onQuickUpdateName;
  final String socialGithub;
  final String socialInstagram;
  final String socialDiscord;
  final String socialTelegram;
  final String socialSpotify;
  final String socialTikTok;
  final VoidCallback onEditSocialLinks;

  const _HeroProfileCard({
    required this.user,
    this.avatarProvider,
    this.onTapChangePhoto,
    required this.isUploadingPhoto,
    required this.genderLabel,
    required this.genderIcon,
    required this.lastSyncedLabel,
    required this.isDark,
    required this.onQuickUpdateName,
    this.socialGithub = '',
    this.socialInstagram = '',
    this.socialDiscord = '',
    this.socialTelegram = '',
    this.socialSpotify = '',
    this.socialTikTok = '',
    required this.onEditSocialLinks,
  });

  @override
  ConsumerState<_HeroProfileCard> createState() => _HeroProfileCardState();
}

class _HeroProfileCardState extends ConsumerState<_HeroProfileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  UserEntity get user => widget.user;
  ImageProvider<Object>? get avatarProvider => widget.avatarProvider;
  VoidCallback? get onTapChangePhoto => widget.onTapChangePhoto;
  bool get isUploadingPhoto => widget.isUploadingPhoto;
  String get genderLabel => widget.genderLabel;
  IconData get genderIcon => widget.genderIcon;
  String get lastSyncedLabel => widget.lastSyncedLabel;
  bool get isDark => widget.isDark;

  String _avatarInitial(String username) {
    final clean = username.trim();
    if (clean.isEmpty) {
      return '?';
    }
    return clean.substring(0, 1).toUpperCase();
  }

  Future<void> _launchSocial(String platform, String handle) async {
    if (handle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tautan $platform belum diatur.')),
      );
      return;
    }
    final success = await UrlHelper.launchSocialUrl(platform, handle);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Gagal membuka $platform. Pastikan format tautan benar.')),
      );
    }
  }

  void _showEditNameBottomSheet(BuildContext context, String currentName) {
    final TextEditingController controller =
        TextEditingController(text: currentName);
    final isDark = widget.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ubah Nama Tampilan',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nama ini akan terlihat di semua aktivitas Anda.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              _ModernTextField(
                controller: controller,
                label: 'Display Name',
                hint: 'Masukkan nama baru',
                icon: Icons.edit_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Simpan Nama',
                  onPressed: () {
                    widget.onQuickUpdateName(controller.text);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    if (role == 'owner' || role == 'developer') return 'Owner / Developer';
    if (role == 'staff' || role == 'admin') return 'Staff / Admin';
    if (role == 'vanguard') return 'Elite Pioneer';
    if (role == 'ace_tester') return 'Ace Tester';
    return 'Regular User';
  }

  Color _roleColor(String role) {
    if (role == 'owner' || role == 'developer') return AppColors.primaryDark;
    if (role == 'staff' || role == 'admin') return AppColors.primary;
    if (role == 'vanguard') return const Color(0xFF8B5CF6); // Violet
    if (role == 'ace_tester') return const Color(0xFF06B6D4); // Cyan
    return AppColors.softHeaderGray;
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = _roleColor(user.role);
    final String roleLabel = _roleLabel(user.role);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final int connectedSocials = <String>[
      widget.socialGithub,
      widget.socialInstagram,
      widget.socialDiscord,
      widget.socialTelegram,
      widget.socialSpotify,
      widget.socialTikTok,
    ].where((String value) => value.trim().isNotEmpty).length;

    return ModernGlassCard(
      padding: EdgeInsets.zero,
      isDark: isDark,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -36,
            right: -18,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    roleColor.withValues(alpha: 0.22),
                    roleColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.public_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Public Identity',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lastSyncedLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const SweepGradient(
                              colors: <Color>[
                                AppColors.primary,
                                AppColors.secondary,
                                AppColors.accent,
                                AppColors.primary,
                              ],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: roleColor.withValues(alpha: 0.24),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF0F172A) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: CircleAvatar(
                            key: ValueKey(
                              user.avatar.isNotEmpty ? user.avatar : user.id,
                            ),
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            backgroundImage: avatarProvider,
                            child: avatarProvider == null
                                ? Text(
                                    _avatarInitial(user.username),
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: onTapChangePhoto,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  width: 3,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: isUploadingPhoto
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          InkWell(
                            onTap: () =>
                                _showEditNameBottomSheet(context, user.name),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.primaryDark,
                                      letterSpacing: -0.7,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                  color: roleColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user.username}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _ProfileStatChip(
                                icon: Icons.workspace_premium_rounded,
                                label: roleLabel,
                                color: roleColor,
                                isDark: isDark,
                              ),
                              _ProfileStatChip(
                                icon: genderIcon,
                                label: genderLabel,
                                color: AppColors.info,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user.bio.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          roleColor.withValues(alpha: isDark ? 0.12 : 0.10),
                          AppColors.primary.withValues(
                            alpha: isDark ? 0.05 : 0.04,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleColor.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'PERSONAL BIO',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color:
                                isDark ? Colors.white54 : AppColors.primaryDark,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.bio,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _ProfileStatChip(
                      icon: Icons.link_rounded,
                      label: '$connectedSocials social links',
                      color: const Color(0xFF0EA5E9),
                      isDark: isDark,
                    ),
                    _ProfileStatChip(
                      icon: Icons.public_rounded,
                      label: 'Bio publik aktif',
                      color: const Color(0xFFEC4899),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Social Hub',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark ? Colors.white : AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tautan ini juga bisa terlihat di profil publik chat.',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: widget.onEditSocialLinks,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.24),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.edit_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    const double spacing = 10;
                    final double halfWidth =
                        (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: <Widget>[
                        SizedBox(
                          width: halfWidth,
                          child: _SocialPill(
                            icon: FontAwesomeIcons.github,
                            label: 'GitHub',
                            color: const Color(0xFF24292E),
                            value: widget.socialGithub,
                            isDark: isDark,
                            onTap: () =>
                                _launchSocial('GitHub', widget.socialGithub),
                          ),
                        ),
                        SizedBox(
                          width: halfWidth,
                          child: _SocialPill(
                            icon: FontAwesomeIcons.instagram,
                            label: 'Instagram',
                            color: const Color(0xFFE1306C),
                            value: widget.socialInstagram,
                            isDark: isDark,
                            isInstagram: true,
                            onTap: () => _launchSocial(
                              'Instagram',
                              widget.socialInstagram,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: halfWidth,
                          child: _SocialPill(
                            icon: FontAwesomeIcons.discord,
                            label: 'Discord',
                            color: const Color(0xFF5865F2),
                            value: widget.socialDiscord,
                            isDark: isDark,
                            onTap: () =>
                                _launchSocial('Discord', widget.socialDiscord),
                          ),
                        ),
                        SizedBox(
                          width: halfWidth,
                          child: _SocialPill(
                            icon: FontAwesomeIcons.telegram,
                            label: 'Telegram',
                            color: const Color(0xFF229ED9),
                            value: widget.socialTelegram,
                            isDark: isDark,
                            onTap: () => _launchSocial(
                                'Telegram', widget.socialTelegram),
                          ),
                        ),
                        SizedBox(
                          width: halfWidth,
                          child: _SocialPill(
                            icon: FontAwesomeIcons.spotify,
                            label: 'Spotify',
                            color: const Color(0xFF1DB954),
                            value: widget.socialSpotify,
                            isDark: isDark,
                            onTap: () =>
                                _launchSocial('Spotify', widget.socialSpotify),
                          ),
                        ),
                        SizedBox(
                          width: halfWidth,
                          child: _SocialPill(
                            icon: FontAwesomeIcons.tiktok,
                            label: 'TikTok',
                            color: const Color(0xFF111827),
                            value: widget.socialTikTok,
                            isDark: isDark,
                            onTap: () =>
                                _launchSocial('TikTok', widget.socialTikTok),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _ProfileStatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.82),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialPill extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color color;
  final String value;
  final bool isDark;
  final bool isInstagram;
  final VoidCallback onTap;

  const _SocialPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
    required this.isDark,
    this.isInstagram = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 260),
          opacity: hasValue ? 1.0 : 0.68,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  color.withValues(alpha: isDark ? 0.20 : 0.12),
                  isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.78),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: hasValue ? 0.24 : 0.14),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isInstagram
                        ? const _InstagramGradientIcon(size: 12)
                        : FaIcon(
                            icon,
                            size: 12,
                            color: hasValue
                                ? color
                                : color.withValues(alpha: 0.68),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        hasValue ? 'Connected' : 'Belum diatur',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white38 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasValue
                      ? Icons.open_in_new_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: hasValue ? 14 : 13,
                  color: hasValue
                      ? color.withValues(alpha: 0.86)
                      : (isDark ? Colors.white30 : Colors.black26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController dobCtrl;
  final String selectedGender;
  final ValueChanged<String> onSelectGender;
  final List<(String, String, IconData)> genderOptions;
  final VoidCallback onSelectDOB;
  final bool isSaving;
  final VoidCallback? onSave;
  final bool isDark;

  const _EditProfileCard({
    required this.formKey,
    required this.usernameCtrl,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.bioCtrl,
    required this.selectedGender,
    required this.onSelectGender,
    required this.genderOptions,
    required this.dobCtrl,
    required this.onSelectDOB,
    required this.isSaving,
    required this.onSave,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 15),
                Text(
                  'Account Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _ModernTextField(
              controller: nameCtrl,
              label: 'Display Name',
              hint: 'Tulis nama lengkap Anda',
              icon: Icons.badge_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _ModernTextField(
              controller: bioCtrl,
              label: 'Personal Bio',
              hint: 'Ceritakan sedikit tentang Anda...',
              icon: Icons.auto_awesome_rounded,
              isDark: isDark,
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 20),
            _ModernTextField(
              controller: usernameCtrl,
              label: 'Username',
              hint: 'username_baru',
              icon: Icons.alternate_email_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _ModernTextField(
              controller: emailCtrl,
              label: 'Email Address',
              hint: 'email@example.com',
              icon: Icons.email_outlined,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _ModernDateField(
              controller: dobCtrl,
              label: 'Birthday Date',
              onTap: onSelectDOB,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            Text(
              'GENDER IDENTITY',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white24 : Colors.black26,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            _GenderSelector(
              selectedGender: selectedGender,
              options: genderOptions,
              onSelect: onSelectGender,
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: CustomButton(
                text: isSaving ? 'Menyimpan...' : 'Perbarui Profile',
                onPressed: isSaving ? null : onSave,
                isLoading: isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernInputLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _ModernInputLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType keyboardType;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ModernInputLabel(label: label, isDark: isDark),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            minLines: maxLines > 1 ? maxLines : 1,
            maxLines: maxLines,
            maxLength: maxLength,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon,
                  size: 20, color: AppColors.primary.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ModernDateField({
    required this.controller,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(
        child: _ModernTextField(
          controller: controller,
          label: label,
          hint: 'Pilih tanggal',
          icon: Icons.calendar_month_rounded,
          isDark: isDark,
          readOnly: true,
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String selectedGender;
  final List<(String value, String label, IconData icon)> options;
  final ValueChanged<String> onSelect;
  final bool isDark;

  const _GenderSelector({
    required this.selectedGender,
    required this.options,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ModernInputLabel(label: 'Gender Identity', isDark: isDark),
        _ModernGenderPicker(
          selectedGender: selectedGender,
          options: options,
          onSelect: onSelect,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ModernGenderPicker extends StatelessWidget {
  final String selectedGender;
  final List<(String value, String label, IconData icon)> options;
  final ValueChanged<String> onSelect;
  final bool isDark;

  const _ModernGenderPicker({
    required this.selectedGender,
    required this.options,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final bool isSelected = selectedGender == opt.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.gradientPrimary : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(opt.$3,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8))),
                  const SizedBox(height: 6),
                  Text(
                    opt.$2,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CompactProfileMenu extends StatelessWidget {
  final bool isDark;
  final bool showAdvanced;
  final VoidCallback onToggleAdvanced;
  final VoidCallback onEditSocialLinks;

  const _CompactProfileMenu({
    required this.isDark,
    required this.showAdvanced,
    required this.onToggleAdvanced,
    required this.onEditSocialLinks,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isCompact = constraints.maxWidth < 380;

          final Widget socialButton = ModernGlassButton(
            text: 'Kelola Sosial',
            icon: Icons.hub_rounded,
            onTap: onEditSocialLinks,
            isPrimary: false,
          );

          final Widget detailButton = ModernGlassButton(
            text: showAdvanced ? 'Sembunyikan' : 'Lihat Detail',
            icon: showAdvanced
                ? Icons.unfold_less_rounded
                : Icons.unfold_more_rounded,
            onTap: onToggleAdvanced,
          );

          if (isCompact) {
            return Column(
              children: <Widget>[
                SizedBox(width: double.infinity, child: socialButton),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: detailButton),
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: socialButton),
              const SizedBox(width: 10),
              Expanded(child: detailButton),
            ],
          );
        },
      ),
    );
  }
}

class _AccountInsightCard extends StatelessWidget {
  final UserEntity user;
  final String genderLabel;
  final IconData genderIcon;
  final String dobLabel;
  final bool isDark;
  final VoidCallback onCopyUsername;
  final VoidCallback onCopyEmail;

  const _AccountInsightCard({
    required this.user,
    required this.genderLabel,
    required this.genderIcon,
    required this.dobLabel,
    required this.isDark,
    required this.onCopyUsername,
    required this.onCopyEmail,
  });

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Color(0xFF6366F1), size: 22),
              ),
              const SizedBox(width: 15),
              Text(
                'Account Summary',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'FULL NAME',
            value: user.name,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'USERNAME',
            value: user.username,
            isDark: isDark,
            actionIcon: Icons.copy_rounded,
            onActionTap: onCopyUsername,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'EMAIL ADDRESS',
            value: user.email,
            isDark: isDark,
            actionIcon: Icons.copy_rounded,
            onActionTap: onCopyEmail,
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.info_outline_rounded,
              label: 'PERSONAL BIO',
              value: user.bio,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 16),
          _InfoRow(
            icon: genderIcon,
            label: 'GENDER ORIENTATION',
            value: genderLabel,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.cake_rounded,
            label: 'DATE OF BIRTH',
            value: dobLabel,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF334155),
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
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
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
    return ModernGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings_suggest_rounded,
                    color: Colors.teal, size: 22),
              ),
              const SizedBox(width: 15),
              Text(
                'Personalization',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _PreferenceSwitch(
            icon: Icons.notifications_active_rounded,
            title: 'Daily Reminders',
            subtitle: 'Get notified for daily activities',
            value: dailyReminderEnabled,
            onChanged: onDailyReminderChanged,
            isDark: isDark,
          ),
          const Divider(height: 24, thickness: 0.5, color: Colors.black12),
          _PreferenceSwitch(
            icon: Icons.chat_bubble_rounded,
            title: 'Chat Notifications',
            subtitle: 'Notify for incoming messages',
            value: chatNotificationsEnabled,
            onChanged: onChatNotificationsChanged,
            isDark: isDark,
          ),
          const Divider(height: 24, thickness: 0.5, color: Colors.black12),
          _PreferenceSwitch(
            icon: Icons.data_usage_rounded,
            title: 'Data Savings Mode',
            subtitle: 'Limit high-quality media loading',
            value: lowDataModeEnabled,
            onChanged: onLowDataModeChanged,
            isDark: isDark,
          ),
          const Divider(height: 24, thickness: 0.5, color: Colors.black12),
          _PreferenceSwitch(
            icon: Icons.dark_mode_rounded,
            title: 'Visual Theme',
            subtitle: 'Toggle dark or light mode',
            value: isDark,
            onChanged: (v) => onToggleTheme(),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
        // activeColor: AppColors.primary, (deprecated, removed)
        title: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isDark ? Colors.white54 : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
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
    return ModernGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLogout,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Text(
                  'SIGN OUT ACCOUNT',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.error,
                    letterSpacing: 1.5,
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

class _AppCredit extends StatelessWidget {
  const _AppCredit();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 14, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(
              'SmartLife Intelligence',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.auto_awesome_rounded,
                size: 14, color: AppColors.primary.withValues(alpha: 0.6)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Build Version 1.0.0 (Stable)',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          ),
        ),
      ],
    );
  }
}

class _StaffManagementCard extends StatelessWidget {
  final bool isDark;

  const _StaffManagementCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      isDark: isDark,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffManagementScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade400,
                        Colors.orange.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Team Management',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control roles and permissions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
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
}

class _InstagramGradientIcon extends StatelessWidget {
  final double size;
  const _InstagramGradientIcon({this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF405DE6),
            Color(0xFFC13584),
            Color(0xFFFD1D1D),
            Color(0xFFF77737),
            Color(0xFFFCAF45),
          ],
        ),
      ),
      child: Icon(
        Icons.camera_alt_rounded,
        size: size * 0.65,
        color: Colors.white,
      ),
    );
  }
}

class _SocialLinkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final dynamic icon;
  final bool isDark;
  final bool isInstagram;
  final TextInputAction textInputAction;

  const _SocialLinkField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.isInstagram = false,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.url,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 12.5,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: isInstagram
              ? const _InstagramGradientIcon(size: 20)
              : FaIcon(icon,
                  size: 18, color: isDark ? Colors.white54 : Colors.black45),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _SocialMediaCard extends StatelessWidget {
  final bool isDark;
  final String github;
  final String instagram;
  final String discord;
  final String telegram;
  final String spotify;
  final String tiktok;
  final VoidCallback onEdit;

  const _SocialMediaCard({
    required this.isDark,
    required this.github,
    required this.instagram,
    required this.discord,
    required this.telegram,
    required this.spotify,
    required this.tiktok,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final List<_SocialMediaItem> items = <_SocialMediaItem>[
      _SocialMediaItem(
        platform: 'GitHub',
        value: github,
        icon: FontAwesomeIcons.github,
        color: isDark ? Colors.white : const Color(0xFF24292E),
      ),
      _SocialMediaItem(
        platform: 'Instagram',
        value: instagram,
        isInstagram: true,
        color: const Color(0xFFE1306C),
      ),
      _SocialMediaItem(
        platform: 'Discord',
        value: discord,
        icon: FontAwesomeIcons.discord,
        color: const Color(0xFF5865F2),
      ),
      _SocialMediaItem(
        platform: 'Telegram',
        value: telegram,
        icon: FontAwesomeIcons.telegram,
        color: const Color(0xFF0088CC),
      ),
      _SocialMediaItem(
        platform: 'Spotify',
        value: spotify,
        icon: FontAwesomeIcons.spotify,
        color: const Color(0xFF1DB954),
      ),
      _SocialMediaItem(
        platform: 'TikTok',
        value: tiktok,
        icon: FontAwesomeIcons.tiktok,
        color: const Color(0xFF111827),
      ),
    ];
    return ModernGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.primary.withValues(alpha: 0.16),
                      AppColors.primary.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Social Media',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ukuran icon dibuat lebih ringkas agar tampilan lebih rapi.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.edit_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Edit',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const double spacing = 10;
              final bool twoColumns = constraints.maxWidth >= 360;
              final double halfWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: <Widget>[
                  for (int i = 0; i < items.length; i++)
                    SizedBox(
                      width: (!twoColumns ||
                              (items.length.isOdd && i == items.length - 1))
                          ? constraints.maxWidth
                          : halfWidth,
                      child: _buildSocialTile(context, items[i]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTile(BuildContext context, _SocialMediaItem item) {
    final bool hasValue = item.value.trim().isNotEmpty;
    final String normalizedUrl =
        hasValue ? UrlHelper.normalizeSocialUrl(item.platform, item.value) : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasValue
            ? () async {
                final bool success = await UrlHelper.launchSocialUrl(
                  item.platform,
                  item.value,
                );
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuka ${item.platform}.')),
                  );
                }
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                item.color.withValues(alpha: isDark ? 0.16 : 0.11),
                isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.84),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.color.withValues(alpha: hasValue ? 0.22 : 0.12),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: item.isInstagram
                      ? const _InstagramGradientIcon(size: 12)
                      : FaIcon(item.icon, size: 12, color: item.color),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.platform,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      hasValue ? normalizedUrl : 'Belum diatur',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.w500,
                        color: hasValue
                            ? (isDark
                                ? Colors.white60
                                : AppColors.textSecondary)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                hasValue
                    ? Icons.open_in_new_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: hasValue ? 13 : 12,
                color: hasValue
                    ? item.color.withValues(alpha: 0.86)
                    : (isDark ? Colors.white30 : Colors.black26),
              ),
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
