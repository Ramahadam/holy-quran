#!/bin/bash
# Extract Mushaf images from Quran Android app on emulator

set -e

ADB="$HOME/Library/Android/sdk/platform-tools/adb"
TEMP_DIR="$HOME/mushaf_images_temp"
DEST_DIR="$(cd "$(dirname "$0")/.." && pwd)/assets/mushaf/madani-images"

echo "================================================"
echo "Extracting Mushaf Images from Quran Android App"
echo "================================================"
echo ""

# Check if adb is available
if [ ! -f "$ADB" ]; then
    echo "Error: adb not found at $ADB"
    echo "Please update ADB path in this script"
    exit 1
fi

# Check if device is connected
echo "Checking emulator connection..."
DEVICE=$($ADB devices | grep "emulator\|device" | grep -v "List of devices" | head -1 | awk '{print $1}')

if [ -z "$DEVICE" ]; then
    echo "Error: No emulator or device connected"
    echo "Please start your Android emulator first"
    exit 1
fi

echo "✓ Connected to: $DEVICE"
echo ""

# Check if images exist on device
echo "Checking for images on device..."
IMAGE_COUNT=$($ADB shell ls /sdcard/Android/data/com.quran.labs.androidquran/files/ 2>/dev/null | grep -c "\.png" || echo "0")

if [ "$IMAGE_COUNT" -eq "0" ]; then
    echo ""
    echo "⚠️  No images found on device!"
    echo ""
    echo "Please:"
    echo "1. Open the Quran app on your emulator"
    echo "2. Let it download the Mushaf images"
    echo "3. Wait for download to complete"
    echo "4. Run this script again"
    echo ""
    exit 1
fi

echo "✓ Found images on device"
echo ""

# Create temp directory
echo "Creating temporary directory..."
mkdir -p "$TEMP_DIR"
echo "✓ Created: $TEMP_DIR"
echo ""

# Pull images from device
echo "Pulling images from device (this may take a minute)..."
$ADB pull /sdcard/Android/data/com.quran.labs.androidquran/files/ "$TEMP_DIR/" 2>&1 | grep -v "^$"

echo ""
echo "✓ Images pulled to temp directory"
echo ""

# Count pulled images
PULLED_COUNT=$(find "$TEMP_DIR" -name "*.png" | wc -l | tr -d ' ')
echo "Found $PULLED_COUNT PNG files"
echo ""

# Create destination directory
mkdir -p "$DEST_DIR"

# Copy and rename images
echo "Copying images to project..."
COPIED=0

for file in "$TEMP_DIR"/*.png; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")

        # Check if filename matches pageXXX.png or XXX.png pattern
        if [[ $filename =~ page([0-9]+)\.png ]]; then
            page_num="${BASH_REMATCH[1]}"
            new_name=$(printf "%03d.png" "$page_num")
            cp "$file" "$DEST_DIR/$new_name"
            ((COPIED++))
        elif [[ $filename =~ ^([0-9]+)\.png$ ]]; then
            page_num="${BASH_REMATCH[1]}"
            new_name=$(printf "%03d.png" "$page_num")
            cp "$file" "$DEST_DIR/$new_name"
            ((COPIED++))
        fi

        # Show progress
        if [ $((COPIED % 50)) -eq 0 ] && [ $COPIED -gt 0 ]; then
            echo "  Copied $COPIED files..."
        fi
    fi
done

echo ""
echo "================================================"
echo "✅ SUCCESS!"
echo "================================================"
echo "  Copied: $COPIED images"
echo "  To: $DEST_DIR"
echo ""

# Verify sample pages
echo "Verifying sample pages..."
SAMPLE_PAGES=(001 002 003 604)
ALL_FOUND=true

for page in "${SAMPLE_PAGES[@]}"; do
    if [ -f "$DEST_DIR/$page.png" ]; then
        SIZE=$(du -h "$DEST_DIR/$page.png" | cut -f1)
        echo "  ✓ Page $page ($SIZE)"
    else
        echo "  ✗ Page $page - NOT FOUND"
        ALL_FOUND=false
    fi
done

echo ""

# Cleanup temp directory
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"
echo "✓ Cleanup complete"
echo ""

if $ALL_FOUND; then
    echo "🎉 All sample pages verified!"
    echo ""
    echo "Next steps:"
    echo "  1. cd $(dirname "$0")/.."
    echo "  2. flutter pub get"
    echo "  3. flutter run"
    echo ""
    echo "You should now see beautiful full-color Mushaf pages!"
else
    echo "⚠️  Some sample pages are missing"
    echo "But you can still test with the pages that were copied."
fi

echo ""
echo "================================================"
