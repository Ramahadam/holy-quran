# Mushaf Page Fidelity

Issue #11 tracks the Phase 2 Mushaf Mode requirement to match the physical Madani Mushaf page experience.

## Page Images

- Pages use the King Fahd Glorious Quran Printing Complex Madani Mushaf layout.
- Runtime assets are expected at `assets/mushaf/madani-images/001.png` through `assets/mushaf/madani-images/604.png`.
- Images should be high-resolution PNG files, preferably 1260px or 1920px wide.
- The app references local bundled assets only; it does not download Mushaf pages at runtime.

The recommended source is the Quran Android image release archive, such as `quran_images_1260.zip` or `quran_images_1920.zip`, which contains Madani Mushaf pages derived from the King Fahd Complex layout. Confirm redistribution requirements before shipping a public build and keep attribution in the app credits.

## Coordinate Mapping

Coordinate data is keyed by physical page and stores normalized rectangles in page space:

```json
{
  "page": 1,
  "items": [
    {
      "type": "word",
      "verseId": "1:1",
      "wordIndex": 1,
      "line": 2,
      "sourceId": "page001-word-001",
      "bounds": { "x": 0.562, "y": 0.518, "w": 0.079, "h": 0.024 }
    }
  ]
}
```

`verseId` is the stable app state anchor. Bookmarks and last-read state should never store image coordinates directly.

## Validation

Run this after installing the full page image set:

```bash
dart run scripts/validate_mushaf_assets.dart
```

The validator checks that all 604 PNG page images exist and that coordinate pages stay within the supported page range.
