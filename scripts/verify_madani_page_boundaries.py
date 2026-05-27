#!/usr/bin/env python3
"""Validate Madani Mushaf page-boundary assignments in verses.json.

The offline validator checks the checked-in Quran data for structural page
integrity. The optional online check compares every verse's page assignment
against the public Quran.com v4 API.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import sys
import urllib.request

EXPECTED_PAGE_COUNT = 604
EXPECTED_VERSE_COUNT = 6236
QURAN_COM_API_BASE = "https://api.quran.com/api/v4"
QURAN_COM_BY_CHAPTER_DOC_URL = (
    "https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/"
    "verses-by-chapter-number/"
)
QURAN_COM_BY_PAGE_DOC_URL = (
    "https://api-docs.quran.com/docs/content_apis_versioned/4.0.0/"
    "verses-by-page-number/"
)
QURAN_FOUNDATION_PAGE_LAYOUT_DOC_URL = (
    "https://api-docs.quran.foundation/docs/tutorials/fonts/page-layout/"
)


@dataclass(frozen=True)
class ValidationResult:
    verse_count: int
    page_count: int
    page_ranges: dict[int, tuple[str, str, int]]
    errors: list[str]


def load_verses(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a JSON array")
    return data


def validate_page_boundaries(
    verses: list[dict],
    expected_page_count: int = EXPECTED_PAGE_COUNT,
    expected_verse_count: int = EXPECTED_VERSE_COUNT,
    source_page_ranges: dict[int, tuple[str, str, int]] | None = None,
) -> ValidationResult:
    errors: list[str] = []
    page_ranges = _page_ranges_from_verses(verses)

    if len(verses) != expected_verse_count:
        errors.append(
            f"verses.json has {len(verses)} verses but expected "
            f"{expected_verse_count}"
        )

    used_pages = set(page_ranges)
    expected_pages = set(range(1, expected_page_count + 1))
    missing_pages = sorted(expected_pages - used_pages)
    extra_pages = sorted(used_pages - expected_pages)
    if missing_pages:
        errors.append(f"Missing pages: {_format_int_list(missing_pages)}")
    if extra_pages:
        errors.append(f"Unexpected pages: {_format_int_list(extra_pages)}")

    seen_keys: set[str] = set()
    for index, verse in enumerate(verses, start=1):
        key = _verse_key(verse)
        if key is None:
            errors.append(f"Verse at index {index} has invalid identity fields")
            continue

        if key in seen_keys:
            errors.append(f"Duplicate verse key: {key}")
        seen_keys.add(key)

        actual_page = verse.get("page")
        if not isinstance(actual_page, int):
            errors.append(f"{key} has invalid page value: {actual_page!r}")
            continue

    errors.extend(_validate_monotonic_page_order(verses))

    if source_page_ranges is not None:
        errors.extend(
            compare_page_ranges(page_ranges, source_page_ranges, "source")
        )

    return ValidationResult(
        verse_count=len(verses),
        page_count=len(page_ranges),
        page_ranges=page_ranges,
        errors=errors,
    )


def fetch_quran_com_verse_pages(
    api_base: str = QURAN_COM_API_BASE,
    timeout: int = 20,
) -> dict[str, int]:
    verse_pages: dict[str, int] = {}
    for chapter in range(1, 115):
        print(f"Fetching Quran.com chapter {chapter}/114...", flush=True)
        page = 1
        while True:
            payload = _fetch_quran_com_json(
                (
                    f"{api_base}/verses/by_chapter/{chapter}"
                    "?fields=chapter_id,verse_number,page_number"
                    f"&per_page=50&page={page}"
                ),
                timeout,
            )
            for verse in payload.get("verses", []):
                verse_pages[verse["verse_key"]] = verse["page_number"]

            pagination = payload.get("pagination", {})
            next_page = pagination.get("next_page")
            if next_page is None:
                break
            page = next_page
    return verse_pages


def page_ranges_from_verse_pages(
    verse_pages: dict[str, int],
) -> dict[int, tuple[str, str, int]]:
    pages: dict[int, list[str]] = {}
    for key, page in sorted(verse_pages.items(), key=lambda item: _parse_key(item[0])):
        pages.setdefault(page, []).append(key)
    return {
        page: (keys[0], keys[-1], len(keys))
        for page, keys in sorted(pages.items())
    }


def compare_verse_pages(
    verses: list[dict],
    source_verse_pages: dict[str, int],
    source_name: str,
) -> list[str]:
    errors: list[str] = []
    for verse in verses:
        key = _verse_key(verse)
        if key is None:
            continue
        source_page = source_verse_pages.get(key)
        if source_page is None:
            errors.append(f"{source_name} is missing verse {key}")
            continue
        local_page = verse.get("page")
        if local_page != source_page:
            errors.append(
                f"{key} has page {local_page} but {source_name} has "
                f"page {source_page}"
            )
    return errors


def _fetch_quran_com_json(url: str, timeout: int) -> dict:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "HolyQuranApp/1.0 page-boundary-verifier",
        },
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def compare_page_ranges(
    local_ranges: dict[int, tuple[str, str, int]],
    source_ranges: dict[int, tuple[str, str, int]],
    source_name: str,
) -> list[str]:
    errors: list[str] = []
    all_pages = sorted(set(local_ranges) | set(source_ranges))
    for page in all_pages:
        local_range = local_ranges.get(page)
        source_range = source_ranges.get(page)
        if local_range is None:
            errors.append(f"Local data is missing page {page}")
            continue
        if source_range is None:
            errors.append(f"{source_name} is missing page {page}")
            continue
        if local_range != source_range:
            errors.append(
                f"Page {page} local range {local_range} differs from "
                f"{source_name} range {source_range}"
            )
    return errors


def _page_ranges_from_verses(
    verses: list[dict],
) -> dict[int, tuple[str, str, int]]:
    pages: dict[int, list[str]] = {}
    for verse in verses:
        key = _verse_key(verse)
        page = verse.get("page")
        if key is None or not isinstance(page, int):
            continue
        pages.setdefault(page, []).append(key)

    return {
        page: (keys[0], keys[-1], len(keys))
        for page, keys in sorted(pages.items())
    }


def _validate_monotonic_page_order(verses: list[dict]) -> list[str]:
    errors: list[str] = []
    previous_key: tuple[int, int] | None = None
    previous_page: int | None = None
    for verse in verses:
        key = _verse_key(verse)
        page = verse.get("page")
        if key is None or not isinstance(page, int):
            continue

        surah = verse["surahNumber"]
        ayah = verse["verseNumber"]
        current_key = (surah, ayah)
        if previous_key is not None and current_key <= previous_key:
            errors.append(f"{key} is not ordered after previous verse")
        if previous_page is not None and page < previous_page:
            errors.append(
                f"{key} has page {page} after previous page {previous_page}"
            )
        previous_key = current_key
        previous_page = page
    return errors


def _verse_key(verse: dict) -> str | None:
    surah = verse.get("surahNumber")
    ayah = verse.get("verseNumber")
    verse_id = verse.get("verseId")
    if not isinstance(surah, int) or not isinstance(ayah, int):
        return None
    key = f"{surah}:{ayah}"
    if verse_id != key:
        return None
    return key


def _parse_key(key: str) -> tuple[int, int]:
    surah, ayah = key.split(":", 1)
    return int(surah), int(ayah)


def _format_int_list(values: list[int]) -> str:
    if len(values) <= 12:
        return ", ".join(str(value) for value in values)
    head = ", ".join(str(value) for value in values[:6])
    tail = ", ".join(str(value) for value in values[-3:])
    return f"{head}, ... {tail}"


def _print_summary(result: ValidationResult) -> None:
    print(
        f"Validated {result.verse_count} verses across "
        f"{result.page_count} pages."
    )
    for page in (1, 2, 3, 604):
        page_range = result.page_ranges.get(page)
        if page_range:
            start, end, count = page_range
            print(f"Page {page}: {start} to {end} ({count} verses)")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate Madani Mushaf page boundaries in verses.json."
    )
    parser.add_argument(
        "--verses",
        type=Path,
        default=Path("assets/quran/verses.json"),
        help="Path to verses.json. Defaults to assets/quran/verses.json.",
    )
    parser.add_argument(
        "--online-quran-com",
        action="store_true",
        help="Also compare every verse page against Quran.com API v4 data.",
    )
    args = parser.parse_args(argv)

    verses = load_verses(args.verses)
    result = validate_page_boundaries(verses)

    errors = list(result.errors)
    if args.online_quran_com:
        source_verse_pages = fetch_quran_com_verse_pages()
        source_ranges = page_ranges_from_verse_pages(source_verse_pages)
        errors.extend(
            compare_verse_pages(
                verses,
                source_verse_pages,
                "Quran.com API v4",
            )
        )
        errors.extend(
            compare_page_ranges(
                result.page_ranges,
                source_ranges,
                "Quran.com API v4",
            )
        )

    _print_summary(result)

    if errors:
        print("\nValidation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Madani Mushaf page-boundary validation passed.")
    print(f"Reference docs: {QURAN_COM_BY_CHAPTER_DOC_URL}")
    print(f"By-page docs: {QURAN_COM_BY_PAGE_DOC_URL}")
    print(f"Page-layout guide: {QURAN_FOUNDATION_PAGE_LAYOUT_DOC_URL}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
