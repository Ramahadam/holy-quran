#!/usr/bin/env python3
"""Import MushafDatabase SVG metadata into normalized coordinate JSON."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

EXPECTED_PAGE_COUNT = 604
DEFAULT_SOURCE_COMMIT = "ebe340a589838c7cf2d79d7a20fc8ec07e4c760c"
DEFAULT_MUSHAF_ID = "madani-hafs-kfgqpc"
DEFAULT_SOURCE_ID = "mushafdatabase-ligature-svg"
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SVG_DIR = PROJECT_ROOT / "assets/mushaf/madani-svg-sample"
DEFAULT_VERSES_PATH = PROJECT_ROOT / "assets/quran/verses.json"
DEFAULT_OUTPUT_PATH = DEFAULT_SVG_DIR / "coordinates.sample.json"
_PATH_TOKEN_RE = re.compile(r"[AaCcHhLlMmQqSsTtVvZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")


@dataclass(frozen=True)
class Bounds:
    x: float
    y: float
    w: float
    h: float

    def normalized(self, view_box: tuple[float, float, float, float]) -> "Bounds":
        view_x, view_y, view_w, view_h = view_box
        return Bounds(
            x=(self.x - view_x) / view_w,
            y=(self.y - view_y) / view_h,
            w=self.w / view_w,
            h=self.h / view_h,
        )

    def as_json(self) -> dict[str, float]:
        return {
            "x": round(self.x, 6),
            "y": round(self.y, 6),
            "w": round(self.w, 6),
            "h": round(self.h, 6),
        }


@dataclass(frozen=True)
class ImportResult:
    document: dict
    errors: list[str]
    warnings: list[str]


def load_verses(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a JSON array")
    return data


def import_svg_directory(
    svg_dir: Path,
    verses: list[dict],
    *,
    expected_page_count: int = EXPECTED_PAGE_COUNT,
    source_commit: str = DEFAULT_SOURCE_COMMIT,
) -> ImportResult:
    svg_paths = sorted(svg_dir.glob("*.svg"))
    errors: list[str] = []
    warnings: list[str] = []
    local_ranges = _page_ranges_from_verses(verses)
    known_verse_ids = {_verse_key(verse) for verse in verses}
    pages = []

    if not svg_paths:
        errors.append(f"No SVG files found in {svg_dir}")

    for svg_path in svg_paths:
        page_doc = import_svg_page(svg_path)
        pages.append(page_doc)
        page = page_doc["page"]
        page_range = _page_range_from_items(page_doc["items"])
        local_range = local_ranges.get(page)

        if local_range is None:
            errors.append(f"Page {page} does not exist in local verse data")
        elif page_range != local_range:
            errors.append(
                f"Page {page} imported range {page_range} differs from "
                f"local range {local_range}"
            )

        for item in page_doc["items"]:
            verse_id = item["verseId"]
            if verse_id not in known_verse_ids:
                errors.append(f"{svg_path.name} maps unknown verseId {verse_id}")
            if not _bounds_are_in_unit_space(item["bounds"]):
                errors.append(
                    f"{svg_path.name} {item['sourceId']} has out-of-page "
                    f"bounds {item['bounds']}"
                )

    imported_pages = [page["page"] for page in pages]
    if len(imported_pages) != expected_page_count:
        warnings.append(
            f"Sample-only coverage: imported {len(imported_pages)} of "
            f"{expected_page_count} pages ({_format_int_list(imported_pages)})"
        )

    document = {
        "schemaVersion": 1,
        "mushaf": {
            "id": DEFAULT_MUSHAF_ID,
            "source": DEFAULT_SOURCE_ID,
            "sourceCommit": source_commit,
            "pageCount": expected_page_count,
            "importedPageCount": len(imported_pages),
            "coordinateSpace": {
                "type": "normalized",
                "width": 1.0,
                "height": 1.0,
            },
        },
        "pages": pages,
    }
    return ImportResult(document=document, errors=errors, warnings=warnings)


def import_svg_page(svg_path: Path) -> dict:
    root = ET.parse(svg_path).getroot()
    view_box = _parse_view_box(root.attrib.get("viewBox"), svg_path)
    page = _page_number(root, svg_path)
    items = []

    for group in root.iter():
        if _local_name(group.tag) != "g":
            continue
        source_id = group.attrib.get("id", "")
        if source_id.startswith("md-word-"):
            items.append(_item_from_group(group, source_id, "word", view_box))
        elif source_id.startswith("md-aya-mark-"):
            items.append(_item_from_group(group, source_id, "ayahMarker", view_box))

    return {
        "page": page,
        "sourceViewBox": " ".join(_format_number(value) for value in view_box),
        "firstVerseId": _page_range_from_items(items)[0],
        "lastVerseId": _page_range_from_items(items)[1],
        "items": items,
    }


def write_json(path: Path, document: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(document, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def _item_from_group(
    group: ET.Element,
    source_id: str,
    item_type: str,
    view_box: tuple[float, float, float, float],
) -> dict:
    verse_id = _verse_id_from_group(group)
    bounds = _bounds_for_group(group).normalized(view_box)
    item = {
        "type": item_type,
        "verseId": verse_id,
        "line": int(group.attrib["data-line-number"]),
        "bounds": bounds.as_json(),
        "sourceId": source_id,
    }
    if item_type == "word":
        item["wordIndex"] = int(group.attrib["data-word-index-in-ayah"])
    return item


def _bounds_for_group(group: ET.Element) -> Bounds:
    points: list[tuple[float, float]] = []
    for child in group.iter():
        if _local_name(child.tag) != "path":
            continue
        path_data = child.attrib.get("d")
        if path_data:
            points.extend(_path_points(path_data))

    if not points:
        source_id = group.attrib.get("id", "<unknown>")
        raise ValueError(f"{source_id} has no path geometry")

    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    min_x = min(xs)
    min_y = min(ys)
    max_x = max(xs)
    max_y = max(ys)
    return Bounds(x=min_x, y=min_y, w=max_x - min_x, h=max_y - min_y)


def _path_points(path_data: str) -> list[tuple[float, float]]:
    tokens = _PATH_TOKEN_RE.findall(path_data)
    points: list[tuple[float, float]] = []
    index = 0
    command = ""
    current = (0.0, 0.0)
    start = (0.0, 0.0)

    def is_command(token: str) -> bool:
        return len(token) == 1 and token.isalpha()

    def has_number() -> bool:
        return index < len(tokens) and not is_command(tokens[index])

    def read_float() -> float:
        nonlocal index
        value = float(tokens[index])
        index += 1
        return value

    def point(x: float, y: float, relative: bool) -> tuple[float, float]:
        if relative:
            return current[0] + x, current[1] + y
        return x, y

    while index < len(tokens):
        if is_command(tokens[index]):
            command = tokens[index]
            index += 1
        if not command:
            raise ValueError(f"Path data starts without a command: {path_data}")

        relative = command.islower()
        op = command.upper()

        if op == "M":
            first = True
            while has_number():
                current = point(read_float(), read_float(), relative)
                points.append(current)
                if first:
                    start = current
                    first = False
                command = "l" if relative else "L"
                op = "L"
        elif op == "L":
            while has_number():
                current = point(read_float(), read_float(), relative)
                points.append(current)
        elif op == "H":
            while has_number():
                x = read_float()
                current = (current[0] + x, current[1]) if relative else (x, current[1])
                points.append(current)
        elif op == "V":
            while has_number():
                y = read_float()
                current = (current[0], current[1] + y) if relative else (current[0], y)
                points.append(current)
        elif op == "C":
            while has_number():
                control_1 = point(read_float(), read_float(), relative)
                control_2 = point(read_float(), read_float(), relative)
                current = point(read_float(), read_float(), relative)
                points.extend([control_1, control_2, current])
        elif op == "S":
            while has_number():
                control = point(read_float(), read_float(), relative)
                current = point(read_float(), read_float(), relative)
                points.extend([control, current])
        elif op == "Q":
            while has_number():
                control = point(read_float(), read_float(), relative)
                current = point(read_float(), read_float(), relative)
                points.extend([control, current])
        elif op == "T":
            while has_number():
                current = point(read_float(), read_float(), relative)
                points.append(current)
        elif op == "A":
            while has_number():
                read_float()
                read_float()
                read_float()
                read_float()
                read_float()
                current = point(read_float(), read_float(), relative)
                points.append(current)
        elif op == "Z":
            current = start
            points.append(current)
            command = ""
        else:
            raise ValueError(f"Unsupported SVG path command: {command}")

    return points


def _parse_view_box(
    view_box: str | None,
    svg_path: Path,
) -> tuple[float, float, float, float]:
    if view_box is None:
        raise ValueError(f"{svg_path} is missing viewBox")
    values = [float(value) for value in view_box.replace(",", " ").split()]
    if len(values) != 4:
        raise ValueError(f"{svg_path} has invalid viewBox: {view_box}")
    if values[2] <= 0 or values[3] <= 0:
        raise ValueError(f"{svg_path} has non-positive viewBox size: {view_box}")
    return values[0], values[1], values[2], values[3]


def _page_number(root: ET.Element, svg_path: Path) -> int:
    filename_page = int(svg_path.stem)
    for group in root.iter():
        page_number = group.attrib.get("data-page-number")
        if page_number is not None:
            root_page = int(page_number)
            if root_page != filename_page:
                raise ValueError(
                    f"{svg_path.name} page {filename_page} differs from "
                    f"data-page-number {root_page}"
                )
            return root_page
    raise ValueError(f"{svg_path} is missing data-page-number")


def _page_range_from_items(items: list[dict]) -> tuple[str, str, int]:
    verse_ids = sorted({item["verseId"] for item in items}, key=_parse_verse_id)
    if not verse_ids:
        raise ValueError("Cannot derive page range from no items")
    return verse_ids[0], verse_ids[-1], len(verse_ids)


def _page_ranges_from_verses(verses: list[dict]) -> dict[int, tuple[str, str, int]]:
    pages: dict[int, list[str]] = {}
    for verse in verses:
        key = _verse_key(verse)
        page = verse.get("page")
        if key is None or not isinstance(page, int):
            continue
        pages.setdefault(page, []).append(key)

    return {
        page: (sorted_keys[0], sorted_keys[-1], len(sorted_keys))
        for page, keys in sorted(pages.items())
        for sorted_keys in [sorted(keys, key=_parse_verse_id)]
    }


def _verse_id_from_group(group: ET.Element) -> str:
    return f"{int(group.attrib['data-surah'])}:{int(group.attrib['data-aya'])}"


def _verse_key(verse: dict) -> str | None:
    verse_id = verse.get("verseId")
    if isinstance(verse_id, str):
        return verse_id
    surah = verse.get("surahNumber")
    ayah = verse.get("verseNumber")
    if isinstance(surah, int) and isinstance(ayah, int):
        return f"{surah}:{ayah}"
    return None


def _parse_verse_id(verse_id: str) -> tuple[int, int]:
    surah, ayah = verse_id.split(":", maxsplit=1)
    return int(surah), int(ayah)


def _bounds_are_in_unit_space(bounds: dict[str, float]) -> bool:
    x = bounds["x"]
    y = bounds["y"]
    w = bounds["w"]
    h = bounds["h"]
    return x >= 0 and y >= 0 and w > 0 and h > 0 and x + w <= 1 and y + h <= 1


def _local_name(tag: str) -> str:
    return tag.rsplit("}", maxsplit=1)[-1]


def _format_number(value: float) -> str:
    return f"{value:.2f}".rstrip("0").rstrip(".")


def _format_int_list(values: list[int]) -> str:
    if len(values) <= 12:
        return ", ".join(str(value) for value in values)
    head = ", ".join(str(value) for value in values[:6])
    tail = ", ".join(str(value) for value in values[-3:])
    return f"{head}, ... {tail}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--svg-dir", type=Path, default=DEFAULT_SVG_DIR)
    parser.add_argument("--verses", type=Path, default=DEFAULT_VERSES_PATH)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT_PATH)
    parser.add_argument("--source-commit", default=DEFAULT_SOURCE_COMMIT)
    args = parser.parse_args(argv)

    verses = load_verses(args.verses)
    result = import_svg_directory(
        args.svg_dir,
        verses,
        source_commit=args.source_commit,
    )

    for warning in result.warnings:
        print(f"WARNING: {warning}")
    if result.errors:
        for error in result.errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    write_json(args.output, result.document)
    print(
        f"Wrote {args.output} with "
        f"{result.document['mushaf']['importedPageCount']} imported pages."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
