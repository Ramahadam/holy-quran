# Handoff: Mushaf Page Chrome Refinement

Date: 2026-06-05

Repository: `/Users/ram/Desktop/Holy Quran`

## Context

This handoff captures the current Mushaf page decoration and layout work.

Start by reading:

- `/Users/ram/Desktop/Holy Quran/Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`
- `/Users/ram/Desktop/Holy Quran/docs/handoff-task13-20260604.md`
- `/Users/ram/Desktop/Holy Quran/lib/presentation/widgets/mushaf_sample_page.dart`
- `/Users/ram/Desktop/Holy Quran/test/mushaf_sample_page_test.dart`

## Current State

Current branch when this handoff was written:

- `main`, with pending local changes from the Mushaf page chrome work

The user tested the app on a physical Android phone:

- Device: `SM A326B`
- Device id: `RFCT205ADPB`
- Android: API 33

The app was launched with:

- `flutter run -d RFCT205ADPB --dart-define-from-file=config/supabase.local.json`

Supabase initialized cleanly during the latest live run.

## Completed Work

Mushaf page layout:

- Regular Mushaf pages now use more vertical height.
- Opening pages that already start with a Surah title do not render the extra page header.
- Page footer decoration stretches across the full page width.
- Header and footer use `qcf_quran`'s `assets/mainframe.png` frame asset.
- The footer centers the Arabic page number inside the decorated band.

Ayah line handling:

- QCF verse text that ends with a line break now preserves that line break after the ayah marker.
- This fixed cases where the marker and end of ayah forced too much text onto one line and broke Mushaf-like alignment.

Header metadata:

- The header renders the Surah name using the Surah title font token, for example `surah002`.
- The header renders the Juz label on the other side.
- A vertical divider is placed at the center of the page in tests.
- Juz labels were extracted into `mushafJuzLabel`.
- The missing `السابع والعشرون` label was restored so Juz 27 and later labels do not shift.

## Known Remaining Issue

The user reports the header text still does not look centered:

- Surah name is still not visually centered in its half of the header.
- Juz name is still not visually centered in its half of the header.
- The divider itself is centered by widget test, so the remaining issue is likely visual/text alignment rather than the divider position.

Likely causes to inspect:

- The QCF Surah font glyph metrics may have asymmetric visual bounds.
- `Directionality(textDirection: TextDirection.ltr)` around the header may affect the Surah font token differently than expected.
- The frame asset may have uneven visual ornament weight or internal padding even though the widget bounds are equal.
- The current header `horizontalPadding: 18` may make the labels look offset inside the decoration.

Suggested next adjustment:

- Test a header layout that uses a `Stack` inside `_MushafFrameBand`.
- Pin the divider to `Alignment.center`.
- Place the Surah and Juz labels in `PositionedDirectional` or two explicit half-width boxes.
- Consider using `Transform.translate` or text-specific padding only if visual font metrics still make the labels look off after exact half-box layout.
- Re-check on the physical Android device, not only widget tests, because the issue is visual.

## Verification Already Run

- `dart format lib/presentation/widgets/mushaf_sample_page.dart test/mushaf_sample_page_test.dart`
- `flutter test test/mushaf_sample_page_test.dart`
- `flutter analyze`
- `flutter devices`
- `flutter run -d RFCT205ADPB --dart-define-from-file=config/supabase.local.json`

Focused tests pass and analysis reports no issues.

## Suggested Skills For The Next Session

- `frontend-ui-engineering`: refine the header alignment visually.
- `test-driven-development`: keep the divider/page-chrome regression tests.
- `browser-testing-with-devtools` is not relevant here; this is Flutter Android visual QA.
- `git-workflow-and-versioning`: keep future commits off `main`.
