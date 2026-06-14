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

  Future<bool> saveSettings(PrayerReminderSettings settings) async {
    await _settingsStore.save(settings);

    if (!settings.enabled) {
      await _scheduler.cancel();
      return true;
    }

    final granted = await _scheduler.requestPermission();
    if (!granted) return false;

    await _scheduler.schedule(settings);
    return true;
  }

  Future<void> snoozeCurrentReminder() async {
    final settings = await _settingsStore.load();
    if (!settings.enabled) return;
    await _scheduler.snooze(settings);
  }
}
