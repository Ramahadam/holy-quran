# Quran Foundation API integration

Quran Foundation recommends choosing the integration path that matches the
application shape:

- Use the [starter app](https://api-docs.quran.foundation/docs/tutorials/oidc/starter-with-npx/)
  for a new JavaScript or TypeScript web application that needs authentication,
  session handling, and Quran features already wired together.
- Use the [JavaScript SDK](https://api-docs.quran.foundation/docs/sdk/javascript/)
  when integrating an existing JavaScript or TypeScript backend. Server-side
  Content and Search calls use `@quranjs/api/server`; browser- or mobile-safe
  OAuth helpers use `@quranjs/api/public`.
- Use the
  [manual API flow](https://api-docs.quran.foundation/docs/quickstart/manual-authentication/)
  when the SDK does not fit the runtime or the integration needs direct control
  over OAuth and API requests.

## Holy Quran app boundary

This Flutter app must not contain the Quran Foundation client secret. The
Cloudflare Worker is the backend boundary for Quran Foundation requests and
stores `QF_CLIENT_ID` and `QF_CLIENT_SECRET` as Worker secrets. The mobile app
calls the Worker and receives only the response data it needs.

Do not place Quran Foundation credentials in Dart defines, local Flutter
configuration, source files, or committed documentation. See
`docs/backend-configuration-security.md` and `docs/cloudflare-backend.md` for
the repository policy and deployment commands.

## Environment endpoints

Credentials and tokens are environment-specific. Keep pre-live credentials
with pre-live endpoints and production credentials with production endpoints.

| Environment | OAuth base URL | API base URL |
| --- | --- | --- |
| Pre-live | `https://prelive-oauth2.quran.foundation` | `https://apis-prelive.quran.foundation` |
| Production | `https://oauth2.quran.foundation` | `https://apis.quran.foundation` |

No credential values belong in this file.
