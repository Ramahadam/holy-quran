# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Branch and Issue Discipline

**Every feature gets its own branch and tracking issue. Clean up after merge.**

### Before Starting Feature Work
1. **Create GitHub issue** describing the feature/task with:
   - Clear overview and context
   - Detailed requirements or acceptance criteria
   - Technical notes and considerations
   - Related issues and dependencies
2. **Create local branch** from main:
   ```bash
   git checkout main
   git pull
   git checkout -b feature/descriptive-name
   ```
   Use naming conventions:
   - `feature/` for new features
   - `fix/` for bug fixes
   - `refactor/` for refactoring work
3. **Reference issue number** in all commits (e.g., "feat: Add models (#3)")

### During Development
- Work only on your feature branch
- Never commit directly to main
- Keep commits atomic and focused
- Write clear commit messages

### After PR Merge
**Always clean up branches after merge:**
```bash
# Switch back to main
git checkout main

# Pull the merged changes
git pull

# Delete local feature branch
git branch -d feature/branch-name

# Delete remote branch (if not auto-deleted)
git push origin --delete feature/branch-name
```

This workflow ensures:
- Clean PR reviews with focused changes
- Easy rollback if needed
- Clear work-in-progress tracking
- No stale branches cluttering the repository
- Atomic, reviewable units of work

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues for `Ramahadam/holy-quran`. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the repository's existing lightweight GitHub label vocabulary. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository using root `CONTEXT.md` and `docs/adr/`. See `docs/agents/domain.md`.

## Project overview

Privacy-first Flutter Quran reader (Android + iOS only; desktop/web dirs are unsupported scaffolding) plus a Cloudflare Worker in `cloudflare/worker/`. Read `README.md` for the full privacy/backup rules and `CONTEXT.md` for domain vocabulary before changing behavior.

## Commands

CI (`.github/workflows/quality.yml`) pins Flutter 3.38.9. Run the same lanes locally:

```sh
flutter pub get
bash scripts/check_dart_format.sh           # non-mutating format check (excludes *.g.dart)
flutter analyze
flutter test --coverage --exclude-tags golden
python3 scripts/check_persistence_coverage.py   # line-coverage floors for repositories + backup service
flutter test test/presentation/bookmarks_screen_test.dart          # single file
flutter test test/quran_backup_test.dart --plain-name "rejects"    # single test by name
```

- Golden tests (`--tags golden`, `test/mushaf_golden_test.dart`, snapshots in `test/goldens/`) are owned by CI's macOS 26 Intel runner; local results on other machines may differ. Failure diffs land in `test/failures/`.
- `test/anonymous_feedback_live_test.dart` writes to production D1; it only runs with `--dart-define=RUN_CLOUDFLARE_LIVE_TESTS=true`.
- Isar schema changes: `dart run build_runner build --delete-conflicting-outputs` (regenerates `lib/data/local/entities/*.g.dart`; `build.yaml` sets `web: true`). Never hand-edit or hand-format `.g.dart` files.
- Localization: edit `lib/l10n/app_en.arb` / `app_ar.arb`; `flutter pub get` / build regenerates `app_localizations*.dart` (checked in, must stay formatter-clean).
- Worker (Node 22): `cd cloudflare/worker && npm ci && npm run typecheck && npm test`; single test: `npx vitest run test/request-size.test.ts`.
- Python tooling (3.12): `python3 scripts/test_fetch_quran_data.py`, `scripts/test_verify_madani_page_boundaries.py`, `scripts/test_import_mushaf_svg_coordinates.py`, `python3 -m unittest discover -s scripts -p test_check_android_page_alignment.py`.
- Run against a non-default Worker: `flutter run --dart-define-from-file=config/cloudflare.local.json` (copy from `config/cloudflare.local.example.json`; public values only).

## Architecture

- **Layers**: `lib/domain/models` (plain models) → `lib/data` (Isar entities, repositories, services) → `lib/presentation` (Riverpod providers, screens, widgets). Repositories are exposed as Riverpod `Provider`s in `lib/presentation/providers/quran_providers.dart`; tests swap implementations via `ProviderScope` overrides. `main.dart` initializes `IsarService` and preloaded locale/theme stores before `runApp`, falling back to `DatabaseErrorApp` on DB failure.
- **Quran content install**: text ships as `assets/quran/{surahs,verses}.json` with SHA-256 digests in `assets/quran/checksums.txt`. On startup `QuranRepositoryImpl` compares the bundled digest to the one recorded in Isar (`QuranDataMetadataEntity`) and, if changed, validates and replaces the Quran collections in a single transaction. Bookmarks and reading position live in separate collections and must survive upgrades (`test/data/repositories/quran_repository_upgrade_test.dart`, legacy fixture in `test/fixtures/isar_3_1/`). Any asset change must regenerate checksums and pass `scripts/verify_madani_page_boundaries.py`; do not use `scripts/add_page_numbers.py` as a source of truth.
- **Two readers (ADR-0001)**: Classic (vertical, reflowable, `reading_classic_content.dart`) and Mushaf (horizontal 604 pages rendered with the `qcf_quran` package's glyph fonts, not images — `mushaf_*` widgets, `qcf_quran_data_source.dart`). Both resolve bookmarks/last-read/verse detail via the canonical `VerseID`. Only import the public `package:qcf_quran/` API; `test/data/quran/qcf_dependency_boundary_test.dart` fails on `package:qcf_quran/src/` imports.
- **Online features**: only Ayah Study tafsir and anonymous feedback touch the network, both through one Worker (`cloudflare/worker/src/index.ts`: `/v1/tafsir`, `/v1/feedback`, `/health`, `/privacy[/ar]`). The Worker holds Quran Foundation credentials as secrets and stores feedback in D1 (`migrations/`). The Flutter app must never carry secrets (`test/backend_configuration_policy_test.dart`) and must not send reading data or identifiers beyond the rate-limit installation ID. See `docs/cloudflare-backend.md`.
- **Backups**: `lib/data/backup/` — passphrase-encrypted (PBKDF2 + AES-256-GCM) local files; restore validates every `VerseID` against bundled data before replacing state. Limits are in `quran_backup_limits.dart`. File I/O uses conditional imports (`_io` / `_stub`).

## Gotchas

- Some tests assert on repo files: `test/dart_formatting_policy_test.dart` checks that `README.md` and `quality.yml` contain the exact format-check command and step order. Update them together.
- `docs/handoff-*` and the root image-download docs are historical (Supabase / scanned-image experiments) — not current instructions.
- Release builds: `flutter build appbundle --release` / `flutter build ipa --release`; see `docs/release-builds.md` and `docs/android-16kb-release-check.md`.
