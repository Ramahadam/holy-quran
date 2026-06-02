#!/usr/bin/env bash
set -euo pipefail

env_file=".env"
if [[ ! -f "$env_file" ]]; then
  echo "Missing $env_file. Create it with PROJECT_URL and PUBLISHABLE_KEY." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

supabase_url="${SUPABASE_URL:-${PROJECT_URL:-}}"
supabase_key="${SUPABASE_PUBLISHABLE_KEY:-${PUBLISHABLE_KEY:-}}"
app_version="${APP_VERSION:-unknown}"

if [[ -z "$supabase_url" || -z "$supabase_key" ]]; then
  echo "Missing Supabase config. Set PROJECT_URL and PUBLISHABLE_KEY in .env." >&2
  exit 1
fi

define_file="$(mktemp)"
chmod 600 "$define_file"
cleanup() {
  rm -f "$define_file"
}
trap cleanup EXIT INT TERM

{
  printf 'SUPABASE_URL=%s\n' "$supabase_url"
  printf 'SUPABASE_PUBLISHABLE_KEY=%s\n' "$supabase_key"
  printf 'APP_VERSION=%s\n' "$app_version"
} > "$define_file"

flutter run --dart-define-from-file="$define_file" "$@"
