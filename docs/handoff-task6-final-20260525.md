# Handoff: Holy Quran App — Bookmark UX Follow-up Merged, Next Task Ready

Date: 2026-05-25
Repository: `/Users/ram/Desktop/Holy Quran`
Current branch: `main`
Current HEAD: `8359af2 fix: improve bookmark removal from home`

## Current State

The bookmark UX follow-up is complete and merged:

- PR #12: https://github.com/Ramahadam/holy-quran/pull/12
- Commit: `8359af2 fix: improve bookmark removal from home`
- Follow-up to merged Task 6 PR #10: https://github.com/Ramahadam/holy-quran/pull/10

What changed in PR #12:

- "Continue Reading" no longer uses a bookmark icon; it now reads visually as resume/last-read.
- Home screen shows recent bookmarks.
- Users can remove a recent bookmark directly from the home/index screen.
- Bookmark repository/provider now fetches recent bookmarks with a limit instead of loading every bookmark.
- Reading screen invalidates recent bookmark state after long-press bookmark toggles.
- Widget tests were updated for page-based reading providers and bookmark removal behavior.

Verification already run before merge:

- `flutter analyze`
- `flutter test test/widget_test.dart`
- `flutter test`

## Workspace Notes

`main` is synced with `origin/main`.

Untracked files remain and were intentionally not touched:

- `AGENTS.md`
- `android/build/`
- `build.yaml`
- `ios/Podfile.lock`
- `macos/Podfile.lock`

Do not delete or stage these unless the user explicitly asks or confirms they are expected project changes.

## PRD Roadmap Read

The PRD has a clear phase order:

- Phase 1 MVP / Classic Mode:
  - Flutter + Isar + Riverpod foundation
  - KFGQPC Vector Font rendering
  - Prayer-time linked notifications
  - Supabase feedback integration
- Phase 2 Enhanced Experience / Mushaf Mode:
  - HD image rendering with coordinate mapping
  - Focus Mode
  - Manual Export/Import backup
- Phase 3 Advanced:
  - Audio recitations
  - Discover topic chips
  - Community error-reporting loop

Based on this, HD image rendering and verse/image coordinate mapping are **not** the immediate next task unless the user explicitly chooses to jump ahead to Phase 2.

Relevant source of truth:

- PRD: `Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`
- Key PRD sections:
  - §3.3 Hybrid "Abstract Renderer" Architecture
  - §4.1 Spiritual Rhythm Notifications
  - §4.2 Accessibility / Focus Mode
  - §6 Feedback & Dashboard
  - §7 Roadmap

## Recommended Next Task

The next session should stay in Phase 1 and choose one of these MVP items:

1. **KFGQPC Vector Font rendering** — recommended next step because the user specifically noticed Arabic layout/Bismillah fidelity problems, and the PRD lists this as Classic Mode v1 work.
2. **Prayer-time linked notifications** — next Phase 1 feature after core reading experience.
3. **Supabase feedback integration** — also Phase 1, but less directly connected to the recent reading-view discussion.

Recommended default: **KFGQPC Vector Font rendering**.

This should improve Arabic rendering, give the Bismillah a more appropriate visual treatment, and keep the app aligned with v1 Classic Mode. It should not promise exact physical Mushaf page parity.

Issue #11 currently says:

- https://github.com/Ramahadam/holy-quran/issues/11
- Title: `feat: Ensure verse layout per page matches physical Madani Mushaf`

Treat #11 carefully. As written, it sounds like Phase 2 Mushaf image fidelity, not the next Phase 1 task. Before implementing against #11, either:

- refine/re-scope it to a Phase 1 font/typography task, or
- leave it open for Phase 2 and create a new Phase 1 issue for KFGQPC font rendering.

Important product interpretation:

- Classic/vector mode should use KFGQPC Hafs Digital Font, support dynamic scaling, and look dignified.
- Classic/vector mode should **not** be forced to exactly match printed Mushaf line count on every device.
- Exact printed-page fidelity belongs later to Phase 2 Mushaf Mode: page images plus coordinate mapping.
- Coordinate mapping should eventually let taps on verse regions open Tafseer / verse detail while bookmarks and last-read continue using `verseId`.

## Suggested Approach For Next Session

Start by clarifying whether to:

1. Re-scope Issue #11 into a Phase 1 KFGQPC Classic Mode typography task, or
2. Create a new issue for KFGQPC font rendering and leave #11 for Phase 2 Mushaf Mode.

If proceeding with KFGQPC Classic Mode:

- Identify the specific KFGQPC Hafs font asset to bundle.
- Add it to `pubspec.yaml`.
- Apply it to Arabic Quran text in the reading view.
- Give Bismillah distinct styling where data allows.
- Keep accessibility/dynamic text scaling in mind.
- Verify with widget tests and, if possible, a device/simulator visual check.

Avoid implementing HD images, coordinate JSON, or Tafseer tap regions in this next PR unless the user explicitly redirects to Phase 2.

## Recommended Skills

- `spec-driven-development`: use before coding to pin the Phase 1 scope and avoid slipping into Phase 2.
- `frontend-ui-engineering`: for Quran typography, Bismillah treatment, touch targets, and visual fidelity.
- `source-driven-development`: use if selecting/downloading/validating the official font source.
- `code-review-and-quality`: before merge.

## Code Discovery Reminder

This repo has AGENTS instructions requiring codebase-memory MCP tools before grep/read for code discovery. Use:

- `search_graph`
- `trace_path`
- `get_code_snippet`
- `query_graph`
- `get_architecture`

Fallback to shell search only for docs/config/text or when graph results are insufficient.
