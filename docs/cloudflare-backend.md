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
