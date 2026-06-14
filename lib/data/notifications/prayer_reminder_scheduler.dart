import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'prayer_reminder_settings.dart';

abstract class PrayerReminderScheduler {
  Future<bool> requestPermission();
  Future<void> schedule(PrayerReminderSettings settings);
  Future<void> cancel();
  Future<void> snooze(PrayerReminderSettings settings);
}

class LocalPrayerReminderScheduler implements PrayerReminderScheduler {
  static const int _dailyReminderId = 4001;
  static const int _snoozeReminderId = 4002;
  static const String _channelId = 'quran_reading_reminders';
  static const String snoozeActionId = 'snooze_reading_reminder';

  final FlutterLocalNotificationsPlugin _notifications;
  final Future<void> Function()? _onSnoozeRequested;
  final Locale Function() _localeProvider;
  bool _initialized = false;

  LocalPrayerReminderScheduler({
    FlutterLocalNotificationsPlugin? notifications,
    Future<void> Function()? onSnoozeRequested,
    Locale Function()? localeProvider,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _onSnoozeRequested = onSnoozeRequested,
       _localeProvider =
           localeProvider ?? (() => PlatformDispatcher.instance.locale);

  @override
  Future<bool> requestPermission() async {
    await _initialize();
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    if (granted == false) return false;

    final exactAlarmsGranted = await android?.requestExactAlarmsPermission();
    return exactAlarmsGranted ?? true;
  }

  @override
  Future<void> schedule(PrayerReminderSettings settings) async {
    await _initialize();
    await _notifications.cancel(id: _dailyReminderId);

    if (!settings.enabled) return;

    final scheduledAt = tz.TZDateTime.from(
      settings.nextReminderAfter(DateTime.now()),
      tz.local,
    );
    final text = _PrayerReminderNotificationText.forLocale(
      _localeProvider(),
      prayer: settings.prayer,
    );

    await _notifications.zonedSchedule(
      id: _dailyReminderId,
      title: text.dailyTitle,
      body: text.dailyBody,
      scheduledDate: scheduledAt,
      notificationDetails: _notificationDetails(text),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'reading-reminder:${settings.prayer.name}',
    );
  }

  @override
  Future<void> cancel() async {
    await _initialize();
    await _notifications.cancel(id: _dailyReminderId);
    await _notifications.cancel(id: _snoozeReminderId);
  }

  @override
  Future<void> snooze(PrayerReminderSettings settings) async {
    await _initialize();
    final scheduledAt = tz.TZDateTime.from(
      DateTime.now().add(Duration(minutes: settings.snoozeMinutes)),
      tz.local,
    );
    final text = _PrayerReminderNotificationText.forLocale(_localeProvider());

    await _notifications.zonedSchedule(
      id: _snoozeReminderId,
      title: text.snoozeTitle,
      body: text.snoozeBody,
      scheduledDate: scheduledAt,
      notificationDetails: _notificationDetails(text),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'reading-reminder:snooze',
    );
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    _initialized = true;
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    if (response.actionId != snoozeActionId) return;
    await _onSnoozeRequested?.call();
  }

  NotificationDetails _notificationDetails(
    _PrayerReminderNotificationText text,
  ) {
    final android = AndroidNotificationDetails(
      _channelId,
      text.channelName,
      channelDescription: text.channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      actions: [
        AndroidNotificationAction(snoozeActionId, text.snoozeActionTitle),
      ],
    );

    const darwin = DarwinNotificationDetails();
    return NotificationDetails(android: android, iOS: darwin, macOS: darwin);
  }
}

class _PrayerReminderNotificationText {
  final String dailyTitle;
  final String dailyBody;
  final String channelName;
  final String channelDescription;
  final String snoozeTitle;
  final String snoozeBody;
  final String snoozeActionTitle;

  const _PrayerReminderNotificationText({
    required this.dailyTitle,
    required this.dailyBody,
    required this.channelName,
    required this.channelDescription,
    required this.snoozeTitle,
    required this.snoozeBody,
    required this.snoozeActionTitle,
  });

  factory _PrayerReminderNotificationText.forLocale(
    Locale locale, {
    PrayerReminderPrayer? prayer,
  }) {
    final isArabic = locale.languageCode.toLowerCase() == 'ar';
    final prayerName = prayer == null
        ? (isArabic ? 'الصلاة' : 'Prayer')
        : _localizedPrayerName(prayer, isArabic: isArabic);

    if (isArabic) {
      return _PrayerReminderNotificationText(
        dailyTitle: 'لحظة هادئة مع القرآن',
        dailyBody: 'انتهى وقت $prayerName. اقرأ بعض الآيات؟',
        channelName: 'تذكيرات قراءة القرآن',
        channelDescription: 'تذكيرات لطيفة لقراءة القرآن بعد الصلاة.',
        snoozeTitle: 'تذكير بالقرآن',
        snoozeBody: 'حان وقت تذكيرك بقراءة القرآن.',
        snoozeActionTitle: 'ذكرني لاحقًا',
      );
    }

    return _PrayerReminderNotificationText(
      dailyTitle: 'A quiet moment for Quran',
      dailyBody: '$prayerName has passed. Read a few ayat?',
      channelName: 'Quran reading reminders',
      channelDescription: 'Gentle reminders to read Quran after prayer.',
      snoozeTitle: 'Quran reminder',
      snoozeBody: 'Your gentle reading reminder is ready.',
      snoozeActionTitle: 'Remind me later',
    );
  }

  static String _localizedPrayerName(
    PrayerReminderPrayer prayer, {
    required bool isArabic,
  }) {
    if (!isArabic) return prayer.label;

    return switch (prayer) {
      PrayerReminderPrayer.fajr => 'الفجر',
      PrayerReminderPrayer.dhuhr => 'الظهر',
      PrayerReminderPrayer.asr => 'العصر',
      PrayerReminderPrayer.maghrib => 'المغرب',
      PrayerReminderPrayer.isha => 'العشاء',
    };
  }
}
