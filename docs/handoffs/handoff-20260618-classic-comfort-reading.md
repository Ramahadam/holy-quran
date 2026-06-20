# Handoff: Classic Comfort Reading And Dark Mode Issue Set

Date: 2026-06-18
Repository: `/Users/ram/Desktop/Holy Quran`

## Focus

The user wants to enhance the current Classic reading experience because the
text feels small compared with image-based Quran apps. The agreed product
direction is not to replace Classic with page images. Instead:

- Keep Mushaf mode as the fixed-page, physical-page-like reading mode.
- Turn Classic into a scrollable, wide, large-text comfort reading mode.
- Use Mushaf-inspired typography and Bismillah styling where it improves beauty,
  without copying Mushaf's fixed-page constraints.
- Treat dark mode as a separate feature set.

Recitation/audio is explicitly out of scope for this project.

## Created GitHub Issues

Created in dependency order:

- #44: Convert Classic mode to vertical comfort reading
  - https://github.com/Ramahadam/holy-quran/issues/44
- #45: Improve Classic Arabic typography and reading width
  - https://github.com/Ramahadam/holy-quran/issues/45
- #46: Polish Classic ayah markers and Bismillah styling
  - https://github.com/Ramahadam/holy-quran/issues/46
- #47: Add dark mode theme foundation
  - https://github.com/Ramahadam/holy-quran/issues/47
- #48: Apply dark mode to Quran reading experiences
  - https://github.com/Ramahadam/holy-quran/issues/48

Issues #44-#47 are labeled `enhancement` and `ready-for-agent`.
Issue #48 is labeled `enhancement` only because it is a HITL visual-review slice.

## Current Code Context

Use codebase-memory MCP first for code discovery, per repo instructions.
Relevant symbols found through the graph:

- `lib/presentation/screens/reading_screen.dart`
  - `_ReadingScreenState._buildPageView`
  - `_QuranPageContent.build`
  - `_QuranPageContent._buildVerseWidgets`
  - `_ArabicVerse`
  - `_BismillahHeader`
  - `_SurahHeader`
- `lib/presentation/widgets/mushaf_sample_page.dart`
  - `MushafQcfPage`
  - `_InspiredQcfPageState._normalVerseText`
  - `_InspiredQcfPageState._buildVerseSpans`
- `lib/presentation/theme/app_theme.dart`
  - `AppTheme` currently only exposes `light`.
- `lib/presentation/app.dart`
  - `HolyQuranApp.build` currently passes `theme: AppTheme.light`.

Important nuance: Classic already has a `SingleChildScrollView` inside each page,
but the outer reader is still a horizontal `PageView` across 604 pages. The user
is asking for Classic to become a true vertical comfort-reading experience, not
merely page-internal overflow scrolling.

## Recommended Implementation Order

1. Implement #44 first. Separate Classic and Mushaf navigation behavior.
2. Implement #45 after #44. Tune text size, width, line height, and touch areas.
3. Implement #46 after #45. Polish markers and Bismillah once layout is stable.
4. Implement #47 independently or after #46. Add centralized dark theme tokens.
5. Implement #48 after #47 and perform visual review before merge.

Use one branch and PR per issue.

## Best Practices

- Preserve `VerseID` as the shared anchor for bookmarks, last-read, and verse
  detail. Do not introduce renderer-specific reading state unless absolutely
  necessary.
- Keep Mushaf mode untouched while working on #44-#46, except where shared code
  must be adapted carefully.
- Make Classic wide, but keep a small safe margin. Full-width should not mean
  glyphs or touch targets feel clipped against screen edges.
- Prefer named theme tokens and shared styles over one-off color literals,
  especially before dark mode work.
- Verify on at least one small Android phone viewport. The visual problem is
  mostly a phone readability problem.
- Update tests around navigation and verse-detail access whenever changing the
  reader structure.
- Keep each PR narrow. A clean #44 should be mostly behavior/navigation; visual
  polish belongs in #45 and #46.

## Do

- Do keep Classic as text, not images.
- Do allow Classic to scroll vertically and reflow for readability.
- Do keep Mushaf fixed-page and page-faithful.
- Do make Bismillah more elegant in Classic, borrowing from Mushaf treatment
  without forcing fixed-page layout.
- Do preserve long-press verse detail/focus behavior.
- Do preserve bookmark highlighting.
- Do test `flutter analyze`, `flutter test`, and a debug build when practical.
- Do use screenshots/manual review for typography and dark mode decisions.

## Do Not

- Do not replace Classic with page images.
- Do not reintroduce PNG/HD Mushaf page assets or coordinate-map dependencies
  for this Classic improvement.
- Do not hand-author ayah coordinate JSON.
- Do not remove valid ayah numbers while removing the empty decorator.
- Do not couple dark mode into the Classic scroll conversion PR.
- Do not hard-code dark colors inside individual widgets when a theme token can
  express the intent.
- Do not change page boundary data in `assets/quran/verses.json`.
- Do not make Mushaf scrollable as part of this effort.

## Nuances To Watch

- Last-read behavior is the main tricky point in #44. The old page-slider model
  can save the first verse of the current page. A vertical Classic reader should
  define a sensible visible-verse save rule, such as the top visible verse or
  latest interacted verse.
- If Classic renders many verses in one scroll, avoid building all 6,236 verses
  naively if performance suffers. Start simple, then optimize only if profiling
  or runtime testing shows a problem.
- Bigger Arabic text needs line-height tuning. Too tight causes diacritics to
  feel cramped; too loose makes reading exhausting.
- Surah openings and Bismillah can consume a lot of vertical space. Keep them
  beautiful but not oversized.
- Dark Mushaf is a design decision, not only a technical one. Inverting or
  recoloring Mushaf-style content may reduce sacred-page familiarity. #48 is
  marked HITL for that reason.

## Suggested Skills For Next Sessions

- `frontend-ui-engineering` for Classic reading layout and dark-mode polish.
- `test-driven-development` for navigation, last-read, and verse-detail behavior.
- `code-review-and-quality` before merging each PR.
- `git-workflow-and-versioning` for branch, commit, PR, and cleanup workflow.
- `debugging-and-error-recovery` if reader state or scroll-position behavior gets
  subtle during #44.

## Verification Baseline

For implementation PRs, prefer:

```bash
flutter test
flutter analyze
flutter build apk --debug
```

For visual slices, also capture emulator or device screenshots for Classic and
Mushaf modes before review.
