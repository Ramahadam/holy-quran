# Handoff: Heartbeat Feedback Prompts Ready

Date: 2026-06-16
Branch: `feature/issue-42-heartbeat-feedback-prompts`
Issue: #42 heartbeat feedback prompts
PR: #43 `feat: add heartbeat feedback prompts`
Latest commit: `ccd7593 fix: preserve feedback submit error details (#42)`

## Focus

Heartbeat feedback prompts are implemented and manually verified. The app now asks engaged readers for anonymous feedback after meaningful local reading activity, reuses the existing anonymous feedback dialog, and avoids collecting reading history or account information.

## Current State

- PR #43 is open, ready for review, and mergeable:
  - https://github.com/Ramahadam/holy-quran/pull/43
- Issue #42 is closed:
  - https://github.com/Ramahadam/holy-quran/issues/42
- The branch is pushed to origin and local git status was clean before this handoff was written.
- Supabase feedback submission was manually verified after the Supabase project was resumed.
- The final diagnostic commit preserves the underlying feedback transport error in logs, which helped identify the paused Supabase project.

## Implemented Behavior

- Production prompt threshold:
  - Shows after 7 distinct reading days.
- QA override:
  - `FEEDBACK_PROMPT_TEST_DELAY_SECONDS=60` shows the heartbeat prompt after about 1 minute from the first recorded reading session.
  - `FEEDBACK_PROMPT_TEST_DELAY_SECONDS=120` shows it after about 2 minutes.
- `Not now` starts the normal prompt cooldown.
- `Give feedback` does not dismiss the prompt by itself.
- Successful feedback submission marks the prompt as completed.
- Failed feedback submission keeps the prompt eligible, so the user can retry later.
- Returning from the reader rechecks prompt eligibility so the QA timer is observable.

## Files Changed

- `lib/data/feedback/feedback_prompt_service.dart`
  - Local prompt state, distinct-day threshold, dismissal/submission state, QA delay support.
- `lib/data/feedback/anonymous_feedback_service.dart`
  - Anonymous feedback transport now preserves useful submit error details in logs.
- `lib/presentation/providers/quran_providers.dart`
  - Feedback prompt providers and QA Dart define wiring.
- `lib/presentation/screens/home_screen.dart`
  - Heartbeat prompt UI, feedback dialog reuse, retry-safe submit flow, post-reader prompt recheck.
- `lib/presentation/screens/reading_screen.dart`
  - Records local engagement when reading starts/saves.
- `pubspec.yaml` / `pubspec.lock`
  - Adds direct `shared_preferences` dependency.
- `test/feedback/feedback_prompt_test.dart`
  - Covers trigger logic, QA delay, dismissal, submission.
- `test/anonymous_feedback_test.dart`
  - Covers Home feedback UI, heartbeat prompt, failed-submit retry behavior, and post-reader recheck.
- `test/widget_test.dart`
  - Updated for reading engagement recording behavior.

## Runtime Evidence

Manual QA on Android:

- Heartbeat prompt displayed with the 1-minute QA timer.
- Initial feedback submission failed while Supabase was paused.
- After resuming Supabase, feedback submitted successfully.
- The failed-submit path no longer dismisses the heartbeat prompt.

Useful test command for phone `SM A326B`:

```bash
flutter run -d RFCT205ADPB \
  --dart-define-from-file=config/supabase.local.json \
  --dart-define=FEEDBACK_PROMPT_TEST_DELAY_SECONDS=60
```

Clear local app data before repeating prompt QA:

```bash
/Users/ram/Library/Android/sdk/platform-tools/adb -s RFCT205ADPB shell pm clear com.holyquran.holy_quran_app
```

For emulator:

```bash
/Users/ram/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell pm clear com.holyquran.holy_quran_app
```

## Verification

Commands run successfully:

```bash
flutter test test/anonymous_feedback_test.dart
flutter test test/widget_test.dart
flutter analyze
flutter test
```

Live Supabase diagnostic while the project was paused produced:

```text
Failed host lookup: 'xwrhpkwrhahdnrfrfkme.supabase.co'
```

After the Supabase project was resumed, manual in-app feedback submission worked.

## Known Caveats

- The QA delay is only active when `FEEDBACK_PROMPT_TEST_DELAY_SECONDS` is passed as a Dart define.
- If Supabase is paused, deleted, or the project URL changes, feedback submission will fail gracefully in the UI and now logs the underlying transport cause.
- If the user taps `Not now`, the prompt enters the normal cooldown. Clear app data for repeated QA.
- `config/supabase.local.json` must contain valid public Supabase mobile config and remains git-ignored.

## Recommended Next Steps

1. Review and merge PR #43.
2. After merge, delete branch `feature/issue-42-heartbeat-feedback-prompts`.
3. Keep Supabase project active before release QA.
4. For future diagnostics, check Flutter logs for `Failed to submit anonymous feedback:`; it now includes the underlying cause.

## Suggested Skills For Next Session

- `github:github` or `github:yeet` if continuing PR/merge workflow.
- `code-review-and-quality` before merging.
- `shipping-and-launch` if preparing a release QA checklist.
