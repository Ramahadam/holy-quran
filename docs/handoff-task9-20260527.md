# Handoff: Holy Quran App - Task 9 Mushaf Mode Phase 2 Scope

Date: 2026-05-27
Repository: `/Users/ram/Desktop/Holy Quran`
Current branch when written: `feature/issue-11-mushaf-mode-handoff`
Next issue: https://github.com/Ramahadam/holy-quran/issues/11

## Current State

PR #17 is merged:

- https://github.com/Ramahadam/holy-quran/pull/17
- Merge commit on `main`: `7184e54`
- Issue #16 is closed.

What landed:

- `scripts/verify_madani_page_boundaries.py`
- `scripts/test_verify_madani_page_boundaries.py`
- `docs/quran-page-boundary-validation.md`

The app now has repeatable validation that the checked-in `assets/quran/verses.json`
page assignments cover 6,236 verses across 604 pages. The optional online check
compares all verse page assignments against Quran.com / Quran Foundation v4 data.

Important result:

- Phase 1 Classic Mode page-boundary data is validated.
- Classic Mode still intentionally does not promise exact printed line breaks,
  visual density, HD page images, or word coordinate mapping.

## Open Next Task

Issue #11 already exists, so no duplicate issue was created:

- Issue #11: https://github.com/Ramahadam/holy-quran/issues/11
- Title: `Phase 2: Mushaf Mode physical page fidelity`
- Current label: `enhancement`

Issue #11 is a Phase 2 tracker. It should not be treated as a small coding task
until the asset and coordinate-source decisions are pinned down.

Recommended next branch:

```bash
git checkout main
git pull --ff-only
git checkout -b feature/issue-11-mushaf-mode-scope
```

## Product Boundary

Source of truth:

- `Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`
- `docs/quran-page-boundary-validation.md`
- Issue #11

Relevant PRD interpretation:

- Phase 1 / Classic Mode: KFGQPC vector font rendering with validated page
  assignments.
- Phase 2 / Mushaf Mode: HD page images plus coordinate mapping.
- Bookmarks and last-read state should remain anchored to `VerseID` so Classic
  Mode and Mushaf Mode can share user state.

## Code Context

Use codebase-memory MCP tools first for code discovery.

Relevant current code paths:

- `lib/presentation/screens/reading_screen.dart`
  - Current reading UI uses a `PageView.builder` over 604 pages.
  - `_QuranPage` resolves the first verse on the current page for last-read state.
- `lib/data/repositories/quran_repository_impl.dart`
  - `getVersesByPage(int page)` validates the 1-604 range and returns verses by
    `page`.
  - `getPageForVerse(String verseId)` maps a stored `VerseID` back to a page.
- `assets/quran/verses.json`
  - Contains validated Classic Mode page assignments.
- `docs/quran-page-boundary-validation.md`
  - Documents the validated Phase 1 page data and Quran.com source.

## Recommended Task 9 Scope

Start with a Phase 2 scoping/spec slice, not a full implementation.

Deliverables:

1. Identify candidate source(s) for 604 HD Madani Mushaf page images.
2. Identify candidate source(s) for verse/word coordinate mapping.
3. Document licensing/usage constraints, offline bundle size implications, and
   whether assets can be checked into the repo.
4. Propose a coordinate schema tied to stable `VerseID` values.
5. Propose how Mushaf Mode should plug into the existing reading state without
   breaking Classic Mode.
6. If implementation is still too broad, split #11 into smaller ready-for-agent
   issues.

## Non-Goals For The Next Agent

Do not start these until the source/licensing/schema decisions are clear:

- Do not download or commit 604 HD Mushaf page images.
- Do not invent coordinate JSON by hand.
- Do not add Tafseer tap regions or word overlays.
- Do not replace Classic Mode.
- Do not change validated `assets/quran/verses.json` page assignments unless a
  new authoritative source proves a discrepancy.

## Acceptance Criteria For The Next Slice

- [ ] Issue #11 has a concrete implementation plan or is split into smaller issues.
- [ ] HD image source and coordinate source are documented with licensing notes.
- [ ] Coordinate schema is documented and maps to `VerseID`.
- [ ] Storage/bundle-size tradeoffs are recorded.
- [ ] Classic Mode compatibility and shared bookmark/last-read behavior are
      explicitly preserved.
- [ ] No Phase 2 assets are committed unless their source and usage rights are
      already documented.

## Suggested Verification

For scoping-only work:

```bash
git diff --check
```

For any app code changes:

```bash
flutter analyze
flutter test
```

If page-boundary data is touched:

```bash
python3 scripts/verify_madani_page_boundaries.py
python3 scripts/verify_madani_page_boundaries.py --online-quran-com
```

## Workspace Notes

Unrelated untracked files were present before this handoff and should remain
untouched unless the user explicitly asks:

- `AGENTS.md`
- `android/build/`
- `build.yaml`
- `docs/handoff-task6-final-20260525.md`
- `docs/handoff-task7-20260526.md`
- `ios/Podfile.lock`
- `macos/Podfile.lock`

## Suggested Skills

- `triage`: if #11 needs to be split into smaller issues.
- `spec-driven-development`: before any Phase 2 implementation.
- `source-driven-development`: to verify asset/API/source decisions.
- `frontend-ui-engineering`: if implementing Mushaf Mode UI.
- `security-and-hardening`: if adding external asset download/update behavior.
- `code-review-and-quality`: before merge.
