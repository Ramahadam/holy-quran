# ADR-0001: Keep Classic and Mushaf as distinct readers

- Status: Accepted
- Date: 2026-08-17

## Context

Comfort reading and page-faithful Mushaf reading have different layout and
navigation requirements. Trying to make one renderer satisfy both goals causes
page-composition regressions in Mushaf mode or constrains text readability in
Classic mode.

## Decision

- Classic mode is a vertically scrolling, reflowable text reader.
- Mushaf mode is a horizontally paged reader that preserves the canonical 604
  page composition using QCF glyph data and fonts rather than scanned images.
- Both readers resolve bookmarks, last-read state, and verse detail through the
  same canonical `VerseID`.
- Renderer-specific layout state may differ, but it must not create a competing
  verse identity or persistence model.

## Consequences

- Reader behavior and visual regression tests must cover Classic and Mushaf
  separately.
- Classic layout improvements should not alter Mushaf page composition.
- Cross-mode navigation and persistence must resolve to an exact verse.
- Replacing QCF rendering with scanned page images or merging the two reader
  behaviors requires a new architectural decision.
