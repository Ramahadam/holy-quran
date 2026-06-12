# Handoff: Mushaf Chrome And Late-Page Overlap Follow-Up

Date: 2026-06-10

Repository: `/Users/ram/Desktop/Holy Quran`

Branch: `feature/issue-36-footer-decoration`

## Context

The active product direction remains QCF/package-rendered Mushaf Mode with a calm
physical-page feeling, not scanned page images.

Relevant prior context:

- `Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`
- `docs/handoff-task14-20260605.md`
- `docs/handoffs/handoff-20260608-mushaf-bismillah-padding.md`
- `docs/handoffs/handoff-20260609-mushaf-immersive-overlay.md`

The user preferred preserving the physical Mushaf decoration instead of moving
directly to an immersive overlay model.

## Completed Baseline Commit

Commit already created:

- `35917f9 fix: compact Mushaf page chrome`

That commit:

- Reduced the top Mushaf page header from `72` to `56`.
- Matched the content top inset to the visible header height.
- Compacted inserted Bismillah on pages `595-600`.
- Added focused widget tests.

The user visually confirmed this solved the initial overlap on pages `595-600`.

## Current Uncommitted Change Set To Commit

The current working change replaces old middle Surah chrome with a new single-slot
decoration and tunes Bismillah/title sizing.

Files involved:

- `lib/presentation/widgets/mushaf_sample_page.dart`
- `test/mushaf_sample_page_test.dart`
- `assets/mushaf/chrome/quran_single_slot_centered.png`

Implemented behavior:

- Added shared single-slot decoration asset:
  - `assets/mushaf/chrome/quran_single_slot_centered.png`
- Replaced in-page/middle Surah `HeaderWidget` usage with
  `_MushafInlineSurahHeader`.
- Reused the same single-slot decoration for the page footer.
- Set single-slot chrome height to match the top page header:
  - `mushafSingleSlotChromeHeight = mushafPageHeaderHeight = 56`
- Increased Surah title glyph size globally:
  - `mushafSurahTitleFontSize = 22`
- Left the Juz title size unchanged.
- Current inserted Bismillah compacting applies only to Juz 30:
  - pages `582-604`
  - text scale `1.0`
  - line height `1.72`

Verification already run after these changes:

- `dart format lib/presentation/widgets/mushaf_sample_page.dart test/mushaf_sample_page_test.dart`
- `flutter test test/mushaf_sample_page_test.dart`
- `flutter analyze`

Both focused tests and analyzer passed.

## Known Remaining Issue

After checking more pages, the user found the same bottom overlap pattern on
additional pages:

- `580`
- `570`
- `564`
- `554`
- `551`
- `547`
- `545`
- `537`
- `534`
- `531`
- `528`
- `520`
- `515`
- `502`

These pages are not random. They cluster in the late Mushaf region where shorter
Surahs and repeated Surah openings increase vertical pressure. Page-by-page
exceptions are not the right long-term fix.

## Recommendation For Next Session

Do not keep adding individual page exceptions.

Recommended next implementation:

1. Replace the Juz-30-only Bismillah rule with a late-page rule:
   - Start with pages `502-604`.
   - Apply the same compact inserted Bismillah text scale/line height currently
     used for Juz 30.
2. Visually re-check the user-reported pages first:
   - `502`, `515`, `520`, `528`, `531`, `534`, `537`, `545`, `547`, `551`,
     `554`, `564`, `570`, `580`, plus `595-600`.
3. If overlap remains after compacting pages `502-604`, avoid adding another
   page list. The next clean design option is to reduce the footer chrome height
   again or reserve bottom content space and slightly scale content down for the
   late-page region.

Potential future refinement:

- Use a density rule rather than a raw page range, such as compacting pages where
  `getPageData(pageNumber)` contains one or more Surah openings after the first
  range. A page-range rule is simpler and may be sufficient because the issue is
  clustered late in the Mushaf.

## Current UX Judgment

The single-slot decoration is visually closer to the top header than the previous
asset and can reasonably serve both middle Surah headers and footer decoration.
The tradeoff is vertical space: matching the header height improves consistency
but increases the chance of bottom overlap on dense late pages.

Keep the physical Mushaf feeling, but solve dense pages with a general layout
rule, not one-off page patches.
