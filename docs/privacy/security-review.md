# Privacy disclosure security review — #149

Reviewed 2026-10-11 using security-and-hardening. This is a source and local-test
review, not an audit of the live Cloudflare account or a penetration test.

## Public policy

Developer: Mohamed Adam. Privacy contact: mohamedadam.tech@gmail.com.

Naming Cloudflare and Quran Foundation explains who handles data. Provider names
and architecture terms do not grant access to feedback or credentials. Keep the
provider disclosures, but use plain language: the public policy now says
Cloudflare-hosted service and Cloudflare storage rather than Worker and D1.
No database IDs, secret values, administrative URLs, or credential instructions
are added to the policy. D1 API access requires authorization; see
[Cloudflare D1 API](https://developers.cloudflare.com/api/resources/d1/subresources/database/methods/query/).

The reviewed source keeps provider credentials in Worker environment secrets,
uses parameterized feedback inserts, and exposes no feedback-reading endpoint.
The policy HTML escapes text and runs without JavaScript or cookies. Existing
CORS controls restrict browser response access; they are not API authentication.
The anonymous API also has existing rate controls.

## Changes and validation

- Added HSTS, frame denial, MIME sniffing protection, and a restrictive fallback
  CSP to normal, error, and preflight responses. The policy's existing CSP is
  preserved so its inline stylesheet continues to work.
- Five new tests failed before the header fix. All 25 Worker tests and TypeScript
  checking pass after it.
- Updated developer/contact information in both policy languages. The owner subsequently approved 90-day retention;
  final policy publication and contact monitoring are now owner-approved.
  Production deployment verification remains pending.

## Findings and remediation

1. **Resolved — Development dependency advisories (#168).** The initial `npm audit --json` reported seven
   advisories (five high, two moderate) across Vitest/mocker, Wrangler/Miniflare,
   sharp, and undici. These packages are development dependencies, not deployed
   Worker application imports. The original privacy PR deferred the tooling
   update. The pre-deployment update below resolves these advisories. Tracked in
   [#168](https://github.com/Ramahadam/holy-quran/issues/168), assigned to the
   repository owner. Review by 2026-10-18.
2. **Resolved — Request size is checked after buffering (#167).** `readJsonObject` checks a
   supplied Content-Length but then calls `request.text()` before its final size
   check. A body without that header can consume memory before rejection, and
   string length counts UTF-16 code units rather than received bytes. The pre-deployment fix below caps streamed bytes and cancels oversized
   bodies, with tests for missing headers, multibyte text, and limit boundaries. This behavior
   predates the privacy change. Tracked in
   [#167](https://github.com/Ramahadam/holy-quran/issues/167), assigned to the
   repository owner. Review by 2026-10-18.

Cloudflare account MFA, deployed secret/API-token scopes, database permissions,
and platform log/backup retention were not verified. Source configuration alone
does not establish those account settings. Verify them before production release.

## Pre-deployment remediation — 2026-10-11

Updated Vitest within 4.x to the patched 4.1.11 release and Wrangler to 4.149.0.
A clean `npm ci` succeeds and `npm audit` reports zero advisories.
The [Vitest advisory](https://github.com/advisories/GHSA-82fw-gwwq-j7x9)
identifies 4.1.11 as patched.

`readJsonObject` now enforces received byte limits while reading the stream and
cancels it before decoding an oversized chunk. Tests reproduce the old failure
and cover absent Content-Length, oversized multibyte text, early cancellation,
the exact byte boundary, and multibyte characters split across chunks.
The policy approval and email monitoring confirmation are recorded in the owner
conversation; release verification and Console submission remain outstanding.
