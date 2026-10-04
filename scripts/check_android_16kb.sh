#!/usr/bin/env bash
# Validate an already-built release bundle and every generated split APK.
set -euo pipefail
bundle=${1:?Usage: check_android_16kb.sh release.aab}
: "${BUNDLETOOL_JAR:?Set BUNDLETOOL_JAR to the bundletool jar}"
: "${ZIPALIGN:?Set ZIPALIGN to Android build-tools 35+ zipalign}"
root=$(cd "$(dirname "$0")/.." && pwd)
python3 "$root/scripts/check_android_page_alignment.py" "$bundle"
config=$(java -jar "$BUNDLETOOL_JAR" dump config --bundle="$bundle")
if ! [[ "$config" == *PAGE_ALIGNMENT_16K* ]]; then
  echo 'FAIL: bundle does not request PAGE_ALIGNMENT_16K' >&2
  exit 1
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
# bundletool signs these inspection APKs with the local debug key by default.
java -jar "$BUNDLETOOL_JAR" build-apks --bundle="$bundle" --output="$work/release.apks"
unzip -q "$work/release.apks" -d "$work/apks"
count=0
while IFS= read -r -d '' apk; do
  "$ZIPALIGN" -c -P 16 4 "$apk"
  count=$((count + 1))
done < <(find "$work/apks" -name '*.apk' -print0)
if (( count == 0 )); then
  echo 'FAIL: bundletool generated no APKs' >&2
  exit 1
fi
echo "PASS: PAGE_ALIGNMENT_16K and zip alignment for $count generated APKs"
