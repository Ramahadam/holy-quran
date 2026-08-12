#!/usr/bin/env python3
"""Fail when critical persistence coverage drops below the approved baseline."""

from pathlib import Path
import sys


MINIMUM_LINE_COVERAGE = {
    "lib/data/repositories/quran_repository_impl.dart": 95,
    "lib/data/repositories/bookmark_repository_impl.dart": 80,
    "lib/data/repositories/reading_position_repository_impl.dart": 95,
    "lib/data/backup/quran_backup_service.dart": 80,
}


def coverage_by_file(lcov_path: Path) -> dict[str, tuple[int, int]]:
    coverage = {}
    source_file = None
    lines_found = 0
    lines_hit = 0

    for line in lcov_path.read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            source_file = line.removeprefix("SF:")
            lines_found = 0
            lines_hit = 0
        elif line.startswith("DA:"):
            _, hits = line.removeprefix("DA:").split(",", maxsplit=1)
            lines_found += 1
            lines_hit += int(hits) > 0
        elif line == "end_of_record" and source_file is not None:
            coverage[source_file] = (lines_hit, lines_found)
            source_file = None

    return coverage


def main() -> int:
    lcov_path = Path("coverage/lcov.info")
    if not lcov_path.is_file():
        print("Missing coverage/lcov.info. Run `flutter test --coverage` first.")
        return 1

    coverage = coverage_by_file(lcov_path)
    failures = []
    for source_file, minimum in MINIMUM_LINE_COVERAGE.items():
        hits, lines = coverage.get(source_file, (0, 0))
        percentage = 100 * hits / lines if lines else 0
        print(f"{source_file}: {hits}/{lines} lines ({percentage:.1f}%)")
        if percentage < minimum:
            failures.append(
                f"{source_file} coverage {percentage:.1f}% is below {minimum}%"
            )

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
