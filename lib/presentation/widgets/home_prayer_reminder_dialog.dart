import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications/prayer_reminder_settings.dart';
import '../../l10n/l10n.dart';
import '../providers/quran_providers.dart';
import 'home_dialog.dart';

class HomePrayerReminderDialog extends ConsumerStatefulWidget {
  const HomePrayerReminderDialog({super.key});

  @override
  ConsumerState<HomePrayerReminderDialog> createState() =>
      _HomePrayerReminderDialogState();
}

class _HomePrayerReminderDialogState
    extends ConsumerState<HomePrayerReminderDialog> {
  bool _initialized = false;
  bool _saving = false;
  bool _enabled = PrayerReminderSettings.defaults.enabled;
  PrayerReminderPrayer _prayer = PrayerReminderSettings.defaults.prayer;
  int _prayerTimeMinutes = PrayerReminderSettings.defaults.prayerTimeMinutes;
  int _offsetMinutes = PrayerReminderSettings.defaults.offsetMinutes;
  int _snoozeMinutes = PrayerReminderSettings.defaults.snoozeMinutes;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(prayerReminderSettingsProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return settingsAsync.when(
      loading: () => HomeDialog(
        dialogKey: const ValueKey('homeDialog-remindersLoading'),
        headerKey: const ValueKey('homeDialogHeader-remindersLoading'),
        icon: Icons.notifications_active_outlined,
        title: l10n.readingReminders,
        subtitle: l10n.loadingReminderSettings,
        content: SizedBox(
          height: 96,
          child: Center(
            child: Semantics(
              label: l10n.loadingReminderSettingsLabel,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        actions: [],
      ),
      error: (_, _) => HomeDialog(
        dialogKey: const ValueKey('homeDialog-remindersError'),
        headerKey: const ValueKey('homeDialogHeader-remindersError'),
        icon: Icons.notifications_off_outlined,
        title: l10n.readingReminders,
        subtitle: l10n.reminderSettingsUnavailable,
        content: HomeDialogNotice(
          noticeKey: const ValueKey('reminderLoadErrorNotice'),
          icon: Icons.error_outline_rounded,
          text: l10n.reminderSettingsLoadFailed,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          FilledButton.icon(
            key: const ValueKey('reminderRetryAction'),
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => ref.invalidate(prayerReminderSettingsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      ),
      data: (settings) {
        _initialize(settings);
        final controlsEnabled = !_saving && _enabled;
        final sectionShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.65),
          ),
        );

        return HomeDialog(
          dialogKey: const ValueKey('homeDialog-reminders'),
          headerKey: const ValueKey('homeDialogHeader-reminders'),
          icon: Icons.notifications_active_outlined,
          title: l10n.readingReminders,
          subtitle: l10n.reminderSubtitle,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  key: const ValueKey('reminderEnableCard'),
                  color: colors.surfaceContainerLow,
                  shape: sectionShape,
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
                    title: Text(
                      l10n.enableReminder,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _enabled
                          ? l10n.reminderEnabledBody
                          : l10n.reminderDisabledBody,
                    ),
                    value: _enabled,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _enabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PrayerReminderPrayer>(
                  initialValue: _prayer,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(Icons.expand_more_rounded),
                  decoration: homeDialogInputDecoration(
                    context,
                    labelText: l10n.prayer,
                    prefixIcon: Icons.mosque_outlined,
                  ),
                  items: PrayerReminderPrayer.values
                      .map(
                        (prayer) => DropdownMenuItem(
                          value: prayer,
                          child: Text(
                            _localizedPrayerLabel(context, prayer),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: !controlsEnabled
                      ? null
                      : (value) => setState(() {
                          if (value != null) _prayer = value;
                        }),
                ),
                const SizedBox(height: 12),
                Material(
                  key: const ValueKey('reminderPrayerTimeCard'),
                  color: colors.surfaceContainerLow,
                  shape: sectionShape,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: sectionShape,
                    onTap: controlsEnabled ? _pickPrayerTime : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: controlsEnabled
                                  ? colors.primaryContainer
                                  : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.schedule_rounded,
                              color: controlsEnabled
                                  ? colors.onPrimaryContainer
                                  : colors.onSurfaceVariant.withValues(
                                      alpha: 0.55,
                                    ),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.prayerTime,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTimeOfDay(_prayerTimeMinutes),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: controlsEnabled
                                        ? colors.onSurface
                                        : colors.onSurface.withValues(
                                            alpha: 0.38,
                                          ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: controlsEnabled ? 1 : 0.38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _offsetMinutes,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(Icons.expand_more_rounded),
                  decoration: homeDialogInputDecoration(
                    context,
                    labelText: l10n.reminderAfter,
                    prefixIcon: Icons.notifications_none_rounded,
                  ),
                  items: const [0, 5, 10, 15, 20, 30, 45, 60]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            minutes == 0
                                ? l10n.atPrayerTime
                                : l10n.minutesShort(minutes),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: !controlsEnabled
                      ? null
                      : (value) => setState(() {
                          if (value != null) _offsetMinutes = value;
                        }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _snoozeMinutes,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(Icons.expand_more_rounded),
                  decoration: homeDialogInputDecoration(
                    context,
                    labelText: l10n.snooze,
                    prefixIcon: Icons.snooze_rounded,
                  ),
                  items: const [5, 10, 15, 30, 45, 60]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            l10n.minutesShort(minutes),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: !controlsEnabled
                      ? null
                      : (value) => setState(() {
                          if (value != null) _snoozeMinutes = value;
                        }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            if (_saving)
              FilledButton(
                key: const ValueKey('reminderSaveAction'),
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                onPressed: null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.saving),
                  ],
                ),
              )
            else
              FilledButton.icon(
                key: const ValueKey('reminderSaveAction'),
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                onPressed: _save,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(l10n.save),
              ),
          ],
        );
      },
    );
  }

  void _initialize(PrayerReminderSettings settings) {
    if (_initialized) return;
    _initialized = true;
    _enabled = settings.enabled;
    _prayer = settings.prayer;
    _prayerTimeMinutes = settings.prayerTimeMinutes;
    _offsetMinutes = settings.offsetMinutes;
    _snoozeMinutes = settings.snoozeMinutes;
  }

  Future<void> _pickPrayerTime() async {
    final currentTime = TimeOfDay(
      hour: _prayerTimeMinutes ~/ 60,
      minute: _prayerTimeMinutes % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final outline = BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.7),
        );

        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: colors.surfaceContainerHigh,
              dialBackgroundColor: colors.surfaceContainerLow,
              dialHandColor: colors.primary,
              dialTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.onPrimary
                    : colors.onSurface,
              ),
              entryModeIconColor: colors.primary,
              hourMinuteColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.primaryContainer
                    : colors.surfaceContainerLow,
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.onPrimaryContainer
                    : colors.onSurface,
              ),
              dayPeriodColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.primaryContainer
                    : colors.surfaceContainerLow,
              ),
              dayPeriodTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: outline,
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: outline,
              ),
              cancelButtonStyle: TextButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
              confirmButtonStyle: TextButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    setState(() {
      _prayerTimeMinutes = picked.hour * 60 + picked.minute;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final settings = PrayerReminderSettings(
      enabled: _enabled,
      prayer: _prayer,
      prayerTimeMinutes: _prayerTimeMinutes,
      offsetMinutes: _offsetMinutes,
      snoozeMinutes: _snoozeMinutes,
    );

    late final bool saved;
    try {
      saved = await ref
          .read(prayerReminderServiceProvider)
          .saveSettings(settings);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.reminderScheduleFailed),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;

    ref.invalidate(prayerReminderSettingsProvider);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? _enabled
                    ? context.l10n.reminderScheduled
                    : context.l10n.reminderDisabled
              : context.l10n.reminderPermissionDenied,
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTimeOfDay(int minutesOfDay) {
    final time = TimeOfDay(hour: minutesOfDay ~/ 60, minute: minutesOfDay % 60);
    return time.format(context);
  }

  String _localizedPrayerLabel(
    BuildContext context,
    PrayerReminderPrayer prayer,
  ) {
    return switch (prayer) {
      PrayerReminderPrayer.fajr => context.l10n.fajr,
      PrayerReminderPrayer.dhuhr => context.l10n.dhuhr,
      PrayerReminderPrayer.asr => context.l10n.asr,
      PrayerReminderPrayer.maghrib => context.l10n.maghrib,
      PrayerReminderPrayer.isha => context.l10n.isha,
    };
  }
}
