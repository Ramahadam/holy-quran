#!/usr/bin/env python3
"""Tests for Mushaf SVG coordinate import."""

import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

from import_mushaf_svg_coordinates import (
    import_svg_directory,
    import_svg_page,
    _path_points,
)


def _svg(page: int, body: str) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 200">
  <g id="md-page" data-page-number="{page:03d}">
    {body}
  </g>
</svg>
"""


def _word(
    source_id: str,
    surah: int,
    ayah: int,
    word_index: int,
    path_data: str,
) -> str:
    return f"""
<g id="{source_id}" data-surah="{surah:03d}" data-aya="{ayah:03d}"
   data-line-number="01" data-type="text" data-word-index-in-ayah="{word_index}">
  <path id="{source_id}-path" d="{path_data}"/>
</g>
"""


def _ayah_marker(source_id: str, surah: int, ayah: int, path_data: str) -> str:
    return f"""
<g id="{source_id}" data-surah="{surah:03d}" data-aya="{ayah:03d}"
   data-line-number="01" data-type="aya-mark">
  <path id="{source_id}-path" d="{path_data}"/>
</g>
"""


def _verse(surah: int, ayah: int, page: int) -> dict:
    return {
        "verseId": f"{surah}:{ayah}",
        "surahNumber": surah,
        "verseNumber": ayah,
        "page": page,
    }


class MushafSvgCoordinateImportTest(unittest.TestCase):
    def test_path_points_respect_relative_curves(self):
        points = _path_points("M 10,20 c 1,2 3,4 5,6")

        self.assertIn((10.0, 20.0), points)
        self.assertIn((11.0, 22.0), points)
        self.assertIn((13.0, 24.0), points)
        self.assertIn((15.0, 26.0), points)
        self.assertNotIn((1.0, 2.0), points)

    def test_imports_normalized_word_and_ayah_marker_bounds(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            svg_path = Path(tmp_dir) / "001.svg"
            svg_path.write_text(
                _svg(
                    1,
                    _word("md-word-001", 1, 1, 1, "M 10,20 L 30,40")
                    + _ayah_marker("md-aya-mark-002", 1, 1, "M 40,60 L 50,80"),
                ),
                encoding="utf-8",
            )

            page = import_svg_page(svg_path)

        self.assertEqual(page["page"], 1)
        self.assertEqual(page["firstVerseId"], "1:1")
        self.assertEqual(page["lastVerseId"], "1:1")
        self.assertEqual(page["items"][0]["verseId"], "1:1")
        self.assertEqual(page["items"][0]["wordIndex"], 1)
        self.assertEqual(
            page["items"][0]["bounds"],
            {"x": 0.1, "y": 0.1, "w": 0.2, "h": 0.1},
        )
        self.assertEqual(page["items"][1]["type"], "ayahMarker")

    def test_directory_import_reports_sample_only_coverage_as_warning(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            svg_path = Path(tmp_dir) / "001.svg"
            svg_path.write_text(
                _svg(1, _word("md-word-001", 1, 1, 1, "M 10,20 L 30,40")),
                encoding="utf-8",
            )

            result = import_svg_directory(
                Path(tmp_dir),
                [_verse(1, 1, 1)],
                expected_page_count=604,
            )

        self.assertEqual(result.errors, [])
        self.assertIn("Sample-only coverage", result.warnings[0])
        self.assertEqual(result.document["mushaf"]["importedPageCount"], 1)

    def test_directory_import_detects_unknown_verse_ids(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            svg_path = Path(tmp_dir) / "001.svg"
            svg_path.write_text(
                _svg(1, _word("md-word-001", 9, 9, 1, "M 10,20 L 30,40")),
                encoding="utf-8",
            )

            result = import_svg_directory(
                Path(tmp_dir),
                [_verse(1, 1, 1)],
                expected_page_count=1,
            )

        self.assertIn("001.svg maps unknown verseId 9:9", result.errors)

    def test_directory_import_detects_page_range_drift(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            svg_path = Path(tmp_dir) / "001.svg"
            svg_path.write_text(
                _svg(
                    1,
                    _word("md-word-001", 1, 1, 1, "M 10,20 L 30,40")
                    + _word("md-word-002", 1, 3, 1, "M 30,40 L 50,60"),
                ),
                encoding="utf-8",
            )

            result = import_svg_directory(
                Path(tmp_dir),
                [_verse(1, 1, 1), _verse(1, 2, 1), _verse(1, 3, 1)],
                expected_page_count=1,
            )

        self.assertIn(
            "Page 1 imported range ('1:1', '1:3', 2) differs from "
            "local range ('1:1', '1:3', 3)",
            result.errors,
        )

    def test_directory_import_detects_out_of_page_bounds(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            svg_path = Path(tmp_dir) / "001.svg"
            svg_path.write_text(
                _svg(1, _word("md-word-001", 1, 1, 1, "M 90,190 L 120,210")),
                encoding="utf-8",
            )

            result = import_svg_directory(
                Path(tmp_dir),
                [_verse(1, 1, 1)],
                expected_page_count=1,
            )

        self.assertIn("001.svg md-word-001 has out-of-page bounds", result.errors[0])


if __name__ == "__main__":
    unittest.main()
