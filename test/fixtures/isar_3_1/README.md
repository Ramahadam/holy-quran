`legacy.isar.gz` is a gzip-compressed database created with the original
`isar` and `isar_flutter_libs` **3.1.0+1** on macOS. It contains synthetic data
only. The schema source and generated code came from commit `4b2dde0`:

- `BookmarkEntity`: verse `2:255`, surah 2, timestamp `2026-01-01T00:00:00Z`,
  note `Legacy bookmark`.
- `ReadingPositionEntity`: id 1, verse `18:10`, last read
  `2026-01-02T00:00:00Z`.

The database was opened as `legacy` with these two schemas, populated in one
write transaction, closed, and compressed with Python `gzip.compress`.
The integration test copies and decompresses it into a temporary directory,
opens it with the new runtime and the full application schema list, verifies
both records, and writes a new reading position. Never regenerate this fixture
using the new runtime: that would stop testing the dependency upgrade.
