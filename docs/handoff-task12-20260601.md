# Handoff: Next PRD Task

Date: 2026-06-01

Repository: `/Users/ram/Desktop/Holy Quran`

## Context

This handoff is for the next task after the merged Focus Mode/Mushaf reader work and the merged manual backup work. Start by reading:

- `/Users/ram/Desktop/Holy Quran/Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`
- `/Users/ram/Desktop/Holy Quran/docs/`
- `/Users/ram/Desktop/Holy Quran/docs/handoff-task11-20260530.md`

The current product direction is still the PRD's privacy-first "Digital Sanctuary" app, but the Mushaf implementation path has changed from PNG/HD image pages to the accepted QCF/package-rendered approach.

## Current State

Current branch:

- `main`

GitHub state checked during this handoff:

- Open PRs: none
- Open issues: none

Recently completed work:

- PR #30, `feature/issue-23-focus-mode-verse-detail`, was merged.
- PR #31, `feature/issue-24-manual-backup`, was merged.
- PR #32 and Issue #11 were closed without merging because they reflected the older PNG image direction.

Important worktree note:

- Tracked files are clean on `main`.
- There are many unrelated untracked files and docs in the worktree. Leave them alone unless the next task explicitly targets them.

## Completed PRD Areas

Focus Mode and Mushaf reader:

- Long-press verse detail/focus mode is implemented and merged.
- Ayah marker placement was fixed.
- QCF/package rendering is the accepted path.
- Do not reintroduce PNG page assets unless the user explicitly reopens that direction.

Manual backup:

- Encrypted `.quran` export/import is implemented and merged.
- Android export uses the share sheet because `file_selector_android` does not provide a save-location picker.
- Round-trip and failure-path tests were added.

## Product Decision To Preserve

The PRD's section 3.3 still describes v2 Mushaf Mode as HD images with coordinate mapping. That is historical product intent, but the current implementation decision is QCF/package rendering. Treat the image-source docs in `/docs` as historical context unless the user explicitly asks to revive page images.

Also preserve the Isar schema fix from recent work: generated schema IDs must remain valid for Flutter web while preserving native Isar collection/index identity. Do not blindly regenerate and commit Isar `.g.dart` files without checking both web compilation and native Isar startup.

## Recommended Next Task

Create a new issue for the anonymous feedback pipeline from PRD section 6.

Why this should be next:

- It is still a Phase 1 PRD item.
- It supports the PRD's Supabase feedback/dashboard plan.
- It is smaller and cleaner than prayer-time linked notifications.
- It can be implemented without touching private reading history or adding accounts.

Suggested issue title:

- `Add anonymous Supabase feedback pipeline`

Suggested branch:

- `feature/anonymous-feedback-pipeline`

Suggested acceptance criteria:

- Add an anonymous feedback submission path using Supabase.
- Do not collect accounts, names, emails, bookmarks, reading history, or last-read position.
- Add a simple app entry point for feedback, likely from the home/menu/settings surface.
- Store feedback text plus only privacy-safe metadata, such as app version/platform if needed.
- Put Supabase access behind a service/repository abstraction so tests can use fakes.
- Add validation for empty or overly long feedback.
- Add failure handling that does not lose user trust or expose technical details.
- Document required Supabase configuration values.
- Add tests for successful submit, submit failure, invalid input, and privacy-safe payload shape.

## Next Larger PRD Task

After feedback, the next Phase 1 feature should be prayer-time linked notifications from PRD section 4.1.

Before coding that, decide:

- Prayer-time calculation/source.
- Iqama offset behavior.
- Notification permission UX for Android and iOS.
- Snooze behavior.
- Local scheduling strategy.
- Whether any settings are user-configurable in the MVP.

Suggested future issue title:

- `Add prayer-time linked reading notifications`

## Defer For Now

- Audio recitations: PRD Phase 3.
- Discover topic chips: PRD Phase 3.
- Community error-reporting loop: later unless feedback work expands into it.
- PNG/HD Mushaf pages: closed/superseded by the QCF/package renderer path.

## Suggested Skills For The Next Session

- `spec-driven-development`: convert the PRD feedback section into concrete requirements.
- `to-issues`: create the GitHub issue before coding.
- `security-and-hardening`: keep feedback payloads privacy-safe.
- `frontend-ui-engineering`: build the feedback entry point and dialog/screen.
- `test-driven-development`: cover service/repository behavior and validation.
- `code-review-and-quality`: review before merge.
- `git-workflow-and-versioning`: create branch, commit, PR, merge, and cleanup.

## First Steps For The Next Agent

1. Confirm `gh issue list --state open --limit 50` and `gh pr list --state open --limit 50`.
2. Read PRD sections 3.1, 5, 6, and 7.
3. Create the GitHub issue before coding.
4. Create a feature branch from up-to-date `main`.
5. Use codebase-memory MCP first for code discovery, per `AGENTS.md`.
6. Keep changes narrow: feedback service, configuration docs, UI entry point, tests.
