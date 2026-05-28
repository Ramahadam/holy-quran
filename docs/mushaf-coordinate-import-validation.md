# Mushaf Coordinate Import And Validation

Date: 2026-05-28
Issue: https://github.com/Ramahadam/holy-quran/issues/20

## Scope

This slice imports coordinate metadata from the checked-in MushafDatabase SVG
sample pages and validates it against the existing Quran verse/page data.

The repository currently contains only sample pages 1, 2, 3, and 604, so the
validator reports sample-only coverage instead of requiring all 604 pages.

## Generated Output

Generated coordinate sample:

- `assets/mushaf/madani-svg-sample/coordinates.sample.json`

The file is generated from SVG metadata by:

```bash
python3 scripts/import_mushaf_svg_coordinates.py
```

Do not hand-edit the generated coordinate JSON. Update the importer or source
SVG files, then regenerate the JSON.

## Schema Notes

The generated file follows the Phase 2 schema direction from
`docs/mushaf-mode-phase2-scope.md`:

- `schemaVersion`: coordinate schema version.
- `mushaf.id`: app-owned Mushaf identifier.
- `mushaf.source`: source dataset identifier.
- `mushaf.sourceCommit`: source commit used for the sample assets.
- `mushaf.coordinateSpace`: normalized page coordinates.
- `pages[].page`: Madani Mushaf page number.
- `pages[].firstVerseId` / `lastVerseId`: derived from imported SVG items.
- `pages[].items[]`: word and ayah-marker regions.
- `items[].verseId`: existing app format, `surah:ayah`.
- `items[].wordIndex`: 1-based within the verse for word items.
- `items[].bounds`: normalized `{x, y, w, h}` within the rendered page.
- `items[].sourceId`: original SVG group ID for traceability.

## Validation

The importer validates:

- every mapped `verseId` exists in `assets/quran/verses.json`;
- imported first/last verse and unique verse count per imported page match the
  local validated page assignments;
- imported page coverage is reported explicitly.

Current expected output includes:

```text
WARNING: Sample-only coverage: imported 4 of 604 pages (1, 2, 3, 604)
Wrote .../assets/mushaf/madani-svg-sample/coordinates.sample.json with 4 imported pages.
```

That warning is intentional while this repository contains only the four-page
proof-of-concept sample.

## Verification

```bash
python3 scripts/test_import_mushaf_svg_coordinates.py
python3 scripts/import_mushaf_svg_coordinates.py
python3 scripts/verify_madani_page_boundaries.py
flutter analyze
flutter test
git diff --check
```
