# Master Product Requirements Document (PRD): Holy Quran Reading App

## 1. Executive summary

The **Holy Quran Reading App** is a privacy-first Flutter application for
Android and iOS. It provides a calm “Digital Sanctuary” for Quran reading while
prioritizing verified text, dependable offline access, accessible interaction,
and local ownership of reading data.

## 2. Product principles

- **Quiet by default:** The app avoids social feeds, accounts, advertising, and
  attention-seeking interface patterns.
- **Verified scripture:** Quran content must be traceable, checksum-verified,
  and rejected safely if it is incomplete or malformed.
- **Offline reading:** Core reading, bookmarks, last-read state, and reminders
  must not depend on a network connection.
- **Private progress:** Reading history and bookmarks stay on the device unless
  the user explicitly creates and moves an encrypted backup file.
- **Simple accessibility:** Large-text Ayah Study, Arabic/English localization,
  dark mode, and clear touch targets take priority over platform-specific input
  tricks.

## 3. Current technical architecture

### 3.1 Mobile application

- **Framework:** Flutter.
- **State management:** Riverpod.
- **Local persistence:** Isar stores verified Quran content, bookmarks, and the
  last-read position. SharedPreferences stores small local settings and prompt
  state.
- **Supported release targets:** Android and iOS. Desktop and web directories
  remain Flutter scaffolding, not supported products.

### 3.2 Quran content and integrity

The complete Quran dataset and Mushaf rendering assets are bundled with each app
release. Runtime reading does not download Quran text or prefetch the next Juz.
The source dataset is generated from KFGQPC Uthmani text exposed through the
Quran.com API, with Saheeh International translation data.

`assets/quran/checksums.txt` is the content manifest. Its two SHA-256 values form
a digest that versions the installed dataset. At startup:

1. The app compares the bundled digest with the digest recorded in Isar.
2. If the digest changed, both JSON assets are checksum-verified and parsed.
3. The app requires exactly 114 surahs and 6,236 ayahs with usable first and
   final Mushaf pages.
4. One Isar transaction replaces only the Quran collections and records the new
   digest.

Validation happens before replacement, and Isar rolls back a failed transaction,
so the previously installed Quran content remains usable after a failed upgrade.
Bookmark and last-read collections are not replaced by Quran upgrades. This is
the implemented atomic update model; there is no runtime dual-partition download
system.

### 3.3 Reading renderers

- **Classic Mode:** Responsive native Arabic text using the KFGQPC Hafs font,
  continuous surah reading, Juz boundaries, and dynamic text sizing.
- **Mushaf Mode:** Page-specific QCF rendering that preserves the 604-page
  Madani flow, with page context, ayah hit regions, bookmarks, and long-press
  access to Ayah Study.
- **Unified state:** Both modes address bookmarks and last-read progress by
  stable `VerseID` values.

### 3.4 Cloudflare services

One Cloudflare Worker (`holy-quran-api`) provides the app’s online-only services:

- Quran Foundation tafsir source discovery and ayah passages. Quran Foundation
  credentials are encrypted Worker secrets and never ship in the app.
- Anonymous feedback submission to the `holy-quran-feedback` D1 database.
- Per-installation and network-level rate limits, plus short-lived edge caching
  for tafsir responses.

Cloudflare is not a sync backend for bookmarks, reading history, reminders, or
backup passphrases.

## 4. User experience and shipped features

### 4.1 Reading and navigation

- Surah and Juz indexes open either Classic or Mushaf reading.
- Bookmarks and the last-read position persist locally across sessions and
  renderer changes.
- Long-pressing an ayah opens **Ayah Study**, which provides large Arabic or
  translated text, bookmark control, adjacent-ayah navigation, and selectable
  tafsir sources.

### 4.2 Accessibility: Focus Mode

- **Interaction:** Long-press on any verse to enter a magnified Verse Detail
  view with large-font tafsir.
- **Navigation:** Keep page turning on the reader's visible touch and swipe
  controls; volume-button page turning is not planned.
- **Onboarding:** The app opens directly into the reading experience without an
  account requirement or onboarding carousel.

**Product decision (July 18, 2026):** Volume-button page turning was evaluated
and dropped. Its benefit is limited to a niche Android reading workflow, it
conflicts with the buttons' standard volume and accessibility uses, and
repurposing the buttons is not suitable for the app's iOS target. The added
platform-specific behavior does not justify its product and maintenance cost.

### 4.3 Reading reminders

Users can configure a local reminder for a selected prayer, prayer time, offset,
and snooze duration. Scheduling and settings remain on device. If notification
permission is denied or scheduling fails, the app reports that state without
affecting reading.

### 4.4 Anonymous feedback

After seven distinct reading days, the app may offer a dismissible feedback
prompt. Dismissing delays another prompt for 30 days; submitting feedback stops
future heartbeat prompts.

Feedback is sent through the Cloudflare Worker. D1 stores only:

- the user-entered feedback text;
- platform;
- app version; and
- the server-generated submission timestamp.

A random 128-bit installation ID is kept in local preferences and sent as a
request header for rate limiting. It is not derived from hardware or user data
and is not stored in the feedback table. The payload excludes accounts, names,
email addresses, bookmarks, reading history, and last-read position.

### 4.5 Encrypted manual backup

Users can save or share an encrypted backup and restore one through the platform
file picker. The backup contains bookmarks and the last-read position only. New
backups require a passphrase of at least eight characters and use
PBKDF2-HMAC-SHA256 key derivation with AES-256-GCM authenticated encryption. The
passphrase never leaves the device and cannot be recovered. Restore validates
the versioned envelope and attempts to reinstate the prior local state if
replacement fails.

## 5. Offline and network behavior

The following work offline from bundled or locally persisted data:

- Classic and Mushaf reading;
- Surah and Juz navigation;
- bookmarks and last-read state;
- reminder configuration and scheduling; and
- backup creation and restoration.

Ayah Study tafsir and anonymous feedback require the Cloudflare Worker. An
offline tafsir failure must leave the local ayah visible and provide a retry
path. Feedback failure must preserve the user’s ability to retry or cancel.

## 6. Release and operations

- Android App Bundles and iOS archives are the supported release artifacts.
- The app version and monotonically increasing build number come from
  `pubspec.yaml`.
- The production Cloudflare Worker URL is the default client configuration.
  Another endpoint may be supplied through a reviewed
  `CLOUDFLARE_API_BASE_URL` Dart define.
- Quran Foundation client credentials are deployed only as Worker secrets.
- Pull requests and `main` run Flutter analysis/tests/coverage, Worker typecheck
  and tests, and Python tooling tests. Platform-sensitive goldens run separately
  against their checked-in snapshots.

Operational commands and identifiers are documented in `README.md`,
`docs/cloudflare-backend.md`, and `docs/release-builds.md`. Historical handoffs
may mention the retired Supabase feedback path or image-based Mushaf experiments;
they are not active setup instructions.

## 7. Roadmap

### Shipped foundation

- Flutter, Riverpod, Isar, Arabic/English localization, and light/dark themes.
- Verified bundled Quran content with atomic Isar upgrades.
- Classic and QCF Mushaf reading with shared bookmark and last-read state.
- Ayah Study with Cloudflare-proxied Quran Foundation tafsir.
- Local prayer-linked reminders and snooze.
- Cloudflare Worker/D1 anonymous feedback.
- Encrypted manual backup and restore.

### Future candidates

- Audio recitations with explicit streaming/offline storage behavior.
- Discovery or topic navigation that does not compromise the quiet reading
  experience.
- A privacy-preserving Quran text error-reporting workflow.
- Scanned-page Mushaf assets only if exact image fidelity is explicitly
  prioritized over package size and interactive text.

---

**Originally prepared by:** Manus AI
**Original date:** May 17, 2026
**Architecture alignment:** August 13, 2026
