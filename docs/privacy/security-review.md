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
- Updated developer/contact information in both policy languages. Retention and
  owner approval remain pending; this is still a draft and has not been deployed.

## Open findings

1. **P2 — Development dependency advisories.** `npm audit --json` reports seven
   advisories (five high, two moderate) across Vitest/mocker, Wrangler/Miniflare,
   sharp, and undici. These packages are development dependencies, not deployed
   Worker application imports. Local development/test tooling remains exposed to
   the applicable advisory conditions. Update the affected tooling and rerun
   tests, type checking, and a Wrangler bundle dry run before the next deployment.
   This PR does not update dependencies. Tracked in
   [#168](https://github.com/Ramahadam/holy-quran/issues/168), assigned to the
   repository owner. Review by 2026-10-18.
2. **P2 — Request size is checked after buffering.** `readJsonObject` checks a
   supplied Content-Length but then calls `request.text()` before its final size
   check. A body without that header can consume memory before rejection, and
   string length counts UTF-16 code units rather than received bytes. A separate
   fix should cap streamed bytes and cancel oversized bodies, with tests for
   missing headers, multibyte text, and bodies exceeding the limit. This behavior
   predates the privacy change. Tracked in
   [#167](https://github.com/Ramahadam/holy-quran/issues/167), assigned to the
   repository owner. Review by 2026-10-18.

Cloudflare account MFA, deployed secret/API-token scopes, database permissions,
and platform log/backup retention were not verified. Source configuration alone
does not establish those account settings. Verify them before production release.
