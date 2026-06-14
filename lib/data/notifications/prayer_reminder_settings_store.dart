import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_reminder_settings.dart';

abstract class PrayerReminderSettingsRepository {
  Future<PrayerReminderSettings> load();
  Future<void> save(PrayerReminderSettings settings);
}

class PrayerReminderSettingsStore implements PrayerReminderSettingsRepository {
  static const _settingsKey = 'prayer_reminder_settings_v1';

  final SharedPreferencesAsync _preferences;

  PrayerReminderSettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<PrayerReminderSettings> load() async {
    final source = await _preferences.getString(_settingsKey);
    if (source == null) return PrayerReminderSettings.defaults;

    try {
      final json = jsonDecode(source);
      if (json is! Map<String, Object?>) {
        return PrayerReminderSettings.defaults;
      }
      return PrayerReminderSettings.fromJson(json);
    } on FormatException {
      return PrayerReminderSettings.defaults;
    } on ArgumentError {
      return PrayerReminderSettings.defaults;
    }
  }

  @override
  Future<void> save(PrayerReminderSettings settings) {
    return _preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}
