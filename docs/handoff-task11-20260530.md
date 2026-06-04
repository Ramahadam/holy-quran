# Handoff: Mushaf UI Marker Spacing

## Context

Repository: `/Users/ram/Desktop/Holy Quran`

Current branch: `feature/issue-23-focus-mode-verse-detail`

Recent stable commit already created before this iteration:

`b3c3a58 feat: add QCF Mushaf reader and focus mode (#23)`

The user is iterating on Mushaf Mode visual fidelity. They prefer a QCF font-rendered Mushaf with a designed cream page, modern header showing Juz/Surah, clear ayah markers, and no random tajweed coloring. They asked for inspiration from Android Quran app screenshots, but the implementation should remain a hybrid QCF text approach for crisp rendering and tap interactions.

## Current Uncommitted Work

Only tracked modified file:

`/Users/ram/Desktop/Holy Quran/lib/presentation/widgets/mushaf_sample_page.dart`

What changed after the baseline commit:

- Normal Mushaf pages scaled up to improve page fill.
- Header made more modern: plain Juz/Surah labels, centered page medallion, simple underline.
- Full page border removed; page-edge separator lines retained for swipe/page separation.
- QCF ayah-number glyph replaced by a Flutter-rendered marker for clearer native Arabic numerals.
- Marker spacing was iterated because the visible circle overlapped nearby QCF glyphs. Latest state uses:
  - `WidgetSpan`
  - `SizedBox(width: 32 * sp)`
  - `Align(alignment: Alignment.centerLeft)`
  - `_AyahNumberMarker(size: 20 * sp)`
  - numeric font size scales by digit count.

Latest visual screenshot:

`/tmp/holy-quran-ayah-marker-shifted.png`

Earlier comparison screenshots:

- `/tmp/holy-quran-crisp-ayah-marker.png`
- `/tmp/holy-quran-ayah-marker-spacing.png`
- `/tmp/holy-quran-ayah-marker-slot.png`
- `/tmp/holy-quran-ayah-marker-wide-slot.png`
- `/tmp/holy-quran-ayah-marker-compact-slot.png`

## Verification Already Run

Latest checks passed:

- `flutter analyze`
- `flutter test`
- `git diff --check`
- Android emulator visual check on Pixel 6 AVD.

The emulator was killed after verification.

## Important Worktree Notes

Do not touch unrelated untracked files. Current `git status --short --branch` showed many unrelated untracked files, including:

- `AGENTS.md`
- `ALTERNATIVE_IMAGE_SOURCES.md`
- `DOWNLOAD_IMAGES_NOW.md`
- `android/build/`
- `assets/mushaf/madani-images/`
- multiple `docs/*` handoff/image-source docs
- `ios/Podfile.lock`
- `macos/Podfile.lock`
- several `scripts/*mushaf*` files

These were not modified by the latest marker-spacing work.

## Pending Decision

The latest marker spacing is an improvement, but still visually subjective. Next session should first ask the user whether `/tmp/holy-quran-ayah-marker-shifted.png` is acceptable.

If accepted:

1. Re-run `flutter analyze`, `flutter test`, and `git diff --check`.
2. Stage only `/Users/ram/Desktop/Holy Quran/lib/presentation/widgets/mushaf_sample_page.dart`.
3. Commit the iteration with a focused message, e.g. `style: refine Mushaf ayah markers (#23)`.

If not accepted:

The next likely option is to reduce marker ornament further or revert to a QCF-compatible ayah marker glyph with color tweaks. Wider marker slots damage the Mushaf line flow, as seen in `/tmp/holy-quran-ayah-marker-wide-slot.png`, so avoid large inline widths.

## Suggested Skills For Next Session

- `frontend-ui-engineering`: for visual layout and responsive UI judgment.
- `code-review-and-quality`: before any commit or merge.
- `git-workflow-and-versioning`: if committing, pushing, or merging.

## Discovery Notes

Per repo instructions, use codebase-memory MCP first for code discovery. The indexed project name is:

`Users-ram-Desktop-Holy Quran`

Relevant symbols:

- `Users-ram-Desktop-Holy Quran.lib.presentation.widgets.mushaf_sample_page._InspiredQcfPage`
- `Users-ram-Desktop-Holy Quran.lib.presentation.widgets.mushaf_sample_page._AyahNumberMarker`
- `Users-ram-Desktop-Holy Quran.lib.presentation.widgets.mushaf_sample_page._AyahNumberMarkerPainter`
