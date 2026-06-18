import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/notifications/prayer_reminder_scheduler.dart';
import 'package:holy_quran_app/data/notifications/prayer_reminder_service.dart';
import 'package:holy_quran_app/data/notifications/prayer_reminder_settings.dart';
import 'package:holy_quran_app/data/notifications/prayer_reminder_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerReminderSettings', () {
    test('calculates the next reminder today when still upcoming', () {
      final settings = PrayerReminderSettings.defaults.copyWith(
        prayerTimeMinutes: 18 * 60,
        offsetMinutes: 10,
      );

      final next = settings.nextReminderAfter(DateTime(2026, 6, 13, 17, 30));

      expect(next, DateTime(2026, 6, 13, 18, 10));
    });

    test(
      'rolls the next reminder to tomorrow after the reminder time passes',
      () {
        final settings = PrayerReminderSettings.defaults.copyWith(
          prayerTimeMinutes: 18 * 60,
          offsetMinutes: 10,
        );

        final next = settings.nextReminderAfter(DateTime(2026, 6, 13, 18, 11));

        expect(next, DateTime(2026, 6, 14, 18, 10));
      },
    );

    test('rejects invalid prayer, offset, and snooze ranges', () {
      expect(
        () => PrayerReminderSettings.defaults
            .copyWith(prayerTimeMinutes: 24 * 60)
            .toJson(),
        throwsArgumentError,
      );
      expect(
        () => PrayerReminderSettings.defaults
            .copyWith(offsetMinutes: 181)
            .toJson(),
        throwsArgumentError,
      );
      expect(
        () =>
            PrayerReminderSettings.defaults.copyWith(snoozeMinutes: 0).toJson(),
        throwsArgumentError,
      );
    });
  });

  group('Android reminder manifest', () {
    test('declares exact alarm permission and notification receivers', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android.permission.SCHEDULE_EXACT_ALARM'));
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
        ),
      );
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
        ),
      );
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver',
        ),
      );
    });
  });

  group('LocalPrayerReminderScheduler', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final calls = <MethodCall>[];

    setUp(() {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            calls.add(methodCall);
            return switch (methodCall.method) {
              'initialize' => true,
              'requestNotificationsPermission' => true,
              'requestExactAlarmsPermission' => true,
              _ => null,
            };
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      calls.clear();
    });

    test(
      'requests notification and exact alarm permissions on Android',
      () async {
        final scheduler = LocalPrayerReminderScheduler();

        final granted = await scheduler.requestPermission();

        expect(granted, isTrue);
        expect(
          calls.map((call) => call.method),
          containsAllInOrder([
            'initialize',
            'requestNotificationsPermission',
            'requestExactAlarmsPermission',
          ]),
        );
      },
    );

    test(
      'schedules daily reminders as exact allow-while-idle alarms',
      () async {
        final scheduler = LocalPrayerReminderScheduler();
        final settings = PrayerReminderSettings.defaults.copyWith(
          enabled: true,
          prayerTimeMinutes: 0,
          offsetMinutes: 0,
        );

        await scheduler.schedule(settings);

        final scheduleCall = calls.singleWhere(
          (call) => call.method == 'zonedSchedule',
        );
        final arguments = scheduleCall.arguments as Map<Object?, Object?>;
        final platformSpecifics =
            arguments['platformSpecifics'] as Map<Object?, Object?>;
        expect(platformSpecifics['scheduleMode'], 'exactAllowWhileIdle');
      },
    );

    test('uses Arabic notification text for Arabic locales', () async {
      final scheduler = LocalPrayerReminderScheduler(
        localeProvider: () => const Locale('ar'),
      );
      final settings = PrayerReminderSettings.defaults.copyWith(
        enabled: true,
        prayer: PrayerReminderPrayer.maghrib,
        prayerTimeMinutes: 0,
        offsetMinutes: 0,
      );

      await scheduler.schedule(settings);

      final arguments = _scheduledNotificationArguments(calls);
      final platformSpecifics =
          arguments['platformSpecifics'] as Map<Object?, Object?>;
      final actions = (platformSpecifics['actions'] as List<Object?>)
          .cast<Map<Object?, Object?>>();
      expect(arguments['title'], 'لحظة هادئة مع القرآن');
      expect(arguments['body'], 'انتهى وقت المغرب. اقرأ بعض الآيات؟');
      expect(platformSpecifics['channelName'], 'تذكيرات قراءة القرآن');
      expect(
        platformSpecifics['channelDescription'],
        'تذكيرات لطيفة لقراءة القرآن بعد الصلاة.',
      );
      expect(actions.single['title'], 'ذكرني لاحقًا');
    });

    test('uses English notification text for non-Arabic locales', () async {
      final scheduler = LocalPrayerReminderScheduler(
        localeProvider: () => const Locale('en'),
      );
      final settings = PrayerReminderSettings.defaults.copyWith(
        enabled: true,
        prayer: PrayerReminderPrayer.maghrib,
        prayerTimeMinutes: 0,
        offsetMinutes: 0,
      );

      await scheduler.schedule(settings);

      final arguments = _scheduledNotificationArguments(calls);
      final platformSpecifics =
          arguments['platformSpecifics'] as Map<Object?, Object?>;
      final actions = (platformSpecifics['actions'] as List<Object?>)
          .cast<Map<Object?, Object?>>();
      expect(arguments['title'], 'A quiet moment for Quran');
      expect(arguments['body'], 'Maghrib has passed. Read a few ayat?');
      expect(platformSpecifics['channelName'], 'Quran reading reminders');
      expect(
        platformSpecifics['channelDescription'],
        'Gentle reminders to read Quran after prayer.',
      );
      expect(actions.single['title'], 'Remind me later');
    });

    test(
      'schedules snoozed reminders as exact allow-while-idle alarms',
      () async {
        final scheduler = LocalPrayerReminderScheduler();
        final settings = PrayerReminderSettings.defaults.copyWith(
          enabled: true,
        );

        await scheduler.snooze(settings);

        final scheduleCall = calls.singleWhere(
          (call) => call.method == 'zonedSchedule',
        );
        final arguments = scheduleCall.arguments as Map<Object?, Object?>;
        final platformSpecifics =
            arguments['platformSpecifics'] as Map<Object?, Object?>;
        expect(platformSpecifics['scheduleMode'], 'exactAllowWhileIdle');
      },
    );
  });

  group('PrayerReminderService', () {
    test(
      'saves and schedules enabled reminders after permission is granted',
      () async {
        final store = _FakePrayerReminderSettingsStore();
        final scheduler = _FakePrayerReminderScheduler(permissionGranted: true);
        final service = PrayerReminderService(
          settingsStore: store,
          scheduler: scheduler,
        );
        final settings = PrayerReminderSettings.defaults.copyWith(
          enabled: true,
        );

        final saved = await service.saveSettings(settings);

        expect(saved, isTrue);
        expect(store.saved, settings);
        expect(scheduler.permissionRequests, 1);
        expect(scheduler.scheduled, settings);
        expect(scheduler.cancelCount, 0);
      },
    );

    test('saves but does not schedule when permission is denied', () async {
      final store = _FakePrayerReminderSettingsStore();
      final scheduler = _FakePrayerReminderScheduler(permissionGranted: false);
      final service = PrayerReminderService(
        settingsStore: store,
        scheduler: scheduler,
      );
      final settings = PrayerReminderSettings.defaults.copyWith(enabled: true);

      final saved = await service.saveSettings(settings);

      expect(saved, isFalse);
      expect(store.saved, settings);
      expect(scheduler.permissionRequests, 1);
      expect(scheduler.scheduled, isNull);
    });

    test('cancels scheduled notifications when disabled', () async {
      final store = _FakePrayerReminderSettingsStore();
      final scheduler = _FakePrayerReminderScheduler(permissionGranted: true);
      final service = PrayerReminderService(
        settingsStore: store,
        scheduler: scheduler,
      );

      final saved = await service.saveSettings(PrayerReminderSettings.defaults);

      expect(saved, isTrue);
      expect(scheduler.cancelCount, 1);
      expect(scheduler.permissionRequests, 0);
    });

    test('snoozes only when stored reminders are enabled', () async {
      final store = _FakePrayerReminderSettingsStore(
        loaded: PrayerReminderSettings.defaults.copyWith(enabled: true),
      );
      final scheduler = _FakePrayerReminderScheduler(permissionGranted: true);
      final service = PrayerReminderService(
        settingsStore: store,
        scheduler: scheduler,
      );

      await service.snoozeCurrentReminder();

      expect(scheduler.snoozed, store.loaded);
    });
  });
}

Map<Object?, Object?> _scheduledNotificationArguments(List<MethodCall> calls) {
  final scheduleCall = calls.singleWhere(
    (call) => call.method == 'zonedSchedule',
  );
  return scheduleCall.arguments as Map<Object?, Object?>;
}

class _FakePrayerReminderSettingsStore
    implements PrayerReminderSettingsRepository {
  PrayerReminderSettings loaded;
  PrayerReminderSettings? saved;

  _FakePrayerReminderSettingsStore({PrayerReminderSettings? loaded})
    : loaded = loaded ?? PrayerReminderSettings.defaults;

  @override
  Future<PrayerReminderSettings> load() async => loaded;

  @override
  Future<void> save(PrayerReminderSettings settings) async {
    saved = settings;
    loaded = settings;
  }
}

class _FakePrayerReminderScheduler implements PrayerReminderScheduler {
  final bool permissionGranted;
  int permissionRequests = 0;
  int cancelCount = 0;
  PrayerReminderSettings? scheduled;
  PrayerReminderSettings? snoozed;

  _FakePrayerReminderScheduler({required this.permissionGranted});

  @override
  Future<void> cancel() async {
    cancelCount += 1;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return permissionGranted;
  }

  @override
  Future<void> schedule(PrayerReminderSettings settings) async {
    scheduled = settings;
  }

  @override
  Future<void> snooze(PrayerReminderSettings settings) async {
    snoozed = settings;
  }
}
