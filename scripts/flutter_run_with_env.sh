#!/usr/bin/env bash
set -euo pipefail

env_file=".env"
if [[ ! -f "$env_file" ]]; then
  echo "Missing $env_file. Create it with CLOUDFLARE_API_BASE_URL." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

cloudflare_api_base_url="${CLOUDFLARE_API_BASE_URL:-https://holy-quran-api.mohamedadam-tech.workers.dev}"
app_version="${APP_VERSION:-unknown}"

if [[ -z "$cloudflare_api_base_url" ]]; then
  echo "Missing Cloudflare config. Set CLOUDFLARE_API_BASE_URL in .env." >&2
  exit 1
fi

define_file="$(mktemp)"
chmod 600 "$define_file"
cleanup() {
  rm -f "$define_file"
}
trap cleanup EXIT INT TERM

{
  printf 'CLOUDFLARE_API_BASE_URL=%s\n' "$cloudflare_api_base_url"
  printf 'APP_VERSION=%s\n' "$app_version"
} > "$define_file"

flutter run --dart-define-from-file="$define_file" "$@"
