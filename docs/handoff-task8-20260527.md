# Handoff: Holy Quran App — Task 8 Ready For Agent

Date: 2026-05-27  
Repository: `/Users/ram/Desktop/Holy Quran`  
Current branch: `feature/issue-15-task-8-mushaf-scope`  
Current HEAD: `9c7169f feat: add KFGQPC classic font rendering (#13) (#14)`

## Current State

PR #14 is merged:

- https://github.com/Ramahadam/holy-quran/pull/14
- Merge commit: `9c7169f70da382d6baad5fa007ab706d2e7bc29e`
- Issue #13 is complete: KFGQPC Hafs font rendering for Classic Mode.

What landed:

- Bundled `assets/fonts/UthmanicHafs_V22.ttf`.
- Registered `KFGQPCHafsUthmanicScript` in `pubspec.yaml`.
- Applied the font to Reading Screen Arabic Quran text and Surah headers.
- Added display-only Bismillah before Surahs 2-8 and 10-114, while preserving Al-Fatihah verse text and omitting At-Tawbah.
- Added focused widget tests for font usage, Bismillah styling, continuation pages, and At-Tawbah.
- Added `.github/workflows/verify-kfgqpc-font.yml` with least-privilege `contents: read`.
- Added `scripts/verify_qpc_hafs_font.sh` to verify the checked-in font against the pinned QUL/Tarteel CDN copy and SHA-256.
- Documented font provenance in `assets/fonts/README.md`.

Verification before merge:

- `scripts/verify_qpc_hafs_font.sh`
- `flutter analyze`
- `flutter test`
- `git diff --check`
- GitHub check `verify-qpc-hafs-font`

## Workspace Notes

The PR branch was merged and the remote feature branch was deleted by `gh pr merge --squash --delete-branch`.

Current working tree still has unrelated untracked files that were intentionally left alone:

- `AGENTS.md`
- `android/build/`
- `build.yaml`
- `docs/handoff-task6-final-20260525.md`
- `docs/handoff-task7-20260526.md`
- `ios/Podfile.lock`
- `macos/Podfile.lock`

Do not stage, delete, or normalize those unless the user explicitly asks.

## Open Work

Task 8 issue:

- Issue #15: https://github.com/Ramahadam/holy-quran/issues/15
- Title: `Task 8: Triage Madani Mushaf page-fidelity scope`
- Branch: `feature/issue-15-task-8-mushaf-scope`

Related existing issue:

- Issue #11: https://github.com/Ramahadam/holy-quran/issues/11
- Title: `feat: Ensure verse layout per page matches physical Madani Mushaf`

Important product interpretation from the PRD:

- Phase 1 / Classic Mode now has KFGQPC Vector Font rendering complete.
- Remaining Phase 1 items in the PRD are prayer-time linked notifications and Supabase feedback integration, but no open issues currently exist for them.
- Issue #11 asks for physical Madani Mushaf page fidelity. Treat it carefully because it overlaps with Phase 2 / Mushaf Mode concepts.
- Phase 2 includes HD Mushaf images, coordinate mapping, Focus Mode, and manual Export/Import backup.

Recommended next step:

1. Use Issue #15 as the agent entry point.
2. Triage Issue #11 and decide whether it is:
   - a Phase 1 validation/data-quality task about existing verse page boundaries, or
   - a Phase 2 Mushaf Mode task involving image fidelity and coordinate mapping.
3. If the user wants to stay strictly on Phase 1 MVP, create/triage a new issue for either:
   - prayer-time linked notifications, or
   - Supabase anonymous feedback integration.

## Source Of Truth

Read before planning next implementation:

- `Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`
- `docs/handoff-task6-final-20260525.md`
- `docs/handoff-task7-20260526.md`
- Issue #15: https://github.com/Ramahadam/holy-quran/issues/15
- Issue #11: https://github.com/Ramahadam/holy-quran/issues/11

Relevant PRD anchors:

- §3.3 Hybrid Abstract Renderer Architecture
- §4.1 Spiritual Rhythm Notifications
- §4.2 Focus Mode
- §6 Feedback & Dashboard
- §7 Roadmap

## Suggested Skills

- `triage`: for Issue #11 scope cleanup or creating the next Phase 1 issue.
- `spec-driven-development`: before implementing Issue #11 or any Phase 2-ish work.
- `source-driven-development`: for authoritative Mushaf/page-boundary data or prayer-time source behavior.
- `frontend-ui-engineering`: if the next task touches reading UI, Focus Mode, or page metadata.
- `security-and-hardening`: if implementing Supabase feedback or any external integration.
- `code-review-and-quality`: before merge.

## Code Discovery Reminder

This repo requires codebase-memory MCP tools first for code discovery:

- `search_graph`
- `trace_path`
- `get_code_snippet`
- `query_graph`
- `get_architecture`

Fallback to shell search only for docs/config/text or when graph results are insufficient.
