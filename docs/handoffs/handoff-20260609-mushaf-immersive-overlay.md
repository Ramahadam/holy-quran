# Handoff: Mushaf Immersive Overlay Direction

Date: 2026-06-09

Repository: `/Users/ram/Desktop/Holy Quran`

Branch when written: `feature/issue-36-footer-decoration`

Superseded issue: https://github.com/Ramahadam/holy-quran/issues/36

## Context

The permanent footer-decoration direction from issue #36 was closed as superseded. The user tested dense Mushaf pages around the `500-600` range and found that the bottom ayat can overlap or become partially hidden when permanent header/footer chrome consumes page space.

The active product direction remains QCF/package-rendered Mushaf Mode, not scanned page images. The goal is a calm, readable Mushaf page that can use the available phone width and height more fully.

Relevant product docs:

- `Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`
- `docs/handoff-task14-20260605.md`
- `docs/handoffs/handoff-20260608-mushaf-bismillah-padding.md`

## Recommendation

Move Mushaf Mode to an immersive reader model:

- Header/footer/page chrome hidden by default in Mushaf mode.
- Single tap anywhere on the page toggles header/footer overlay visibility.
- Long press on an ayah opens the ayah detail/focus view.
- Header/footer should draw as temporary overlays and should not permanently reserve layout height.
- Page text should use the full available reading area when the overlay is hidden.
- Auto-hide overlays after a short delay, likely `2.5-3s`, unless the user taps again.
- Keep horizontal page swiping unaffected.

This aligns better with the PRD's Focus Mode language, which describes long-press on a verse to enter verse detail.

## Research Summary

Reader apps commonly use a single tap to reveal navigation/chrome and long-press for text/verse-level actions. This pattern keeps the page as the primary interaction surface while preserving a path to detail actions.

References checked during the session:

- Android immersive mode documentation: books are a good fullscreen/immersive use case, and system bars should overlay content rather than resize it when transient.
- Google Play Books help: tap page center for navigation/tools; touch and hold selected text for highlight/note/search/translate actions.
- Flutter `GestureDetector`: supports clean separation between `onTap` and `onLongPress`/`onLongPressStart`.

## Code Entry Points

Start with these files:

- `lib/presentation/screens/reading_screen.dart`
- `lib/presentation/widgets/mushaf_sample_page.dart`
- `test/mushaf_sample_page_test.dart`

Important current seams:

- `reading_screen.dart`
  - `_ReadingScreenState._buildPageView`
  - Current `PageView` wrapper uses a `GestureDetector` to hide Mushaf controls when visible.
  - `_QuranPageState` passes `onVerseTap` into `MushafSamplePage`; that callback currently opens verse detail.

- `mushaf_sample_page.dart`
  - `_MushafSamplePageState._handleTapUp` currently hit-tests a tap and calls `onHit`.
  - `MushafQcfPage` accepts `onTap` and `onLongPress`, but both are currently wired to the same verse action path.
  - `_MushafPageHeader` and `_MushafPageFooter` are currently rendered inside the page stack.

## Suggested Implementation Slice

1. Add an explicit Mushaf page chrome state in `reading_screen.dart`.
   - Keep app-level controls/chrome hidden in immersive mode.
   - Toggle page overlay visibility on single tap.

2. Change Mushaf ayah detail to long-press.
   - Single tap should no longer open ayah detail.
   - Long press should hit-test the touched ayah and open the existing verse detail/focus view.

3. Move header/footer into overlay behavior.
   - They can still be rendered in `MushafQcfPage`, but only when overlay visibility is true.
   - Do not permanently reserve content space for hidden chrome.
   - When visible, use a translucent or decorated overlay treatment that does not resize the page.

4. Re-check page scale after overlays are hidden.
   - Once permanent chrome no longer consumes space, revisit QCF font scale and content insets.
   - Verify dense pages in the `500-600` range before increasing font size.

## Verification Targets

Automated:

- Add/update widget tests for:
  - Single tap toggles Mushaf overlay controls.
  - Long press opens/dispatches ayah detail.
  - Single tap no longer opens ayah detail.
  - Header/footer hidden state allows dense late pages to avoid footer/header collision.

Manual emulator:

- Run:
  - `flutter run -d emulator-5554 --dart-define-from-file=config/supabase.local.json`
- Check Mushaf pages around:
  - `500`
  - `567`
  - `573`
  - `582`
  - `600`
  - `602`
  - `603`
- Confirm:
  - No bottom ayah is hidden.
  - Single tap reveals overlay chrome.
  - Second tap or timeout hides overlay chrome.
  - Long press opens the ayah detail/focus view.
  - Page swiping still works naturally.

## Notes

- The user-provided footer decoration remains at `/Users/ram/Downloads/footer_decoration.png`.
- The generated repo copy from the superseded permanent-footer attempt was removed from `assets/mushaf/chrome/`.
- Avoid reintroducing permanent footer/header height until the immersive overlay model is validated.

## Suggested Skills For Next Session

- `frontend-ui-engineering`: interaction and overlay polish.
- `test-driven-development`: lock tap/long-press behavior and dense-page regression checks.
- `diagnose`: if overlap still appears after hidden chrome.
- `code-review-and-quality`: review gesture changes before merge.
