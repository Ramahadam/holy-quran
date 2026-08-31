# Domain Docs

How engineering skills should consume this repository's domain documentation.

## Before exploring

- Read `CONTEXT.md` at the repository root.
- Read ADRs under `docs/adr/` that affect the area being changed.
- If either source does not exist or has no relevant entry, proceed silently.

## Layout

This is a single-context repository:

```text
/
├── CONTEXT.md
├── docs/adr/
└── lib/
```

## Consumer rules

- Use the glossary's terms in issue titles, tests, hypotheses, and proposals.
- Do not invent synonyms for concepts already defined in `CONTEXT.md`.
- Surface conflicts with an accepted ADR instead of silently overriding it.
- Record new domain language or durable architectural decisions only when they
  are actually resolved.
