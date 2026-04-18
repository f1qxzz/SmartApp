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
  final TextEditingController _budgetCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  DateTime? _selectedDOB;
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
  String _socialGithub = '';
  String _socialInstagram = '';
  String _socialDiscord = '';
  String _socialTelegram = '';
  String _socialSpotify = '';

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
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveSocialLinks({
    required String github,
    required String instagram,
    required String discord,
    required String telegram,
    required String spotify,
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    _socialGithub = github;
    _socialInstagram = instagram;
    _socialDiscord = discord;
    _socialTelegram = telegram;
    _socialSpotify = spotify;

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
          monthlyBudget: double.tryParse(
                  _budgetCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ??
              user.monthlyBudget,
          dateOfBirth: user.dateOfBirth,
          socialGithub: github,
          socialInstagram: instagram,
          socialDiscord: discord,
          socialTelegram: telegram,
          socialSpotify: spotify,
        );

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _budgetCtrl.dispose();
    _dobCtrl.dispose();
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
                  genderLabel: _genderLabel(genderValue),
                  genderIcon: _genderIcon(genderValue),
                  lastSyncedLabel: _formatLastSynced(_lastSyncedAt),
                  isDark: isDark,
                  socialGithub: _socialGithub,
                  socialInstagram: _socialInstagram,
                  socialDiscord: _socialDiscord,
                  socialTelegram: _socialTelegram,
                  socialSpotify: _socialSpotify,
                  onEditSocialLinks: () =>
                      _showEditSocialLinksBottomSheet(context),
                  onQuickUpdateName: (newName) {
                    ref.read(authProvider.notifier).updateProfile(
                          username: user.username,
                          email: user.email,
                          name: newName,
                          gender: user.gender,
                          avatar: user.avatar,
                          monthlyBudget: user.monthlyBudget,
                          dateOfBirth: user.dateOfBirth,
                        );
                  },
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
                  dobCtrl: _dobCtrl,
                  onSelectDOB: _selectDOB,
                ),
                const SizedBox(height: 14),
                _AccountInsightCard(
                  user: user,
                  genderLabel: _genderLabel(_toGenderValue(user.gender)),
                  genderIcon: _genderIcon(_toGenderValue(user.gender)),
                  dobLabel: user.dateOfBirth != null
                      ? '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}'
                      : 'Belum diisi',
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
                  onEdit: () => _showEditSocialLinksBottomSheet(context),
                ),
                const SizedBox(height: 14),
                if (user.role == 'owner' || user.role == 'developer') ...[
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
    _budgetCtrl.text = AppFormatters.currencyNoSymbol(user.monthlyBudget);
    _selectedGender = _toGenderValue(user.gender);
    _selectedDOB = user.dateOfBirth;
    if (_selectedDOB != null) {
      _dobCtrl.text =
          '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}';
    } else {
      _dobCtrl.text = '';
    }
    _lastSyncedAt = DateTime.now();

    if (mounted) {
      setState(() {});
    }
  }

  String _userSignature(UserEntity user) {
    return '${user.id}|${user.username}|${user.email}|${user.name}|${user.gender}|${user.avatar}|${user.monthlyBudget}|${user.dateOfBirth?.millisecondsSinceEpoch}';
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
        _dobCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
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
            monthlyBudget:
                double.tryParse(_budgetCtrl.text.replaceAll('.', '')) ?? 0,
            dateOfBirth: _selectedDOB,
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
                'Edit Social Media Links',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                  icon: FontAwesomeIcons.github,
                  isDark: isDark),
              const SizedBox(height: 12),
              _SocialLinkField(
                  controller: instagramCtrl,
                  label: 'Instagram',
                  icon: Icons.camera_alt_rounded,
                  isDark: isDark,
                  isInstagram: true),
              const SizedBox(height: 12),
              _SocialLinkField(
                  controller: discordCtrl,
                  label: 'Discord',
                  icon: FontAwesomeIcons.discord,
                  isDark: isDark),
              const SizedBox(height: 12),
              _SocialLinkField(
                  controller: telegramCtrl,
                  label: 'Telegram',
                  icon: FontAwesomeIcons.telegram,
                  isDark: isDark),
              const SizedBox(height: 12),
              _SocialLinkField(
                  controller: spotifyCtrl,
                  label: 'Spotify',
                  icon: FontAwesomeIcons.spotify,
                  isDark: isDark),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Simpan',
                  onPressed: () {
                    _saveSocialLinks(
                      github: githubCtrl.text.trim(),
                      instagram: instagramCtrl.text.trim(),
                      discord: discordCtrl.text.trim(),
                      telegram: telegramCtrl.text.trim(),
                      spotify: spotifyCtrl.text.trim(),
                    );
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
        // Modern Soft Gradient Orbs
        Positioned(
          top: -120,
          left: -60,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF6366F1) : AppColors.primary)
                      .withValues(alpha: isDark ? 0.18 : 0.12),
                  (isDark ? const Color(0xFF6366F1) : AppColors.primary)
                      .withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 150,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFFA855F7) : AppColors.secondary)
                      .withValues(alpha: isDark ? 0.15 : 0.08),
                  (isDark ? const Color(0xFFA855F7) : AppColors.secondary)
                      .withValues(alpha: 0),
                ],
              ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Saya',
              style: AppTextStyles.heading2(context).copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: -0.8,
              ),
            ),
            Container(
              height: 4,
              width: 28,
              margin: const EdgeInsets.only(top: 4, left: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
        const Spacer(),
        _TopBarAction(
          icon: Icons.refresh_rounded,
          onPressed: onRefresh,
          isDark: isDark,
          tooltip: 'Sinkronkan profile',
        ),
      ],
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon,
            color: isDark ? Colors.white : AppColors.textPrimary, size: 22),
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
    return 'Regular User';
  }

  Color _roleColor(String role) {
    if (role == 'owner' || role == 'developer') return AppColors.primaryDark;
    if (role == 'staff' || role == 'admin') return AppColors.primary;
    return AppColors.softHeaderGray;
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = _roleColor(user.role);
    final String roleLabel = _roleLabel(user.role);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.dividerLight.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _OrganicBlobPainter(
                  color1: isDark
                      ? AppColors.primary.withValues(alpha: 0.22)
                      : AppColors.secondaryLight,
                  color2: isDark
                      ? AppColors.primaryLight.withValues(alpha: 0.16)
                      : AppColors.accentLight,
                  color3: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFE3EBFF),
                  isDark: isDark,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.03),
                            const Color(0xFF0F172A).withValues(alpha: 0.34),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.72),
                            AppColors.secondaryLight.withValues(alpha: 0.5),
                          ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -36,
              right: -30,
              child: IgnorePointer(
                child: Container(
                  width: 164,
                  height: 164,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.14 : 0.95),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  AppColors.primaryLight,
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                  AppColors.primaryLight,
                                ],
                                transform: const GradientRotation(3.14 / 4),
                              ),
                            ),
                          ),
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color:
                                  isDark ? AppColors.surfaceDark : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  width: 3),
                            ),
                            child: CircleAvatar(
                              key: ValueKey(user.avatar.isNotEmpty
                                  ? user.avatar
                                  : user.id),
                              backgroundColor: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight,
                              backgroundImage: avatarProvider,
                              child: avatarProvider == null
                                  ? Text(
                                      _avatarInitial(user.username),
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.softHeaderGray,
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
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: isUploadingPhoto
                                    ? const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(Icons.camera_alt_rounded,
                                        color: Colors.white, size: 14),
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
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.primaryDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textTertiary,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${user.username}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(
                                  alpha: isDark ? 0.18 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: roleColor.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Text(
                                roleLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (widget.socialGithub.isNotEmpty)
                                  _SocialIcon(
                                    icon: FontAwesomeIcons.github,
                                    onTap: () => _launchSocial(
                                        'GitHub', widget.socialGithub),
                                    isDark: isDark,
                                  ),
                                if (widget.socialInstagram.isNotEmpty)
                                  _SocialIcon(
                                    icon: null,
                                    isInstagram: true,
                                    onTap: () => _launchSocial(
                                        'Instagram', widget.socialInstagram),
                                    isDark: isDark,
                                  ),
                                if (widget.socialDiscord.isNotEmpty)
                                  _SocialIcon(
                                    icon: FontAwesomeIcons.discord,
                                    onTap: () => _launchSocial(
                                        'Discord', widget.socialDiscord),
                                    isDark: isDark,
                                  ),
                                if (widget.socialTelegram.isNotEmpty)
                                  _SocialIcon(
                                    icon: FontAwesomeIcons.telegram,
                                    onTap: () => _launchSocial(
                                        'Telegram', widget.socialTelegram),
                                    isDark: isDark,
                                  ),
                                if (widget.socialSpotify.isNotEmpty)
                                  _SocialIcon(
                                    icon: FontAwesomeIcons.spotify,
                                    onTap: () => _launchSocial(
                                        'Spotify', widget.socialSpotify),
                                    isDark: isDark,
                                    iconColor: const Color(0xFF1DB954),
                                  ),
                                InkWell(
                                  onTap: widget.onEditSocialLinks,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.07)
                                          : AppColors.primary
                                              .withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.08)
                                            : AppColors.primary
                                                .withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: Icon(Icons.add_link_rounded,
                                        size: 14, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(
                      color: isDark
                          ? Colors.white12
                          : AppColors.dividerLight.withValues(alpha: 0.9),
                      height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${user.id.substring(user.id.length > 8 ? user.id.length - 8 : 0).toUpperCase()}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white38 : AppColors.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Baru saja',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.softHeaderGray,
                            ),
                          ),
                        ],
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
}

class _SocialIcon extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isInstagram;
  final Color? iconColor;

  const _SocialIcon({
    this.icon,
    required this.onTap,
    required this.isDark,
    this.isInstagram = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isInstagram
            ? const _InstagramGradientIcon(size: 14)
            : FaIcon(
                icon,
                size: 14,
                color: iconColor ??
                    (isDark ? Colors.white70 : AppColors.primaryDark),
              ),
      ),
    );
  }
}

class _OrganicBlobPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Color color3;
  final bool isDark;

  _OrganicBlobPainter({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {

    // Specular Highlight Paint
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);

    // Grain/Noise Texture logic (randomized tiny dots)
    // We use a fixed seed if possible for performance, or just draw a few clusters
    final grainPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03);

    // Draw Blobs with Specular highlights
    // Top Right
    _drawBlob(canvas, size, color3, [0.7, 0.0], [0.9, 0.1], [1.0, 0.4]);
    // Bottom Left
    _drawBlob(canvas, size, color2, [0.0, 0.6], [0.2, 0.7], [0.4, 1.0]);
    // Middle Right
    _drawBlob(canvas, size, color1, [1.0, 0.5], [0.7, 0.7], [0.8, 1.0]);

    // Specular Highlights (Simulate glass edge reflection)
    final specPath = Path()
      ..moveTo(20, 10)
      ..quadraticBezierTo(size.width * 0.5, 5, size.width - 20, 15);
    canvas.drawPath(specPath, highlightPaint);

    // Micro-Grain Texture Overlay
    for (int i = 0; i < 400; i++) {
      canvas.drawCircle(
        Offset(i.toDouble() % size.width, (i * 0.5) % size.height),
        0.5,
        grainPaint,
      );
    }
  }

  void _drawBlob(Canvas canvas, Size size, Color color, List<double> start,
      List<double> ctrl, List<double> end) {
    final paint = Paint()
      ..color = color
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 20); // Bloom effect

    final path = Path();
    path.moveTo(size.width * start[0], size.height * start[1]);
    path.quadraticBezierTo(size.width * ctrl[0], size.height * ctrl[1],
        size.width * end[0], size.height * end[1]);

    // Connect to corners if needed or just close organically
    if (start[1] == 0) {
      path.lineTo(size.width, 0);
    } else if (end[1] == 1.0) {
      path.lineTo(0, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  final TextEditingController dobCtrl;
  final VoidCallback onSelectDOB;
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
    required this.dobCtrl,
    required this.onSelectDOB,
    required this.isSaving,
    required this.onSave,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.03),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.edit_note_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Edit Informasi Profil',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ModernInputLabel(label: 'Nama Lengkap', isDark: isDark),
            _ModernTextField(
              controller: nameCtrl,
              hint: 'Masukkan nama lengkap',
              icon: Icons.person_rounded,
              isDark: isDark,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 18),
            _ModernInputLabel(label: 'Username', isDark: isDark),
            _ModernTextField(
              controller: usernameCtrl,
              hint: 'Masukkan username',
              icon: Icons.alternate_email_rounded,
              isDark: isDark,
              validator: (value) {
                final input = value?.trim().toLowerCase() ?? '';
                if (input.isEmpty) return 'Username wajib diisi';
                if (!RegExp(r'^[a-z0-9._]{3,30}$').hasMatch(input)) {
                  return 'Username tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _ModernInputLabel(label: 'Email Konfirmasi', isDark: isDark),
            _ModernTextField(
              controller: emailCtrl,
              hint: 'Masukkan email',
              icon: Icons.email_rounded,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) return 'Email wajib diisi';
                if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$')
                    .hasMatch(input)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _ModernInputLabel(label: 'Tanggal Lahir', isDark: isDark),
            GestureDetector(
              onTap: onSelectDOB,
              child: AbsorbPointer(
                child: _ModernTextField(
                  controller: dobCtrl,
                  hint: 'Pilih Tanggal Lahir',
                  icon: Icons.cake_rounded,
                  isDark: isDark,
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _ModernInputLabel(label: 'Gender', isDark: isDark),
            const SizedBox(height: 10),
            _ModernGenderPicker(
              selectedGender: selectedGender,
              options: genderOptions,
              onSelect: onSelectGender,
              isDark: isDark,
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Simpan Perubahan',
              isLoading: isSaving,
              onPressed: onSave,
              gradient: AppColors.gradientPrimary,
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
  final String hint;
  final IconData icon;
  final bool isDark;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;

  const _ModernTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        validator: validator,
        keyboardType: keyboardType,
        readOnly: readOnly,
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.03),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Ringkasan Akun',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Username',
            value: user.username,
            isDark: isDark,
            actionIcon: Icons.copy_rounded,
            onActionTap: onCopyUsername,
          ),
          const Divider(height: 16, thickness: 0.5, color: Colors.black12),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
            isDark: isDark,
            actionIcon: Icons.copy_rounded,
            onActionTap: onCopyEmail,
          ),
          const Divider(height: 16, thickness: 0.5, color: Colors.black12),
          _InfoRow(
            icon: genderIcon,
            label: 'Gender',
            value: genderLabel,
            isDark: isDark,
          ),
          const Divider(height: 16, thickness: 0.5, color: Colors.black12),
          _InfoRow(
            icon: Icons.cake_rounded,
            label: 'Ulang Tahun',
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.03),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings_suggest_rounded,
                    color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Preferensi Aplikasi',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PreferenceSwitch(
            icon: Icons.notifications_active_rounded,
            title: 'Reminder Harian',
            subtitle: 'Kirim pengingat aktivitas harian.',
            value: dailyReminderEnabled,
            onChanged: onDailyReminderChanged,
            isDark: isDark,
          ),
          _PreferenceSwitch(
            icon: Icons.chat_bubble_rounded,
            title: 'Notifikasi Chat',
            subtitle: 'Pemberitahuan pesan masuk.',
            value: chatNotificationsEnabled,
            onChanged: onChatNotificationsChanged,
            isDark: isDark,
          ),
          _PreferenceSwitch(
            icon: Icons.data_usage_rounded,
            title: 'Mode Hemat Data',
            subtitle: 'Batasi penggunaan media berat.',
            value: lowDataModeEnabled,
            onChanged: onLowDataModeChanged,
            isDark: isDark,
          ),
          _PreferenceSwitch(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Tema tampilan gelap/terang.',
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.03),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLogout,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.power_settings_new_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Keluar dari Akun',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                    letterSpacing: -0.2,
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // TODO: Route to staff_management_screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffManagementScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade400,
                        Colors.orange.shade500,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Manajemen Tim & Staff',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Atur role dan hak akses pengguna',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textLight.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark
                      ? Colors.white54
                      : AppColors.textLight.withValues(alpha: 0.5),
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
  final dynamic icon;
  final bool isDark;
  final bool isInstagram;

  const _SocialLinkField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.isInstagram = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? Colors.white54 : Colors.black45,
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
  final VoidCallback onEdit;

  const _SocialMediaCard({
    required this.isDark,
    required this.github,
    required this.instagram,
    required this.discord,
    required this.telegram,
    required this.spotify,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_SocialMediaItem>[
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
    ];
    final visibleItems =
        items.where((item) => item.value.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.link_rounded,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Social Media',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleItems.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: visibleItems
                  .map((item) => _buildSocialQuickIcon(context, item))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          ...items.map((item) => _buildSocialRow(context, item)),
        ],
      ),
    );
  }

  Widget _buildSocialQuickIcon(BuildContext context, _SocialMediaItem item) {
    return _SocialIcon(
      icon: item.icon,
      isInstagram: item.isInstagram,
      isDark: isDark,
      iconColor: item.isInstagram ? null : item.color,
      onTap: () async {
        final success =
            await UrlHelper.launchSocialUrl(item.platform, item.value);
        if (!context.mounted || success) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka ${item.platform}.')),
        );
      },
    );
  }

  Widget _buildSocialRow(BuildContext context, _SocialMediaItem item) {
    final hasValue = item.value.isNotEmpty;
    final normalizedUrl =
        hasValue ? UrlHelper.normalizeSocialUrl(item.platform, item.value) : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasValue
              ? () async {
                  final success = await UrlHelper.launchSocialUrl(
                      item.platform, item.value);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Gagal membuka ${item.platform}.')),
                    );
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: item.isInstagram
                        ? const _InstagramGradientIcon(size: 20)
                        : FaIcon(item.icon, size: 16, color: item.color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.platform,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        hasValue ? normalizedUrl : 'Belum diatur',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight:
                              hasValue ? FontWeight.w600 : FontWeight.w400,
                          color: hasValue
                              ? (isDark ? Colors.white : AppColors.textPrimary)
                              : (isDark ? Colors.white30 : Colors.black26),
                          fontStyle:
                              hasValue ? FontStyle.normal : FontStyle.italic,
                          decoration:
                              hasValue ? TextDecoration.underline : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasValue)
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black38,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
              ],
            ),
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
