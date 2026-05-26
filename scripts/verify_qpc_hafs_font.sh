#!/usr/bin/env bash
set -euo pipefail

font_url="https://static-cdn.tarteel.ai/qul/fonts/UthmanicHafs_V22.ttf"
expected_font_sha256="aa68bffce289b4c0ebac68e90502eb69e42356abcd1603cb2b8e99c2c723f145"
repo_font="assets/fonts/UthmanicHafs_V22.ttf"

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "Neither shasum nor sha256sum is available." >&2
    exit 1
  fi
}

if [[ ! -f "$repo_font" ]]; then
  echo "Repo font not found: $repo_font" >&2
  exit 1
fi

repo_font_sha256="$(sha256_file "$repo_font")"

if [[ "$repo_font_sha256" != "$expected_font_sha256" ]]; then
  echo "Repo font SHA-256 mismatch: $repo_font_sha256" >&2
  exit 1
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

downloaded_font="$work_dir/UthmanicHafs_V22.ttf"
curl --connect-timeout 10 --max-time 120 --retry 3 --retry-delay 2 -fsSL \
  "$font_url" \
  -o "$downloaded_font"

downloaded_font_sha256="$(sha256_file "$downloaded_font")"

if [[ "$downloaded_font_sha256" != "$expected_font_sha256" ]]; then
  echo "Downloaded font SHA-256 mismatch: $downloaded_font_sha256" >&2
  exit 1
fi

if ! cmp -s "$downloaded_font" "$repo_font"; then
  echo "Repo font differs from the pinned QUL/Tarteel CDN font." >&2
  exit 1
fi

echo "Verified $repo_font against the pinned QUL/Tarteel CDN font."
