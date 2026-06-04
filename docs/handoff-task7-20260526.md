# Handoff: Holy Quran App — Ready for Task 7 / KFGQPC Classic Mode Font Rendering

Date: 2026-05-26
Repository: `/Users/ram/Desktop/Holy Quran`
Current branch: `main`
Current HEAD: `8359af2 fix: improve bookmark removal from home`

## Current State

`main` is synced with `origin/main`.

Most recent completed work:

- PR #12 merged: https://github.com/Ramahadam/holy-quran/pull/12
- Commit: `8359af2 fix: improve bookmark removal from home`
- This was a follow-up to Task 6 / PR #10: https://github.com/Ramahadam/holy-quran/pull/10

Prior durable handoff:

- `docs/handoff-task6-final-20260525.md`

That doc captures the merged bookmark UX follow-up and the roadmap correction after rereading the PRD.

## Workspace Notes

There are untracked files in the working tree:

- `AGENTS.md`
- `android/build/`
- `build.yaml`
- `docs/handoff-task6-final-20260525.md`
- `ios/Podfile.lock`
- `macos/Podfile.lock`

These were intentionally left untouched in prior work. Do not stage/delete them unless the user explicitly confirms they should be included.

## Next Task

Pick up Issue #13:

- https://github.com/Ramahadam/holy-quran/issues/13
- Title: `feat: Add KFGQPC font rendering for Classic Mode`

This is the next Phase 1 task.

Important distinction:

- Phase 1 / Classic Mode: KFGQPC vector font rendering.
- Phase 2 / Mushaf Mode: HD page images plus coordinate mapping.

Do **not** start HD image rendering, coordinate JSON, or Tafseer tap-region work for Issue #13 unless the user explicitly redirects. Existing Issue #11 is the more Phase-2-sounding physical Mushaf fidelity issue:

- https://github.com/Ramahadam/holy-quran/issues/11

## Source Of Truth

Read these before planning:

- PRD: `Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`
- Prior handoff: `docs/handoff-task6-final-20260525.md`
- Issue #13: https://github.com/Ramahadam/holy-quran/issues/13

Relevant PRD roadmap read:

- Phase 1 MVP includes KFGQPC Vector Font rendering, prayer-time notifications, and Supabase feedback.
- Phase 2 includes HD image rendering with coordinate mapping, Focus Mode, and manual backup/import/export.

## Suggested Next-Session Plan

1. Confirm scope with the user if needed: Issue #13 is Phase 1 Classic Mode typography, not Phase 2 image mapping.
2. Use source-driven research to identify the correct KFGQPC Hafs Digital Font asset and licensing/source.
3. Add/register the font in Flutter (`pubspec.yaml` and asset path).
4. Apply the font to Arabic Quran text in the reading view.
5. Improve Bismillah presentation where data allows, without promising exact physical Mushaf line/page fidelity.
6. Preserve accessibility/dynamic text scaling.
7. Add/update focused widget tests where practical.
8. Run `flutter analyze` and `flutter test`.
9. Open PR against `main` and run `code-review-and-quality` before merge.

## Recommended Skills

- `spec-driven-development`: pin the Phase 1 scope before coding.
- `source-driven-development`: verify the official font/source before bundling anything.
- `frontend-ui-engineering`: typography, Bismillah treatment, accessibility, and visual polish.
- `code-review-and-quality`: review before merge.

## Code Discovery Reminder

This repo's AGENTS instructions require codebase-memory MCP tools first for code discovery:

- `search_graph`
- `trace_path`
- `get_code_snippet`
- `query_graph`
- `get_architecture`

Fallback to shell search only for docs/config/text or when graph tools are insufficient.
