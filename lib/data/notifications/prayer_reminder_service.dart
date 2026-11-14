import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../localization/app_locale_store.dart';
import 'prayer_reminder_scheduler.dart';
import 'prayer_reminder_settings.dart';
import 'prayer_reminder_settings_store.dart';

class PrayerReminderService {
  final PrayerReminderSettingsRepository _settingsStore;
  final PrayerReminderScheduler _scheduler;

  const PrayerReminderService({
    required PrayerReminderSettingsRepository settingsStore,
    required PrayerReminderScheduler scheduler,
  }) : _settingsStore = settingsStore,
       _scheduler = scheduler;

  Future<PrayerReminderSettings> loadSettings() => _settingsStore.load();

  Future<void> synchronizeTimezone() async {
    if (!await _scheduler.synchronizeTimezone()) return;

    final settings = await _settingsStore.load();
    if (!settings.enabled) return;
    await _scheduler.schedule(settings);
  }

  Future<bool> saveSettings(PrayerReminderSettings settings) async {
    if (!settings.enabled) {
      await _settingsStore.save(settings);
      await _scheduler.cancel();
      return true;
    }

    final granted = await _scheduler.requestPermission();
    if (!granted) {
      await _settingsStore.save(settings.copyWith(enabled: false));
      await _scheduler.cancel();
      return false;
    }

    await _settingsStore.save(settings);
    await _scheduler.schedule(settings);
    return true;
  }

  Future<void> snoozeCurrentReminder() async {
    final settings = await _settingsStore.load();
    if (!settings.enabled) return;
    await _scheduler.snooze(settings);
  }
}

/// Android delivers reminder actions that do not open the app to a background
/// isolate, so this must be a top-level entry point.
@pragma('vm:entry-point')
Future<void> snoozeReminderInBackground(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  // Matches the app's default language when none has been chosen.
  final languageCode =
      await SharedPreferencesAppLocaleStore().readLanguageCode() ?? 'ar';
  await handleReminderResponse(
    response,
    PrayerReminderService(
      settingsStore: PrayerReminderSettingsStore(),
      scheduler: LocalPrayerReminderScheduler(
        localeProvider: () => Locale(languageCode),
      ),
    ),
  );
}

Future<void> handleReminderResponse(
  NotificationResponse response,
  PrayerReminderService service,
) async {
  if (response.actionId != LocalPrayerReminderScheduler.snoozeActionId) return;
  await service.snoozeCurrentReminder();
}
