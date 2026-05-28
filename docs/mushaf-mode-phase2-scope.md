# Mushaf Mode Phase 2 Scope

Date: 2026-05-28
Issue: https://github.com/Ramahadam/holy-quran/issues/11

## Objective

Define the Phase 2 Mushaf Mode implementation boundary before adding HD page
assets, coordinate data, or UI code. Mushaf Mode should reproduce the physical
Madani Mushaf page experience while preserving the current Classic Mode and
keeping bookmarks and last-read state anchored to stable `VerseID` values.

This is a scoping/spec slice. No Mushaf page images, SVG pages, or coordinate
datasets are committed by this document.

## Product Context

The PRD defines a hybrid renderer:

- Classic Mode: KFGQPC Hafs vector font rendering, lightweight and dynamically
  scalable.
- Mushaf Mode: HD page images plus coordinate mapping for interaction.
- Unified state: bookmarks and last-read positions remain saved as `VerseID`.

The PRD also lists Focus Mode and manual export/import backup in Phase 2. Those
are real Phase 2 requirements, but they are broader than issue #11 and should be
tracked separately so Mushaf page fidelity can stay reviewable.

## Current App Boundary

Relevant current code, discovered through the codebase graph:

- `lib/presentation/screens/reading_screen.dart`
  - Uses `PageView.builder` over 604 pages.
  - Resolves the first verse on the current page for reading-position saves.
- `lib/data/repositories/quran_repository_impl.dart`
  - `getVersesByPage(int page)` validates the 1-604 range and returns verses by
    `page`.
  - `getPageForVerse(String verseId)` maps a saved `VerseID` to a page.
- `lib/domain/models/reading_position.dart`
  - Stores `verseId` and `lastReadAt`; no renderer-specific state.
- `lib/domain/models/verse.dart`
  - Stores `verseId`, surah/verse numbers, text, optional translation, and page.
- `docs/quran-page-boundary-validation.md`
  - Documents that current Classic Mode page assignments validate against
    Quran.com / Quran Foundation v4 data.

Implication: Mushaf Mode should plug into the existing page navigation and
reading-position model rather than replacing the repository or changing
`assets/quran/verses.json`.

## Candidate Sources

| Candidate | Use | What it provides | License/usage notes | Fit |
| --- | --- | --- | --- | --- |
| King Fahd Complex Digital Mushaf (`dm.qurancomplex.gov.sa`) | Primary page artwork source | Official Madani Mushaf vector artwork for print and digital uses | The rights page says the digital copy can be used free of charge for personal work, organizations, paper printing, desktop publishing, media, websites, and computer programs inside and outside Saudi Arabia. Commercial Quran printing has separate Saudi restrictions. | Best authoritative source for page fidelity, but raw materials must be transformed into app-friendly assets. |
| Mushaf Database Ligature-Based SVG | Page rendering and semantic structure | 604 Hafs Madinah Mushaf SVG files with page, line, word, ayah-marker, and metadata groups | Repository license grants use, copy, modification, publication, distribution, derivatives, and commercial use, with a Quranic-integrity condition. It is derived from King Fahd Complex digital Mushaf materials. | Strongest implementation candidate because it combines visual fidelity with queryable structure. Need verify repository contents and file size before bundling. |
| Quran Foundation / Quran.com v4 API | Validation and fallback layout metadata | Verse/page lookup, word `page_number`, `line_number`, `position`, QCF glyph fields, and `verse_key` | Official API docs. Current docs show token/client headers for Quran Foundation endpoints; app should not depend on runtime API calls for offline Mushaf Mode. | Good validation source and possible import source for line/word identity. Not enough by itself for image hit-test coordinates. |
| quran.com-images | Historical generator and glyph bounds | Scripts that generate page images and update a database with glyph bounds | README says code is GPL/copyleft, but fonts/pages in `res/fonts` belong to King Fahd Complex. License boundary is mixed. | Useful reference only. Avoid committing generated assets from it until licensing and data provenance are confirmed. |
| `qurancoor` / `quran-word-coords` | Word coordinate dataset | Pixel boxes for 77,320 words across 604 Madani Mushaf page images; coordinates are relative to 900x1437 images | Published as MIT on PyPI. It depends on/generated from quran.com-images and page images, so provenance should be reviewed before adoption. | Promising for a prototype and coordinate-schema comparison, but should not become the canonical source until provenance is reviewed. |

## Recommended Source Decision

Use Mushaf Database Ligature-Based SVG as the first implementation candidate.

Reasons:

- It is page-native: one SVG per Madinah Mushaf page.
- It exposes semantic metadata for lines, words, ayah markers, diacritics, and
  non-Quranic elements.
- It avoids inventing coordinates by hand.
- It can support future word-level interaction without requiring separate PNG
  hit-test maps.
- Its coordinate system is vector based, so it can scale cleanly to different
  screens.

Keep Quran Foundation / Quran.com v4 as the validation source for page, verse,
line, and word identity, not as the runtime dependency.

Do not adopt quran.com-images or qurancoor as the canonical source until their
asset provenance is reviewed against the King Fahd Complex terms and the exact
page image edition is proven to match the desired Mushaf.

## Coordinate Schema Proposal

Store imported Mushaf interaction data in normalized page coordinates, even if
the initial source is SVG.

```json
{
  "schemaVersion": 1,
  "mushaf": {
    "id": "madani-hafs-kfgqpc",
    "source": "mushafdatabase-ligature-svg",
    "pageCount": 604,
    "coordinateSpace": {
      "type": "normalized",
      "width": 1.0,
      "height": 1.0
    }
  },
  "pages": [
    {
      "page": 3,
      "sourceViewBox": "0 0 382.68 547.09",
      "firstVerseId": "2:6",
      "lastVerseId": "2:16",
      "items": [
        {
          "type": "word",
          "verseId": "2:6",
          "wordIndex": 1,
          "line": 1,
          "bounds": { "x": 0.721, "y": 0.084, "w": 0.062, "h": 0.038 },
          "sourceId": "md-word-001"
        },
        {
          "type": "ayahMarker",
          "verseId": "2:6",
          "line": 1,
          "bounds": { "x": 0.112, "y": 0.084, "w": 0.028, "h": 0.038 },
          "sourceId": "md-aya-mark-006"
        }
      ]
    }
  ]
}
```

Rules:

- `verseId` uses the existing app format: `surah:ayah`.
- `wordIndex` is 1-based within the verse.
- `page` is 1-604 and must match the validated Madani page assignment.
- `bounds` are normalized to the rendered page rectangle, not the device screen.
- Ayah/verse-level hit regions can be derived by unioning word and ayah-marker
  bounds for the same `verseId`.
- Preserve source IDs so validation scripts can trace app data back to the
  imported SVG or dataset.

## Storage And Bundle Tradeoffs

Mushaf Mode can be shipped three ways:

| Option | Bundle impact | Offline behavior | Risk |
| --- | --- | --- | --- |
| Bundle all 604 SVG pages and coordinate metadata | Largest install size, but vector assets may compress well. Actual size must be measured from selected source. | Fully offline from first launch. | App-store size increase and slower initial asset load unless pages are cached/lazy-loaded. |
| Bundle only metadata, download page assets after install | Smaller initial app. | Requires first-run download and cache integrity checks. | Conflicts with privacy/offline-first expectations unless clearly optional and verified. |
| Generate raster WebP/PNG derivatives from SVG and bundle them | Predictable Flutter image rendering and memory behavior. | Fully offline from first launch. | Larger than vector in many cases; loses semantic SVG structure unless coordinates are kept separately. |

Recommended first implementation path:

1. Measure the selected SVG dataset and a compressed raster derivative.
2. Prototype one page renderer from bundled local assets.
3. Verify memory, zoom, and legibility on small mobile screens.
4. Choose SVG-native or raster+JSON only after measurement.

## Integration Plan

1. Add a reading-mode selection model: `classic` and `mushaf`.
2. Keep `ReadingPosition(verseId, lastReadAt)` unchanged.
3. Keep `Bookmark` storage anchored to `verseId`.
4. Reuse existing page navigation: page number remains the bridge between modes.
5. Add a Mushaf page asset resolver that maps `page` to the selected local page
   asset.
6. Add a coordinate repository that maps `page` and tap location to `VerseID`
   and optionally `(verseId, wordIndex)`.
7. Add validation scripts before committing any full dataset:
   - page coverage is exactly 1-604;
   - every mapped `verseId` exists in `assets/quran/verses.json`;
   - first/last verse per page matches the existing validated page data;
   - every Quranic word has a page and line mapping;
   - no runtime network dependency is required for reading bundled pages.

## Proposed Issue Split

Issue #11 should remain the parent tracker. Split implementation into smaller
ready-for-agent issues:

1. Source and asset proof-of-concept
   - Import or vendor a tiny sample from the chosen source, render pages 1, 2,
     3, and 604 locally, and measure asset size.
2. Coordinate import and validation script
   - Convert source metadata into the proposed schema and validate coverage
     against `assets/quran/verses.json`.
3. Mushaf Mode renderer
   - Add mode selection and page rendering without tap interactions.
4. Verse hit-testing
   - Map taps on a Mushaf page back to `VerseID`; preserve shared bookmarks and
     last-read state.
5. PRD follow-up: Focus Mode
   - Long-press verse detail view for accessibility, shared by Classic and
     Mushaf modes where possible.
6. PRD follow-up: manual export/import backup
   - Encrypted local `.quran` export/import for bookmarks and reading state.

## Non-Goals Until Source Decision Is Locked

- Do not commit 604 page assets.
- Do not hand-author coordinate JSON.
- Do not replace Classic Mode.
- Do not change validated page assignments in `assets/quran/verses.json`.
- Do not add runtime Quran API dependencies for normal reading.
- Do not add Tafseer or translation overlays in the first renderer slice.

## Verification For This Scoping Slice

```bash
git diff --check
```

For future implementation:

```bash
flutter analyze
flutter test
python3 scripts/verify_madani_page_boundaries.py
```

## Sources

- PRD: `Master Product Requirements Document (PRD)_ Holy Quran Reading App.md`
- Page boundary validation: `docs/quran-page-boundary-validation.md`
- King Fahd Complex Digital Mushaf project:
  https://dm.qurancomplex.gov.sa/project-def/
- King Fahd Complex Digital Mushaf rights:
  https://dm.qurancomplex.gov.sa/rights/
- Mushaf Database Ligature-Based SVG:
  https://github.com/mushafdatabase/MushafDatabase-Ligature-Based-SVG
- Mushaf Database license:
  https://github.com/mushafdatabase/MushafDatabase-Ligature-Based-SVG/blob/main/LICENSE
- Quran Foundation page-layout guide:
  https://api-docs.quran.foundation/docs/tutorials/fonts/page-layout/
- Quran.com by-page API docs:
  https://api-docs.quran.com/docs/content_apis_versioned/4.0.0/verses-by-page-number/
- quran.com-images:
  https://github.com/quran/quran.com-images
- qurancoor:
  https://pypi.org/project/qurancoor/1.2.1/
