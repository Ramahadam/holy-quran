#!/bin/bash
# Setup script to copy and rename Mushaf images after manual download
# Run this after downloading quran_images_1260.zip from GitHub

set -e

echo "================================================"
echo "Mushaf Images Setup Script"
echo "King Fahd Complex - Madani Mushaf"
echo "================================================"
echo ""

# Check if user provided download path
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_extracted_images>"
    echo ""
    echo "Example:"
    echo "  $0 ~/Downloads/quran_images_1260"
    echo ""
    echo "First, download and extract quran_images_1260.zip from:"
    echo "  https://github.com/quran/quran_android/releases"
    echo ""
    exit 1
fi

SOURCE_DIR="$1"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$PROJECT_DIR/assets/mushaf/madani-images"

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Count PNG files in source
PNG_COUNT=$(find "$SOURCE_DIR" -maxdepth 1 -name "*.png" | wc -l)
echo "Found $PNG_COUNT PNG files in $SOURCE_DIR"

if [ "$PNG_COUNT" -eq 0 ]; then
    echo "Error: No PNG files found in source directory"
    echo "Make sure you extracted the zip file and provided the correct path"
    exit 1
fi

echo ""
echo "Copying images to: $DEST_DIR"
echo ""

# Create destination directory
mkdir -p "$DEST_DIR"

# Copy and rename files
COPIED=0
RENAMED=0

for file in "$SOURCE_DIR"/page*.png; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")

        # Extract page number and create zero-padded version
        if [[ $filename =~ page([0-9]+)\.png ]]; then
            page_num="${BASH_REMATCH[1]}"
            new_name=$(printf "%03d.png" "$page_num")

            cp "$file" "$DEST_DIR/$new_name"
            ((COPIED++))
            ((RENAMED++))

            # Show progress every 50 files
            if [ $((RENAMED % 50)) -eq 0 ]; then
                echo "  Copied $RENAMED files..."
            fi
        fi
    fi
done

echo ""
echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo "  Copied: $COPIED images"
echo "  Location: $DEST_DIR"
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

if $ALL_FOUND; then
    echo "🎉 All sample pages verified!"
    echo ""
    echo "Next steps:"
    echo "  1. cd $PROJECT_DIR"
    echo "  2. flutter pub get"
    echo "  3. flutter run"
    echo ""
    echo "You should now see beautiful full-color Mushaf pages!"
else
    echo "⚠️  Some sample pages are missing"
    echo "Check if the source directory contains all files"
fi

echo ""
echo "================================================"
