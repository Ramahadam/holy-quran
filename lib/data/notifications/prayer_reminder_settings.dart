enum PrayerReminderPrayer {
  fajr('Fajr'),
  dhuhr('Dhuhr'),
  asr('Asr'),
  maghrib('Maghrib'),
  isha('Isha');

  final String label;

  const PrayerReminderPrayer(this.label);
}

class PrayerReminderSettings {
  final bool enabled;
  final PrayerReminderPrayer prayer;
  final int prayerTimeMinutes;
  final int offsetMinutes;
  final int snoozeMinutes;

  const PrayerReminderSettings({
    required this.enabled,
    required this.prayer,
    required this.prayerTimeMinutes,
    required this.offsetMinutes,
    required this.snoozeMinutes,
  });

  static const PrayerReminderSettings defaults = PrayerReminderSettings(
    enabled: false,
    prayer: PrayerReminderPrayer.maghrib,
    prayerTimeMinutes: 18 * 60,
    offsetMinutes: 10,
    snoozeMinutes: 15,
  );

  PrayerReminderSettings copyWith({
    bool? enabled,
    PrayerReminderPrayer? prayer,
    int? prayerTimeMinutes,
    int? offsetMinutes,
    int? snoozeMinutes,
  }) {
    return PrayerReminderSettings(
      enabled: enabled ?? this.enabled,
      prayer: prayer ?? this.prayer,
      prayerTimeMinutes: prayerTimeMinutes ?? this.prayerTimeMinutes,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }

  DateTime nextReminderAfter(DateTime now) {
    _validate();

    final prayerHour = prayerTimeMinutes ~/ 60;
    final prayerMinute = prayerTimeMinutes % 60;
    var reminder = DateTime(
      now.year,
      now.month,
      now.day,
      prayerHour,
      prayerMinute,
    ).add(Duration(minutes: offsetMinutes));

    if (!reminder.isAfter(now)) {
      reminder = reminder.add(const Duration(days: 1));
    }

    return reminder;
  }

  Map<String, Object> toJson() {
    _validate();

    return {
      'enabled': enabled,
      'prayer': prayer.name,
      'prayerTimeMinutes': prayerTimeMinutes,
      'offsetMinutes': offsetMinutes,
      'snoozeMinutes': snoozeMinutes,
    };
  }

  static PrayerReminderSettings fromJson(Map<String, Object?> json) {
    final prayerName = json['prayer']?.toString();
    final prayer = PrayerReminderPrayer.values.firstWhere(
      (value) => value.name == prayerName,
      orElse: () => defaults.prayer,
    );

    final settings = PrayerReminderSettings(
      enabled: json['enabled'] == true,
      prayer: prayer,
      prayerTimeMinutes:
          _intValue(json['prayerTimeMinutes']) ?? defaults.prayerTimeMinutes,
      offsetMinutes: _intValue(json['offsetMinutes']) ?? defaults.offsetMinutes,
      snoozeMinutes: _intValue(json['snoozeMinutes']) ?? defaults.snoozeMinutes,
    );
    settings._validate();
    return settings;
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _validate() {
    if (prayerTimeMinutes < 0 || prayerTimeMinutes > 23 * 60 + 59) {
      throw ArgumentError.value(
        prayerTimeMinutes,
        'prayerTimeMinutes',
        'Must be within a local day.',
      );
    }
    if (offsetMinutes < 0 || offsetMinutes > 180) {
      throw ArgumentError.value(
        offsetMinutes,
        'offsetMinutes',
        'Must be between 0 and 180 minutes.',
      );
    }
    if (snoozeMinutes < 1 || snoozeMinutes > 120) {
      throw ArgumentError.value(
        snoozeMinutes,
        'snoozeMinutes',
        'Must be between 1 and 120 minutes.',
      );
    }
  }
}
