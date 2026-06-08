# Handoff: Mushaf Bismillah And Padding Refinement

Date: 2026-06-08

Repository: `/Users/ram/Desktop/Holy Quran`

Branch: `feature/issue-37-reading-page-layout`

Issue: https://github.com/Ramahadam/holy-quran/issues/37

## Context

This work continues the Mushaf page chrome and reading layout refinements from:

- `docs/handoff-task14-20260605.md`
- `Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`

The active product direction remains QCF/package-rendered Mushaf pages, not HD scanned page images.

## Completed In This Slice

- Exposed Mushaf page content padding knobs in `lib/presentation/widgets/mushaf_sample_page.dart`.
- Reduced the Mushaf content bottom inset to `0` and made horizontal content inset explicit.
- Updated Classic mode Bismillah handling so later Surah openings reuse the Al-Fatihah Bismillah treatment:
  - font size `28`
  - line height `2.0`
  - normal text color instead of green
- Updated Mushaf/QCF inserted Bismillah handling so later Surah openings use the same page-1 QCF glyph source via `getVerseQCF(1, 1, verseEndSymbol: false)`.
- Added per-glyph Allah-word red coloring to inserted QCF Bismillah, matching the page-1 Bismillah behavior.
- Removed the old hardcoded inserted Bismillah shortcut string and the separate package `basmalaFontSize*` sizing path.

## Verification Run

- `flutter test test/widget_test.dart --plain-name "Bismillah"`
- `flutter test test/mushaf_sample_page_test.dart`
- `flutter analyze`
- Rebuilt/launched on `emulator-5554` with:
  - `flutter run -d emulator-5554 --dart-define-from-file=config/supabase.local.json`

## Notes For Next Session

- User was visually comparing page 1 Al-Fatihah Bismillah against later Surah-opening Bismillah in the Android emulator.
- If Bismillah still appears visually off, inspect the QCF inserted Bismillah rendered on page 2 against page 1 in Mushaf mode first.
- Keep adjustments step-by-step and visually review on the emulator before committing broad typography changes.
- Footer frame replacement is tracked separately in issue #36 and should wait for the user-provided frame asset/direction.

## Suggested Skills

- `frontend-ui-engineering`: for visual tuning and emulator review.
- `test-driven-development`: for focused widget regressions around Bismillah and page chrome.
- `code-review-and-quality`: before merge.
