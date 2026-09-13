# Holy Quran Domain Context

## Product purpose

The app provides focused Quran reading with two complementary reading
experiences, local reading continuity, prayer-linked reading reminders, and an
anonymous feedback channel.

## Glossary

- **Ayah / verse**: One Quran verse. Use the domain model's `VerseID` as its
  canonical identity across presentation modes and persisted features.
- **Classic mode**: A vertically scrolling, reflowable comfort-reading view with
  large Arabic text.
- **Mushaf mode**: A horizontally paged, page-faithful view of the canonical 604
  Mushaf pages rendered with QCF glyph data and fonts.
- **Last read**: The persisted `VerseID` representing the reader's meaningful
  current position, not merely a page or scroll percentage.
- **Prayer reading reminder**: A local notification scheduled for a selected
  prayer time plus the user's configured offset.
- **Heartbeat feedback prompt**: An anonymous feedback invitation shown after
  meaningful local reading activity. The production threshold is seven distinct
  reading days.

## Stable product rules

- Keep Classic and Mushaf as distinct reading experiences. Classic reflows and
  scrolls vertically; Mushaf preserves fixed page composition and horizontal
  page navigation.
- Mushaf pages are package/QCF-rendered, not scanned page-image assets.
- Bookmarks, last-read state, and verse detail use the same canonical `VerseID`
  regardless of reading mode.
- A prayer reading reminder fires at prayer time plus its configured offset. It
  is a normal notification scheduled exactly when platform permission allows,
  not continuous alarm-clock ringing.
- Feedback is anonymous by design. Do not attach account identifiers, names,
  email addresses, bookmarks, reading history, IP addresses, or last-read
  position to stored feedback. See `docs/cloudflare-backend.md`.
