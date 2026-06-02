# Anonymous Supabase Feedback

The feedback pipeline is anonymous by design. The app submits only:

- `feedback_text`
- `platform`
- `app_version`

Do not add account identifiers, names, emails, bookmarks, reading history, or
last-read position to this payload.

## Build Configuration

For local development, keep `.env` ignored by git and run:

```bash
bash scripts/flutter_run_with_env.sh
```

The script reads `.env` and forwards only the public values the Flutter app
needs. It accepts either naming style:

```text
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-public-key
APP_VERSION=1.0.0+1
```

or:

```text
PROJECT_URL=https://your-project.supabase.co
PUBLISHABLE_KEY=your-public-key
APP_VERSION=1.0.0+1
```

Do not pass the whole `.env` file with `--dart-define-from-file` if it contains
database passwords, service-role keys, or other private values.

For CI or release builds, provide Supabase values at build time with Dart
defines:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-public-anon-key \
  --dart-define=APP_VERSION=1.0.0+1
```

`SUPABASE_ANON_KEY` is also accepted for older environment naming. Do not commit
real keys to the repository.

If the Supabase values are omitted, the app still runs and feedback submissions
show a friendly failure message.

## Table Shape

Create an `anonymous_feedback` table with columns matching the payload:

```sql
create table anonymous_feedback (
  id uuid primary key default gen_random_uuid(),
  feedback_text text not null check (char_length(feedback_text) <= 2000),
  platform text not null,
  app_version text not null,
  created_at timestamptz not null default now()
);
```
