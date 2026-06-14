# Handoff: Prayer Reminder Runtime Delivery

Date: 2026-06-13
Branch: `feature/issue-40-prayer-notifications`
Issue: #40 prayer notification reminders

## Focus

The current task is to fix prayer reading reminders so a saved reminder reliably appears as a visible Android notification at the configured time.

## Current State

- Prayer reminder feature code has been implemented but not committed.
- The app can save reminder settings without the previous spinner hang.
- Android notification permission is granted on the emulator.
- The app schedules alarms through `flutter_local_notifications`.
- Runtime testing shows the alarm receiver fires, but the user-visible notification does not remain visible in the notification shade.

## Emulator Test Performed

Device: `emulator-5554`
App package: `com.holyquran.holy_quran_app`

Steps performed through the app UI:

1. Opened the app in the emulator.
2. Opened menu.
3. Opened `Reading reminders`.
4. Set prayer time to `2:37 PM`.
5. Kept `Reminder after` at `5 min`.
6. Saved settings.

Expected reminder time:

- `2:42 PM` on 2026-06-13 Asia/Dubai.

Observed Android alarm state after saving:

- Android scheduled `ScheduledNotificationReceiver` for `2026-06-13 14:42:00`.
- The alarm was `RTC_WAKEUP`.
- It had an inexact delivery window of about 6 minutes 58 seconds.
- This means Android could delay delivery until about `14:48:58`.

Observed runtime result:

- At `14:44`, the alarm was still pending.
- Around `14:49`, Android alarm history showed the app receiver had fired.
- `appops` showed `VIBRATE` was used seconds after the receiver fired.
- No Quran reminder notification appeared in the notification shade.
- `dumpsys notification --noredact` showed no active `com.holyquran.holy_quran_app` notification record.
- The notification shade screenshot showed only the Android System "Serial console enabled" notification.

Follow-up behavior:

- After the first receiver run, Android showed another pending app alarm for `14:55`.
- That alarm also used an inexact window, ending around `14:58:51`.
- After `15:00`, Android alarm history showed another app wakeup.
- The notification manager still showed no active Quran notification.
- The notification shade still had no Quran notification.

Conclusion:

- Alarm scheduling is happening.
- Receiver execution is happening.
- The visible notification is not reliably posted or retained.
- Reminder timing is also unreliable because the current scheduler uses inexact alarms.

## Local Access Note

The local repo path under `/Users/ram/Desktop/Holy Quran` has shown intermittent macOS Desktop privacy failures from this Codex process. At one point shell reads and installs failed with:

```text
ls: .: Operation not permitted
sed: lib/data/notifications/prayer_reminder_scheduler.dart: Operation not permitted
```

After this handoff was created, a direct read of this handoff file succeeded, but directory listing and `git status` still failed with `Operation not permitted`. Before patching code, verify repo access with `git status --short` and a direct read of `lib/data/notifications/prayer_reminder_scheduler.dart`.

ADB access still works from `/private/tmp`.

## Relevant Runtime Commands

ADB path:

```bash
/Users/ram/Library/Android/sdk/platform-tools/adb
```

Useful checks:

```bash
/Users/ram/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell dumpsys alarm | grep -i -B5 -A25 'com.holyquran.holy_quran_app'
/Users/ram/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell dumpsys notification --noredact | grep -i -B8 -A35 'pkg=com.holyquran.holy_quran_app\|holy_quran\|quran_reading\|reading reminder'
/Users/ram/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell cmd appops get com.holyquran.holy_quran_app
/Users/ram/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell dumpsys package com.holyquran.holy_quran_app | grep -i -A3 -B2 'POST_NOTIFICATIONS\|SCHEDULE_EXACT_ALARM\|USE_EXACT_ALARM'
```

## Recommended Next Work

Use the following skills:

- `diagnose` for the runtime delivery loop.
- `test-driven-development` for scheduler calculation/permission behavior tests if a suitable seam exists.
- `git-workflow-and-versioning` before commit/PR work.

Recommended fix direction:

1. Verify repository file access for Codex.
2. Inspect `lib/data/notifications/prayer_reminder_scheduler.dart`.
3. Change reminder scheduling from inexact to exact scheduling, likely `AndroidScheduleMode.exactAllowWhileIdle`.
4. Add or verify Android exact alarm permission handling if required by the plugin/API level.
5. Verify notification channel creation and notification details:
   - Channel importance should be visible enough for reminders.
   - Notification priority should be high/default as appropriate.
   - Small icon must resolve correctly.
   - Notification should not auto-cancel before the user sees it.
6. Add a fast debug/test path if acceptable, such as a temporary "test reminder in 10 seconds" helper or a test-only immediate notification call.
7. Rebuild and install on emulator.
8. Re-run the UI test and confirm:
   - Alarm is exact or has no broad inexact window.
   - Notification appears in the shade.
   - `dumpsys notification` includes an active record for `com.holyquran.holy_quran_app`.

## Important Context

Earlier test/build results before file access broke:

- `flutter test test/notifications/prayer_reminder_test.dart`
- `flutter test test/widget_test.dart`
- `flutter analyze`
- `flutter build apk --debug`

These reportedly passed before the macOS file access issue appeared.

Unrelated untracked doc noted earlier:

- `docs/handoffs/handoff-20260609-mushaf-immersive-overlay.md`

Avoid touching unrelated handoff docs or unrelated Mushaf work while fixing this reminder issue.
