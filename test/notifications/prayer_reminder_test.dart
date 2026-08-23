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
      'returns true when Android permissions are already authorized',
      () async {
        final scheduler = LocalPrayerReminderScheduler(
          localTimezoneNameProvider: () async => 'Etc/UTC',
        );

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

    test('stops when Android notification permission is denied', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            calls.add(methodCall);
            return switch (methodCall.method) {
              'initialize' => true,
              'requestNotificationsPermission' => false,
              _ => null,
            };
          });
      final scheduler = LocalPrayerReminderScheduler(
        localTimezoneNameProvider: () async => 'Etc/UTC',
      );

      final granted = await scheduler.requestPermission();

      expect(granted, isFalse);
      expect(
        calls.map((call) => call.method),
        isNot(contains('requestExactAlarmsPermission')),
      );
    });

    test(
      'returns false when the Android exact alarm permission flow is cancelled',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (methodCall) async {
              calls.add(methodCall);
              return switch (methodCall.method) {
                'initialize' => true,
                'requestNotificationsPermission' => true,
                'requestExactAlarmsPermission' => false,
                _ => null,
              };
            });
        final scheduler = LocalPrayerReminderScheduler(
          localTimezoneNameProvider: () async => 'Etc/UTC',
        );

        final granted = await scheduler.requestPermission();

        expect(granted, isFalse);
      },
    );

    test('returns the iOS notification permission result', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      IOSFlutterLocalNotificationsPlugin.registerWith();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            calls.add(methodCall);
            return switch (methodCall.method) {
              'initialize' => true,
              'requestPermissions' => false,
              _ => null,
            };
          });
      final scheduler = LocalPrayerReminderScheduler(
        localTimezoneNameProvider: () async => 'Etc/UTC',
      );

      final granted = await scheduler.requestPermission();

      expect(granted, isFalse);
      expect(
        calls.map((call) => call.method),
        containsAllInOrder(['initialize', 'requestPermissions']),
      );
    });

    test(
      'schedules daily reminders as exact allow-while-idle alarms',
      () async {
        final scheduler = LocalPrayerReminderScheduler(
          localTimezoneNameProvider: () async => 'Etc/UTC',
        );
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
        localTimezoneNameProvider: () async => 'Etc/UTC',
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
        localTimezoneNameProvider: () async => 'Etc/UTC',
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
        final scheduler = LocalPrayerReminderScheduler(
          localTimezoneNameProvider: () async => 'Etc/UTC',
        );
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

    test(
      'keeps the selected wall-clock time across a DST transition',
      () async {
        final scheduler = LocalPrayerReminderScheduler(
          localTimezoneNameProvider: () async => 'America/New_York',
          nowProvider: () => DateTime.utc(2026, 3, 7, 15),
        );
        final settings = PrayerReminderSettings.defaults.copyWith(
          enabled: true,
          prayerTimeMinutes: 9 * 60,
          offsetMinutes: 0,
        );

        await scheduler.schedule(settings);

        final arguments = _scheduledNotificationArguments(calls);
        expect(arguments['timeZoneName'], 'America/New_York');
        expect(arguments['scheduledDateTime'], '2026-03-08T09:00:00');
        expect(
          arguments['scheduledDateTimeISO8601'],
          '2026-03-08T09:00:00.000-0400',
        );
      },
    );

    test('uses the device wall-clock time in a non-DST timezone', () async {
      final scheduler = LocalPrayerReminderScheduler(
        localTimezoneNameProvider: () async => 'Asia/Dubai',
        nowProvider: () => DateTime.utc(2026, 6, 1, 6),
      );
      final settings = PrayerReminderSettings.defaults.copyWith(
        enabled: true,
        prayerTimeMinutes: 9 * 60,
        offsetMinutes: 0,
      );

      await scheduler.schedule(settings);

      final arguments = _scheduledNotificationArguments(calls);
      expect(arguments['timeZoneName'], 'Asia/Dubai');
      expect(arguments['scheduledDateTime'], '2026-06-02T09:00:00');
      expect(
        arguments['scheduledDateTimeISO8601'],
        '2026-06-02T09:00:00.000+0400',
      );
    });
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

    test(
      'keeps reminders disabled and cancels pending alarms when permission is denied',
      () async {
        final store = _FakePrayerReminderSettingsStore();
        final scheduler = _FakePrayerReminderScheduler(
          permissionGranted: false,
        );
        final service = PrayerReminderService(
          settingsStore: store,
          scheduler: scheduler,
        );
        final settings = PrayerReminderSettings.defaults.copyWith(
          enabled: true,
        );

        final saved = await service.saveSettings(settings);

        expect(saved, isFalse);
        expect(store.saved?.enabled, isFalse);
        expect(scheduler.permissionRequests, 1);
        expect(scheduler.scheduled, isNull);
        expect(scheduler.cancelCount, 1);
      },
    );

    test(
      'does not schedule after restart when the enable permission flow failed',
      () async {
        final store = _FakePrayerReminderSettingsStore();
        final deniedScheduler = _FakePrayerReminderScheduler(
          permissionGranted: false,
        );
        final enabledSettings = PrayerReminderSettings.defaults.copyWith(
          enabled: true,
        );

        await PrayerReminderService(
          settingsStore: store,
          scheduler: deniedScheduler,
        ).saveSettings(enabledSettings);
        final restartScheduler = _FakePrayerReminderScheduler(
          permissionGranted: true,
          timezoneChanged: true,
        );
        await PrayerReminderService(
          settingsStore: store,
          scheduler: restartScheduler,
        ).synchronizeTimezone();

        expect(store.loaded.enabled, isFalse);
        expect(restartScheduler.scheduled, isNull);
      },
    );

    test('allows enabling after permission is later granted', () async {
      final store = _FakePrayerReminderSettingsStore();
      final settings = PrayerReminderSettings.defaults.copyWith(enabled: true);
      await PrayerReminderService(
        settingsStore: store,
        scheduler: _FakePrayerReminderScheduler(permissionGranted: false),
      ).saveSettings(settings);
      final grantedScheduler = _FakePrayerReminderScheduler(
        permissionGranted: true,
      );

      final saved = await PrayerReminderService(
        settingsStore: store,
        scheduler: grantedScheduler,
      ).saveSettings(settings);

      expect(saved, isTrue);
      expect(store.loaded.enabled, isTrue);
      expect(grantedScheduler.scheduled, settings);
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

    test(
      'reschedules an enabled reminder after the timezone changes',
      () async {
        final settings = PrayerReminderSettings.defaults.copyWith(
          enabled: true,
        );
        final store = _FakePrayerReminderSettingsStore(loaded: settings);
        final scheduler = _FakePrayerReminderScheduler(
          permissionGranted: true,
          timezoneChanged: true,
        );
        final service = PrayerReminderService(
          settingsStore: store,
          scheduler: scheduler,
        );

        await service.synchronizeTimezone();

        expect(scheduler.timezoneSynchronizations, 1);
        expect(scheduler.scheduled, settings);
        expect(scheduler.permissionRequests, 0);
      },
    );

    test('does not reschedule when the timezone is unchanged', () async {
      final store = _FakePrayerReminderSettingsStore(
        loaded: PrayerReminderSettings.defaults.copyWith(enabled: true),
      );
      final scheduler = _FakePrayerReminderScheduler(
        permissionGranted: true,
        timezoneChanged: false,
      );
      final service = PrayerReminderService(
        settingsStore: store,
        scheduler: scheduler,
      );

      await service.synchronizeTimezone();

      expect(scheduler.timezoneSynchronizations, 1);
      expect(scheduler.scheduled, isNull);
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
  final bool timezoneChanged;
  int permissionRequests = 0;
  int cancelCount = 0;
  int timezoneSynchronizations = 0;
  PrayerReminderSettings? scheduled;
  PrayerReminderSettings? snoozed;

  _FakePrayerReminderScheduler({
    required this.permissionGranted,
    this.timezoneChanged = false,
  });

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
  Future<bool> synchronizeTimezone() async {
    timezoneSynchronizations += 1;
    return timezoneChanged;
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
