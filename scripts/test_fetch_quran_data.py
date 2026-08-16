#!/usr/bin/env python3
"""Tests for Quran Foundation text import cleanup."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fetch_quran_data import strip_qpc_hafs_ayah_number


class FetchQuranDataTest(unittest.TestCase):
    def test_strips_only_the_trailing_qpc_hafs_ayah_number(self):
        text = "وَبِٱلۡأٓخِرَةِ هُمۡ يُوقِنُونَ\u00a0٤"

        self.assertEqual(
            strip_qpc_hafs_ayah_number(text),
            "وَبِٱلۡأٓخِرَةِ هُمۡ يُوقِنُونَ",
        )

    def test_preserves_qpc_hafs_marks_when_no_ayah_number_is_present(self):
        text = "ٱلۡكِتَٰبُ ظُلُمَٰتٖ"

        self.assertEqual(strip_qpc_hafs_ayah_number(text), text)


if __name__ == "__main__":
    unittest.main()
