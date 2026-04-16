import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/storage/session_auth_cache.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/domain/entities/reminder_entity.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _authNotificationId = 900001;
  static const String _authChannelId = 'auth_status_channel';
  static const String _chatChannelId = 'chat_message_channel';
  static const String _reminderChannelId = 'reminder_channel';
  static const Duration _reminderLeadTime = Duration(minutes: 15);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _configureTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macImplementation = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await macImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create High Importance Channel for Android
    if (!kIsWeb) {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        const chatChannel = AndroidNotificationChannel(
          _chatChannelId,
          'Pesan Chat',
          description: 'Notifikasi pesan chat baru',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
        await androidImplementation.createNotificationChannel(chatChannel);
        
        const reminderChannel = AndroidNotificationChannel(
          _reminderChannelId,
          'Pengingat',
          description: 'Notifikasi pengingat jadwal',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
        await androidImplementation.createNotificationChannel(reminderChannel);
      }
    }

    _initialized = true;
  }

  Future<void> _configureTimezone() async {
    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (error) {
      debugPrint('[NOTIF] timezone init fallback: $error');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  NotificationDetails _authNotificationDetails() {
    const android = AndroidNotificationDetails(
      _authChannelId,
      'Status Akun',
      channelDescription: 'Notifikasi status login/register',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  NotificationDetails _chatNotificationDetails({String? groupKey}) {
    final android = AndroidNotificationDetails(
      _chatChannelId,
      'Pesan Chat',
      channelDescription: 'Notifikasi pesan chat baru',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      groupKey: groupKey ?? 'chat_group',
      setAsGroupSummary: groupKey == null,
      styleInformation: const DefaultStyleInformation(true, true),
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'chat_group',
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  NotificationDetails _reminderNotificationDetails() {
    const android = AndroidNotificationDetails(
      _reminderChannelId,
      'Pengingat',
      channelDescription: 'Notifikasi pengingat jadwal',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  Future<void> showAuthSuccess({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(
      _authNotificationId,
      title,
      body,
      _authNotificationDetails(),
      payload: 'auth:success',
    );
  }

  Future<void> showChatMessage(ChatMessageEntity message) async {
    await initialize();

    final sender = message.senderUsername.trim().isEmpty
        ? 'Pesan Baru'
        : message.senderUsername.trim();
    final preview = _chatPreview(message);

    await _plugin.show(
      _chatNotificationId(message.chatId),
      sender,
      preview,
      _chatNotificationDetails(groupKey: 'chat_${message.chatId}'),
      payload: 'chat:${message.chatId}',
    );

    // Show a summary notification for the whole chat group (Android requirement for grouping)
    await _plugin.show(
      _stableInt('chat_summary'),
      'Pesan Baru',
      'Kamu memiliki pesan baru',
      _chatNotificationDetails(),
      payload: 'chat_summary',
    );
  }

  String _chatPreview(ChatMessageEntity message) {
    final type = message.type.toLowerCase().trim();
    if (type == 'image') {
      final caption = message.text.trim();
      return caption.isEmpty ? 'Mengirim gambar' : 'Gambar: $caption';
    }
    if (type == 'audio' || type == 'voice') return 'Mengirim voice note';
    if (type == 'file') return 'Mengirim file';

    final text = message.text.trim();
    return text.isEmpty ? 'Pesan baru' : text;
  }

  Future<void> scheduleReminder(ReminderEntity reminder) async {
    await initialize();
    await cancelReminder(reminder.id);

    if (reminder.isCompleted) {
      return;
    }

    final scheduledAt = reminder.dateTime.toLocal();
    if (!scheduledAt.isAfter(DateTime.now())) {
      return;
    }

    final dueTitle = 'Pengingat: ${reminder.title}';
    final dueBody = reminder.description.trim().isEmpty
        ? 'Waktunya menjalankan pengingat kamu.'
        : reminder.description.trim();

    await _scheduleReminderNotification(
      notificationId: _reminderDueNotificationId(reminder.id),
      title: dueTitle,
      body: dueBody,
      scheduledAt: scheduledAt,
      payload: 'reminder:due:${reminder.id}',
    );

    final now = DateTime.now();
    final soonAt = scheduledAt.subtract(_reminderLeadTime);
    DateTime? nearNotificationTime;
    if (soonAt.isAfter(now)) {
      nearNotificationTime = soonAt;
    } else if (scheduledAt.difference(now) > const Duration(minutes: 1)) {
      // If reminder is less than 15 minutes away, show a near-time alert soon.
      nearNotificationTime = now.add(const Duration(seconds: 10));
    }

    if (nearNotificationTime != null) {
      await _scheduleReminderNotification(
        notificationId: _reminderSoonNotificationId(reminder.id),
        title: 'Sebentar lagi: ${reminder.title}',
        body:
            'Pengingat kamu akan berjalan pada ${_formatTimeLabel(scheduledAt)}.',
        scheduledAt: nearNotificationTime,
        payload: 'reminder:soon:${reminder.id}',
      );
    }
  }

  Future<void> _scheduleReminderNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      _reminderNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> cancelReminder(String reminderId) async {
    await initialize();
    await _plugin.cancel(_reminderDueNotificationId(reminderId));
    await _plugin.cancel(_reminderSoonNotificationId(reminderId));
    // Backward compatibility: old one-shot reminder ID.
    await _plugin.cancel(_reminderNotificationId(reminderId));
  }

  Future<void> syncReminderNotifications(List<ReminderEntity> reminders) async {
    await initialize();

    final activeReminderIds = reminders
        .where((reminder) =>
            !reminder.isCompleted && reminder.dateTime.isAfter(DateTime.now()))
        .map((reminder) => reminder.id)
        .toSet();

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final reminderId = _extractReminderId(request.payload ?? '');
      if (reminderId == null) {
        continue;
      }

      if (!activeReminderIds.contains(reminderId)) {
        await _plugin.cancel(request.id);
      }
    }

    for (final reminder in reminders) {
      await scheduleReminder(reminder);
    }
  }

  String? _extractReminderId(String payload) {
    if (payload.startsWith('reminder:due:')) {
      final id = payload.replaceFirst('reminder:due:', '').trim();
      return id.isEmpty ? null : id;
    }

    if (payload.startsWith('reminder:soon:')) {
      final id = payload.replaceFirst('reminder:soon:', '').trim();
      return id.isEmpty ? null : id;
    }

    // Backward compatibility: old payload style `reminder:<id>`.
    if (payload.startsWith('reminder:')) {
      final id = payload.replaceFirst('reminder:', '').trim();
      return id.isEmpty ? null : id;
    }

    return null;
  }

  Future<void> syncReminderNotificationsFromStorage() async {
    await initialize();
    final box = Hive.box(HiveBoxes.reminders);
    final activeUserId = _activeUserId();
    if (activeUserId == null || activeUserId.isEmpty) {
      await syncReminderNotifications(const []);
      return;
    }

    final reminders = <ReminderEntity>[];
    for (final raw in box.values) {
      Map<String, dynamic>? map;
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map = Map<String, dynamic>.from(decoded);
        }
      } else if (raw is Map) {
        map = Map<String, dynamic>.from(raw);
      }

      if (map == null) {
        continue;
      }

      final ownerId = (map['userId'] ?? '').toString().trim();
      if (ownerId.isNotEmpty && ownerId != activeUserId) {
        continue;
      }
      reminders.add(ReminderEntity.fromJson(map));
    }

    await syncReminderNotifications(reminders);
  }

  String? _activeUserId() {
    final sessionUserId = SessionAuthCache.user?.id.trim();
    if (sessionUserId != null && sessionUserId.isNotEmpty) {
      return sessionUserId;
    }

    final cachedUser = HiveService.user;
    final rawId =
        (cachedUser?['id'] ?? cachedUser?['_id'] ?? '').toString().trim();
    return rawId.isEmpty ? null : rawId;
  }

  int _reminderDueNotificationId(String reminderId) {
    return _stableInt('reminder:due:$reminderId');
  }

  int _reminderSoonNotificationId(String reminderId) {
    return _stableInt('reminder:soon:$reminderId');
  }

  int _reminderNotificationId(String reminderId) {
    // Backward compatibility ID used by older versions.
    return _stableInt('reminder:$reminderId');
  }

  int _chatNotificationId(String chatId) {
    return _stableInt('chat:$chatId');
  }

  int _stableInt(String source) {
    const int fnvOffsetBasis = 2166136261;
    const int fnvPrime = 16777619;
    int hash = fnvOffsetBasis;
    for (final unit in source.codeUnits) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0x7fffffff;
    }
    return hash;
  }
}
