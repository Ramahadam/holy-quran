# Holy Quran

Holy Quran is a privacy-first Flutter reading app for Android and iOS. It
provides an offline Classic reader, a page-faithful Mushaf reader, bookmarks,
last-read tracking, prayer-linked reminders, Ayah Study with tafsir, anonymous
feedback, and encrypted manual backups.

## Supported platforms

Android and iOS are the supported release targets. The macOS, Windows, Linux,
and web directories are Flutter scaffolding only and are not supported release
targets.

## Quick start

Install Flutter, an Android or iOS toolchain, and the platform dependencies
reported by `flutter doctor`. Then run:

```sh
flutter pub get
flutter analyze
flutter run
```

The production Cloudflare Worker URL is built in, so the app does not require a
local backend configuration for normal development. To use another Worker,
copy the example configuration and pass it to Flutter:

```sh
cp config/cloudflare.local.example.json config/cloudflare.local.json
flutter run --dart-define-from-file=config/cloudflare.local.json
```

`config/cloudflare.local.json` is ignored by Git. It may contain only public
client configuration such as `CLOUDFLARE_API_BASE_URL` and `APP_VERSION`.
Quran Foundation credentials belong in Cloudflare Worker secrets and must never
be placed in Flutter configuration.

The optional `.env` helper forwards the same public values:

```sh
bash scripts/flutter_run_with_env.sh
```

## Architecture

| Area | Implementation |
| --- | --- |
| Mobile UI | Flutter with Riverpod |
| Local persistence | Isar for verified Quran content, bookmarks, and last-read position; SharedPreferences for small local settings |
| Quran content | Bundled JSON and QCF assets verified with SHA-256 before installation into Isar |
| Online services | One Cloudflare Worker for Quran Foundation tafsir and anonymous feedback |
| Feedback storage | Cloudflare D1 (`holy-quran-feedback`) |
| Backup | User-selected local file/share flow with passphrase-based AES-256-GCM encryption |

### Quran installation and updates

The complete 114-surah, 6,236-ayah dataset and Mushaf assets ship with the app;
the app does not download Quran text or prefetch the next Juz at runtime. On
startup, the repository compares the bundled checksum digest with the version
installed in Isar. Changed content is fully checksum-validated and parsed
before a single Isar transaction replaces the Quran collections and records the
new digest. A validation or transaction failure leaves the previously installed
Quran content intact. Bookmarks and last-read state use separate collections
and are preserved across Quran content upgrades.

`scripts/fetch_quran_data.py` fetches Quran Foundation QPC Hafs text for the
bundled KFGQPC font. It is an upstream-data fetch helper, not a complete
asset-release pipeline: its output still requires verified Mushaf page
assignments. Any Quran asset update must preserve those assignments, regenerate
`assets/quran/checksums.txt`, pass the repository upgrade tests, and pass the
[Madani page-boundary checks](docs/quran-page-boundary-validation.md) before
release. Do not use the legacy `scripts/add_page_numbers.py` table as the
verification source.

### Offline and privacy behavior

- Classic and Mushaf reading, bookmarks, last-read state, reminders, and backup
  creation/restoration work from local data.
- Ayah Study tafsir and anonymous feedback require network access to the
  Cloudflare Worker.
- Reading history, bookmarks, reminder settings, and backup passphrases are not
  sent to the Worker.
- D1 stores only submitted feedback text, platform, app version, and the server
  timestamp. A random local installation ID is sent only for rate limiting and
  is not stored in the feedback table.
- Backups contain bookmarks and the last-read position. New backups require an
  eight-character passphrase and use PBKDF2-HMAC-SHA256 with AES-256-GCM. The
  passphrase cannot be recovered. Restore accepts files up to 5 MiB and at most
  6,236 bookmarks. Duplicate bookmark Verse IDs are rejected. Every bookmark
  and last-read Verse ID is checked against the bundled Quran data before any
  bookmarks or reading state are replaced, so validation failures leave local
  state unchanged.

See [Cloudflare backend](docs/cloudflare-backend.md) for endpoint, D1, caching,
rate-limit, and deployment details.

## Verification

Run the same Flutter quality lane used by CI:

```sh
flutter analyze
flutter test --coverage --exclude-tags golden
python3 scripts/check_persistence_coverage.py
```

Golden tests are renderer/platform sensitive. The checked-in snapshots are
owned by the CI environment: macOS 26 Intel with Flutter 3.38.9. To reproduce
the required `Mushaf visual regression` check locally in that environment:

```sh
flutter pub get
flutter test --tags golden
```

A mismatch fails the check and CI uploads the expected, actual, isolated-diff,
and masked-diff images generated under `test/failures/`.

Verify the Cloudflare Worker with Node.js 22 or later:

```sh
cd cloudflare/worker
npm ci
npm run typecheck
npm test
```

Verify the Python tooling with Python 3.12 or later:

```sh
python3 scripts/test_fetch_quran_data.py
python3 scripts/test_verify_madani_page_boundaries.py
python3 scripts/test_import_mushaf_svg_coordinates.py
```

The live feedback test is intentionally opt-in because it writes to the remote
D1 database:

```sh
flutter test test/anonymous_feedback_live_test.dart \
  --dart-define=RUN_CLOUDFLARE_LIVE_TESTS=true
```

## Backend development

```sh
cd cloudflare/worker
npm ci
npx wrangler d1 migrations apply holy-quran-feedback --remote
npx wrangler secret put QF_CLIENT_ID
npx wrangler secret put QF_CLIENT_SECRET
npm run deploy
```

## Release builds

After updating `version` in `pubspec.yaml` and passing the verification commands,
build the supported release artifacts:

```sh
flutter build appbundle --release
flutter build ipa --release
```

The production Worker URL is the default. Pass a reviewed
`CLOUDFLARE_API_BASE_URL` override only for a release candidate that should use a
different endpoint. See [Mobile release builds](docs/release-builds.md) for
identifiers, versioning, and store-build details.

## Repository documentation

Active operational documentation lives in `README.md`,
`docs/cloudflare-backend.md`, and `docs/release-builds.md`. Files under
`docs/handoffs/` and files named `docs/handoff-*` record historical work and may
refer to retired Supabase or image-based Mushaf experiments; they are not current
setup instructions.
