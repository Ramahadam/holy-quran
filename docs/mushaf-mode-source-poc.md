# Mushaf Mode Source Proof Of Concept

Date: 2026-05-28
Issue: https://github.com/Ramahadam/holy-quran/issues/19
Parent: https://github.com/Ramahadam/holy-quran/issues/11

## Scope

This proof of concept vendors only four sample pages from the selected Mushaf
source:

- `assets/mushaf/madani-svg-sample/001.svg`
- `assets/mushaf/madani-svg-sample/002.svg`
- `assets/mushaf/madani-svg-sample/003.svg`
- `assets/mushaf/madani-svg-sample/604.svg`

The app can render these sample pages locally with `flutter_svg`. It does not
commit the full 604-page dataset, coordinate JSON, or generated raster assets.

## Source

Source repository:

- https://github.com/mushafdatabase/MushafDatabase-Ligature-Based-SVG

Source commit used for this sample:

```text
ebe340a589838c7cf2d79d7a20fc8ec07e4c760c
```

Source paths:

- `SVG V1.0/001.svg`
- `SVG V1.0/002.svg`
- `SVG V1.0/003.svg`
- `SVG V1.0/604.svg`

The source README describes the dataset as 604 SVG files, one file per printed
Madinah Mushaf page. It also documents the common root viewport as
`viewBox="0 0 382.68 547.09"` with `preserveAspectRatio="xMidYMid meet"`.

## License And Provenance

The source license grants permission to use, copy, modify, publish, distribute,
and create derivative works from the dataset for lawful personal, educational,
research, nonprofit, and commercial use. It also requires users not to knowingly
alter Quranic content in a way that misrepresents or compromises the integrity
of the Holy Quran.

The source README says the visual artwork is derived from the Madinah Mushaf
issued by the King Fahd Glorious Quran Printing Complex and the digital Mushaf
materials published through the Quran Complex portal.

King Fahd Complex source:

- https://dm.qurancomplex.gov.sa/

## Size Measurement

Measured sample size:

| Page | Raw SVG bytes |
| --- | ---: |
| 001 | 202,858 |
| 002 | 254,126 |
| 003 | 623,983 |
| 604 | 399,319 |
| Total sample | 1,480,286 |

Filesystem size for the four checked-in SVG files is approximately 1.4 MB.
The same four files gzip to 304,723 bytes.

GitHub content metadata for all 604 source SVG files at the sampled commit
reports 396,725,315 raw bytes, or about 378.35 MiB before app-store, APK/AAB,
or IPA compression. Source SVG sizes range from 202,858 to 859,843 bytes, with
an average of about 656,830 bytes per page.

The full-dataset decision still needs a compressed raster comparison and an
on-device memory/rendering check before choosing SVG-native bundling.

## Rendering

The sample renderer lives in:

- `lib/presentation/widgets/mushaf_sample_page.dart`

The current reading screen exposes a temporary app-bar toggle that switches the
visible page between Classic Mode and the local Mushaf sample renderer. Only
pages 1, 2, 3, and 604 render as SVG samples; other pages show a sample-scope
message.

This proof of concept intentionally does not introduce the final reading-mode
model. That belongs to the later Mushaf Mode page-renderer issue.

## Verification

```bash
flutter analyze
flutter test
git diff --check
```
