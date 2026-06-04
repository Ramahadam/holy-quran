#!/bin/bash
# Script to download sample Mushaf images from trusted sources
# King Fahd Glorious Quran Printing Complex (Madani Mushaf)

set -e

IMAGES_DIR="assets/mushaf/madani-images"
mkdir -p "$IMAGES_DIR"

echo "Downloading sample Mushaf page images..."
echo "Source: Quran.com (King Fahd Complex Madani Mushaf)"
echo ""

# Array of page numbers to download
PAGES=(1 2 3 604)

# Try multiple CDN sources
download_image() {
    local page=$1
    local padded_page=$(printf "%03d" $page)
    local output_file="$IMAGES_DIR/$padded_page.png"

    if [ -f "$output_file" ]; then
        echo "✓ Page $page already exists"
        return 0
    fi

    echo "Downloading page $page..."

    # List of CDN URLs to try (in order of preference)
    URLS=(
        "https://equran.oss-accelerate.aliyuncs.com/madani/images_1920/page$padded_page.png"
        "https://raw.githubusercontent.com/quran/quran-images/master/1920/$padded_page.png"
        "https://mushaf.s3.amazonaws.com/madani/$padded_page.png"
    )

    for url in "${URLS[@]}"; do
        if curl -f -s -L -o "$output_file" "$url" 2>/dev/null; then
            if file "$output_file" | grep -q "PNG image"; then
                echo "✓ Downloaded page $page successfully"
                return 0
            else
                rm -f "$output_file"
            fi
        fi
    done

    echo "✗ Failed to download page $page from all sources"
    return 1
}

# Download each page
SUCCESS_COUNT=0
for page in "${PAGES[@]}"; do
    if download_image "$page"; then
        ((SUCCESS_COUNT++))
    fi
done

echo ""
echo "Downloaded $SUCCESS_COUNT/${#PAGES[@]} pages"
echo ""
echo "NOTE: If downloads failed, please manually download images from:"
echo "1. https://github.com/quran/quran_android/releases"
echo "2. Extract the image database and copy pages to: $IMAGES_DIR"
echo ""
echo "See docs/mushaf-images-guide.md for detailed instructions"
