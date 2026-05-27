#!/usr/bin/env python3
"""Tests for Madani Mushaf page-boundary validation."""

import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

from verify_madani_page_boundaries import (
    compare_page_ranges,
    validate_page_boundaries,
)


def _verse(surah, ayah, page):
    return {
        "verseId": f"{surah}:{ayah}",
        "surahNumber": surah,
        "verseNumber": ayah,
        "page": page,
    }


class MadaniPageBoundaryValidationTest(unittest.TestCase):
    def test_accepts_a_valid_small_boundary_set(self):
        verses = [
            _verse(1, 1, 1),
            _verse(1, 2, 1),
            _verse(2, 1, 2),
            _verse(2, 2, 2),
        ]

        result = validate_page_boundaries(
            verses,
            expected_page_count=2,
            expected_verse_count=4,
        )

        self.assertEqual(result.errors, [])
        self.assertEqual(result.page_count, 2)
        self.assertEqual(result.verse_count, 4)
        self.assertEqual(result.page_ranges[1], ("1:1", "1:2", 2))
        self.assertEqual(result.page_ranges[2], ("2:1", "2:2", 2))

    def test_reports_page_assignment_drift(self):
        verses = [
            _verse(1, 1, 1),
            _verse(1, 2, 2),
            _verse(2, 1, 2),
            _verse(2, 2, 2),
        ]

        result = validate_page_boundaries(
            verses,
            expected_page_count=2,
            expected_verse_count=4,
            source_page_ranges={
                1: ("1:1", "1:2", 2),
                2: ("2:1", "2:2", 2),
            },
        )

        self.assertIn(
            "Page 1 local range ('1:1', '1:1', 1) differs from "
            "source range ('1:1', '1:2', 2)",
            result.errors,
        )

    def test_reports_missing_page_start(self):
        verses = [
            _verse(1, 1, 1),
            _verse(1, 2, 1),
            _verse(2, 2, 2),
        ]

        result = validate_page_boundaries(
            verses,
            expected_page_count=2,
            expected_verse_count=3,
            source_page_ranges={
                1: ("1:1", "1:2", 2),
                2: ("2:1", "2:2", 2),
            },
        )

        self.assertIn(
            "Page 2 local range ('2:2', '2:2', 1) differs from "
            "source range ('2:1', '2:2', 2)",
            result.errors,
        )

    def test_compare_page_ranges_covers_real_edge_pages(self):
        local_ranges = {
            1: ("1:1", "1:7", 7),
            2: ("2:1", "2:5", 5),
            3: ("2:6", "2:16", 11),
            604: ("112:1", "114:6", 15),
        }
        source_ranges = dict(local_ranges)

        self.assertEqual(
            compare_page_ranges(local_ranges, source_ranges, "source"),
            [],
        )


if __name__ == "__main__":
    unittest.main()
