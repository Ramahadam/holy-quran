# Backend Configuration Security

The Flutter app accepts only public client configuration. Environment-specific
files are local inputs, not repository artifacts.

## Repository policy

- Commit sanitized `*.example.json` files with placeholders only.
- Keep `config/*.local.json`, `.env`, `.env.local`, `.env.*.local`, `*.pem`, and
  `*.key` files untracked.
- Limit Flutter Dart defines to public values such as
  `CLOUDFLARE_API_BASE_URL` and `APP_VERSION`; Dart defines are recoverable from
  a built client.
- Store Quran Foundation credentials as Cloudflare Worker secrets. Supply any
  deployment credentials through the CI secret store without writing a tracked
  configuration file.
- Inject local configuration with `--dart-define-from-file` and CI public
  configuration with explicit `--dart-define` arguments.

## Repository history audit

On 2026-08-28, all local branch and remote-tracking histories were checked for
environment-specific config paths and common credential patterns. The deleted
`config/supabase.local.example.json` history contained placeholders and a
public app version only; no `config/supabase.local.json` file was committed.
GitHub secret scanning also reported no open alerts.

No credential exposure was found in repository history. On 2026-08-28, the
repository owner accepted the audit assessment and recorded that credential
rotation is not required for issue #113.
