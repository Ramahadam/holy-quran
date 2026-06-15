# Handoff: Prayer Reminder Notifications Working

Date: 2026-06-15
Branch: `feature/issue-40-prayer-notifications`
Issue: #40 prayer notification reminders
Commit: `011d910 feat: add prayer reading reminders (#40)`

## Focus

Prayer reading reminders are now working end-to-end on Android: saving reminder settings schedules an exact alarm, the app can be closed, Android wakes the app receiver at the reminder time, and a visible Quran reminder appears in the notification shade.

## Current State

- Reminder feature has been implemented, committed, and pushed on `feature/issue-40-prayer-notifications`.
- Commit pushed: `011d910 feat: add prayer reading reminders (#40)`.
- Android notification permission is granted on the tested emulator.
- Android exact alarm app-op is allowed on the tested emulator.
- The scheduler uses `AndroidScheduleMode.exactAllowWhileIdle`.
- Android manifest includes the required exact alarm permission and `flutter_local_notifications` receivers.
- The notification small icon resolves from `android/app/src/main/res/drawable/ic_notification.xml`.
- Daily reminders and snoozed reminders use exact allow-while-idle scheduling.
- Notifications use the system locale:
  - Arabic system locale (`ar`) -> Arabic title/body/action/channel text.
  - Any other locale -> English title/body/action/channel text.
- Reminder notifications use the Android channel's default sound and vibration behavior. They are normal notifications, not continuous alarm-clock ringing.

## Runtime Evidence

Device: `emulator-5554`
App package: `com.holyquran.holy_quran_app`

### Exact Scheduling

After saving a reminder through the app UI, Android alarm state showed:

```text
RTC_WAKEUP
origWhen=2026-06-14 14:55:00.000
window=0
exactAllowReason=permission
tag=*walarm*:com.holyquran.holy_quran_app/com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
```

This confirms the previous broad inexact delivery window is gone for freshly saved reminders.

### App Closed Delivery

The app was closed and Android still started the app process for the scheduled receiver:

```text
06-14 11:48:00.062 ActivityManager: Start proc ... com.holyquran.holy_quran_app ... for broadcast {com.holyquran.holy_quran_app/com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver}
06-14 11:48:01.230 NotificationListener: received notification posted event - com.holyquran.holy_quran_app
```

`dumpsys notification --noredact` showed an active notification record:

```text
pkg=com.holyquran.holy_quran_app
id=4001
channel=quran_reading_reminders
title=A quiet moment for Quran
text=Maghrib has passed. Read a few ayat?
mSound=content://settings/system/notification_sound
mVibration=...
mImportance=DEFAULT
```

The expanded notification shade displayed:

```text
holy_quran_app - now
A quiet moment for Quran
Maghrib has passed. Read a few ayat?
Remind me later
```

### Timing Clarification

The selected `Prayer time` is not always the notification fire time. The reminder fires at:

```text
Prayer time + Reminder after
```

Example from runtime testing:

- Prayer time set to `11:43`
- `Reminder after` left at `5 min`
- Notification fired at `11:48`

To fire exactly at the selected prayer time, set `Reminder after` to `At prayer time`.

## Implemented Files

- `lib/data/notifications/prayer_reminder_settings.dart`
  - Defines reminder settings, prayer choices, validation, JSON serialization, and next reminder calculation.
- `lib/data/notifications/prayer_reminder_settings_store.dart`
  - Persists reminder settings with `SharedPreferencesAsync`.
- `lib/data/notifications/prayer_reminder_service.dart`
  - Coordinates settings persistence, permission requests, scheduling, cancellation, and snooze.
- `lib/data/notifications/prayer_reminder_scheduler.dart`
  - Wraps `flutter_local_notifications`.
  - Requests notification and exact alarm permissions.
  - Schedules exact daily/snooze notifications.
  - Localizes notification text for English and Arabic.
- `lib/presentation/providers/quran_providers.dart`
  - Provides reminder settings/service dependencies.
- `lib/presentation/screens/home_screen.dart`
  - Adds the `Reading reminders` menu entry and settings dialog.
- `android/app/src/main/AndroidManifest.xml`
  - Adds `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and `SCHEDULE_EXACT_ALARM`.
  - Adds scheduled, boot, and action receivers required by `flutter_local_notifications`.
- `android/app/src/main/res/drawable/ic_notification.xml`
  - Notification small icon.
- `test/notifications/prayer_reminder_test.dart`
  - Covers reminder calculations, settings validation, Android manifest requirements, exact schedule mode, exact permission request, English/Arabic notification text, and service behavior.
- `test/widget_test.dart`
  - Covers the home-screen reminder dialog save/error flows.

## Verification

Commands run successfully before commit:

```bash
flutter test test/notifications/prayer_reminder_test.dart
flutter test test/widget_test.dart
flutter analyze
flutter build apk --debug
```

Runtime checks used:

```bash
/Users/ram/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell dumpsys alarm | grep -i -B8 -A35 'com.holyquran.holy_quran_app'
/Users/ram/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell dumpsys notification --noredact | grep -i -B10 -A50 'pkg=com.holyquran.holy_quran_app\|quran_reading'
/Users/ram/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell cmd appops get com.holyquran.holy_quran_app
/Users/ram/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell cmd statusbar expand-notifications
```

## User-Facing Behavior

- User opens menu -> `Reading reminders`.
- User enables reminder.
- User chooses prayer, prayer time, reminder offset, and snooze duration.
- On save:
  - Notification permission is requested if needed.
  - Exact alarm permission is requested if needed.
  - Daily reminder is scheduled exactly.
- When reminder fires:
  - Notification appears in the shade.
  - It uses normal notification sound/vibration according to Android channel/device settings.
  - The `Remind me later` action schedules an exact snooze reminder.

## Known Caveats

- Existing Android notification channels keep some user/device-level settings after creation. If a tester previously muted the `quran_reading_reminders` channel, the app cannot silently override that.
- Notifications are not alarm-clock style continuous ringing. They use normal notification sound/vibration.
- If Do Not Disturb, silent mode, or channel mute is active, the notification may show silently.
- If app language selection is added later, wire that preference into `LocalPrayerReminderScheduler(localeProvider: ...)` and reschedule active reminders when the app language changes.
- The old handoff `docs/handoffs/handoff-20260613-prayer-reminder-runtime.md` documents the original broken runtime state and should be kept as historical debugging evidence.
- Unrelated untracked file still noted locally: `docs/handoffs/handoff-20260609-mushaf-immersive-overlay.md`.

## Recommended Next Steps

1. Open a PR from `feature/issue-40-prayer-notifications` to `main`.
2. In PR notes, call out that `11:43` with `Reminder after 5 min` fires at `11:48` by design.
3. If product wants alarm-like ringing, create a separate issue because that requires a different UX/permission decision from normal reminders.
4. If product wants an in-app English/Arabic selector, create a separate localization issue and reschedule reminders when the selected app language changes.
