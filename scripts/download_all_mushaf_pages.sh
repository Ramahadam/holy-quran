#!/bin/bash
# Download all 604 Mushaf pages from official Quran.app CDN
# Source: https://files.quran.app (King Fahd Complex Madani Mushaf)

set -e

DEST_DIR="$(cd "$(dirname "$0")/.." && pwd)/assets/mushaf/madani-images"
BASE_URL="https://files.quran.app/hafs/madani/width_1260"

echo "================================================"
echo "Downloading All 604 Mushaf Pages"
echo "Source: King Fahd Complex (via Quran.app)"
echo "================================================"
echo ""

mkdir -p "$DEST_DIR"

DOWNLOADED=0
FAILED=0
SKIPPED=0

for page in {1..604}; do
    PADDED=$(printf "%03d" $page)
    OUTPUT="$DEST_DIR/$PADDED.png"

    # Skip if already exists
    if [ -f "$OUTPUT" ]; then
        ((SKIPPED++))
        if [ $((page % 50)) -eq 0 ]; then
            echo "Progress: $page/604 pages ($SKIPPED skipped, $DOWNLOADED downloaded)"
        fi
        continue
    fi

    # Download
    if curl -f -s -L -o "$OUTPUT" "$BASE_URL/page$PADDED.png" 2>/dev/null; then
        ((DOWNLOADED++))
    else
        echo "✗ Failed to download page $page"
        ((FAILED++))
    fi

    # Show progress every 50 pages
    if [ $((page % 50)) -eq 0 ]; then
        echo "Progress: $page/604 pages ($DOWNLOADED downloaded, $SKIPPED skipped)"
    fi
done

echo ""
echo "================================================"
echo "✅ Download Complete!"
echo "================================================"
echo "  Downloaded: $DOWNLOADED pages"
echo "  Skipped (already exist): $SKIPPED pages"
echo "  Failed: $FAILED pages"
echo "  Total: 604 pages"
echo ""
echo "Location: $DEST_DIR"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All pages downloaded successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. flutter pub get"
    echo "  2. flutter run"
    echo ""
    echo "Enjoy beautiful full-color Mushaf pages!"
else
    echo "⚠️  Some pages failed to download"
    echo "You can re-run this script to retry failed downloads"
fi

echo ""
echo "================================================"
