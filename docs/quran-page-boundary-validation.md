# Madani Mushaf Page-Boundary Validation

This project treats Classic Mode page fidelity as a data-integrity concern:
each verse in `assets/quran/verses.json` must have the correct 1-604 Madani
Mushaf page assignment. Classic Mode does not attempt to reproduce printed line
breaks, visual density, HD page images, or word coordinate mapping; those belong
to Phase 2 Mushaf Mode.

## Source Of Truth

The authoritative comparison source is the Quran.com / Quran Foundation v4 API:

- By-chapter API documentation: https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/verses-by-chapter-number/
- API documentation: https://api-docs.quran.com/docs/content_apis_versioned/4.0.0/verses-by-page-number/
- Page-layout guide: https://api-docs.quran.foundation/docs/tutorials/fonts/page-layout/
- Endpoint used by the online verifier: `https://api.quran.com/api/v4/verses/by_chapter/{chapter}?fields=chapter_id,verse_number,page_number&per_page=50&page={page}`

The docs define `verse_key`, `verse_number`, and `page_number`. The verifier
compares every local verse's page assignment to the API response, then derives
page first verse, last verse, and verse count from those per-verse assignments.
The page-layout guide shows page boundary examples such as page 2 starting at
`2:1` and page 3 starting at `2:6`.

## Verification Commands

Run the fast local structural check:

```bash
python3 scripts/verify_madani_page_boundaries.py
```

Run the authoritative online comparison against Quran.com for all 604 pages:

```bash
python3 scripts/verify_madani_page_boundaries.py --online-quran-com
```

The online check compares every local verse page assignment and each local
page's first verse, last verse, and verse count against the Quran.com response.

## Expected Edge Pages

The current checked-in data validates these edge pages:

- Page 1: `1:1` to `1:7` (7 verses)
- Page 2: `2:1` to `2:5` (5 verses)
- Page 3: `2:6` to `2:16` (11 verses)
- Page 604: `112:1` to `114:6` (15 verses)

## Legacy Note

`scripts/add_page_numbers.py` contains an old hardcoded `PAGE_DATA` table. That
table is not used as the verification source because it currently contains more
than 604 entries. Use `scripts/verify_madani_page_boundaries.py` for validation.
