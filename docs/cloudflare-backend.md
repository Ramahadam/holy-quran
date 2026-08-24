# Cloudflare Backend

The mobile app uses one Cloudflare Worker for Quran Foundation tafsir and
anonymous feedback:

- Worker: `holy-quran-api`
- D1 database: `holy-quran-feedback`
- D1 binding: `FEEDBACK_DB`
- Public base URL: `https://holy-quran-api.mohamedadam-tech.workers.dev`

Quran Foundation credentials are encrypted Worker secrets. They must never be
included in Flutter Dart defines, committed files, or client-side code.

## API

- `GET /health`
- `POST /v1/tafsir` with `{"operation":"sources"}`
- `POST /v1/tafsir` with `{"operation":"ayah","verseKey":"1:1","resourceId":169}`
- `POST /v1/feedback` with `feedback_text`, `platform`, and `app_version`

Feedback is anonymous by design. Do not add account identifiers, names, email
addresses, bookmarks, reading history, IP addresses, or last-read position to
the stored payload.

## Abuse protection and caching

The app sends a random 128-bit installation ID in `X-Client-Id`. It is stored
only in local app preferences, is not derived from device hardware or user
data, and is not written to the feedback database. Existing clients without
the header fall back to Cloudflare's connecting IP for rate limiting.

Worker rate limits are:

- Tafsir: 120 requests per installation per 60 seconds.
- Tafsir network ceiling: 1,200 requests per connecting IP per 60 seconds.
- Feedback: 3 submissions per installation per 60 seconds.
- Feedback network ceiling: 30 submissions per connecting IP per 60 seconds.

Exceeded limits return HTTP 429 with `Retry-After: 60`. Cloudflare rate-limit
counters are approximate and local to each Cloudflare location. The looser
network ceilings supplement the installation limits so rotating client IDs
does not bypass Tafsir or feedback protection, while reducing false positives
on shared mobile networks. Network identity is used only as an in-memory rate
limit key and is not written to feedback or application records.

Successful tafsir source and ayah responses are stored for one hour in the
Cloudflare Cache API under deterministic synthetic GET keys. Cache entries are
local to the data center serving the request; a miss calls Quran Foundation and
stores the normalized response for later identical requests in that location.

Browser CORS is closed by default. Native requests do not include an `Origin`
header and continue to work. If a browser client is released, configure exact
comma-separated origins in the non-secret `ALLOWED_ORIGINS` Worker variable,
for example:

```json
{
  "vars": {
    "ALLOWED_ORIGINS": "https://quran.example,https://www.quran.example"
  }
}
```

Wildcard and partial-origin matching are intentionally unsupported.

Implementation references:

- [Cloudflare Workers Rate Limiting](https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/)
- [Cloudflare Workers Cache API](https://developers.cloudflare.com/workers/runtime-apis/cache/)
- [Cloudflare Worker execution context](https://developers.cloudflare.com/workers/runtime-apis/context/)

## Flutter configuration

The production Worker URL is the app default. To override it locally, copy
`config/cloudflare.local.example.json` to the ignored
`config/cloudflare.local.json`, then run:

```bash
flutter run --dart-define-from-file=config/cloudflare.local.json
```

The `.env` helper also forwards only the public Worker URL and app version to
Flutter:

```bash
bash scripts/flutter_run_with_env.sh
```

## Worker development and deployment

```bash
cd cloudflare/worker
npm install
npm test
npm run typecheck
npx wrangler d1 migrations apply holy-quran-feedback --remote
npx wrangler deploy
```

Upload the Quran Foundation production credentials as Worker secrets:

```bash
npx wrangler secret put QF_CLIENT_ID
npx wrangler secret put QF_CLIENT_SECRET
```

Never place secret values in `wrangler.jsonc`.
