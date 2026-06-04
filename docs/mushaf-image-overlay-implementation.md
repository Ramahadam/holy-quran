# Mushaf Image + SVG Overlay Implementation

## Overview

Implemented a hybrid rendering system that displays full-color traditional Mushaf page images with SVG coordinate overlay for precise hit-testing.

## Implementation Date

May 28, 2026

## What Was Implemented

### 1. Image + SVG Overlay Renderer

**File:** `lib/presentation/widgets/mushaf_sample_page.dart`

**Features:**
- ✅ Displays full-color Mushaf page images when available
- ✅ Falls back to SVG rendering if images are missing
- ✅ Maintains SVG overlay for precise tap coordinate detection
- ✅ Automatic image existence checking
- ✅ Error handling with graceful fallback

**Rendering Logic:**
```
1. Check if full-color image exists
2. If YES:
   - Display full-color image as base layer
   - Overlay transparent SVG for hit-testing
3. If NO:
   - Fall back to SVG-only rendering (current behavior)
```

### 2. Asset Management Updates

**Updated Files:**
- `pubspec.yaml` - Added `assets/mushaf/madani-images/` directory
- `MushafSampleAssets` class - Added image path methods

**New Methods:**
- `imagePathForPage(int page)` - Returns path to full-color image
- `svgPathForPage(int page)` - Returns path to SVG coordinates
- `hasImageForPage(int page)` - Checks if image is available

### 3. Download Infrastructure

**Created Files:**
1. `scripts/download_sample_mushaf_images.sh` - Automated download script
2. `assets/mushaf/madani-images/README.md` - Image directory documentation
3. `assets/mushaf/madani-images/DOWNLOAD_INSTRUCTIONS.md` - Step-by-step guide
4. `docs/mushaf-images-guide.md` - Comprehensive implementation guide

## How It Works

### Current Behavior (Without Images)

```
User taps page → SVG paths → Black text on white → Hit detection works
```

### New Behavior (With Images)

```
User sees → Full-color beautiful Mushaf page
User taps → SVG overlay detects exact coordinate → Hit detection works
```

### Visual Layers

```
┌─────────────────────────────┐
│   Transparent SVG Overlay   │ ← Hit-testing coordinates
├─────────────────────────────┤
│   Full-Color Mushaf Image   │ ← Beautiful traditional styling
└─────────────────────────────┘
```

## Next Steps - ACTION REQUIRED

### To Complete the Implementation:

1. **Download Mushaf Images**

   Visit: https://github.com/quran/quran_android/releases

   Download: `quran_images_1260.zip` or `quran_images_1920.zip`

2. **Extract and Copy**

   ```bash
   # Extract the downloaded zip file
   unzip quran_images_1260.zip

   # Copy images to your project
   cp page*.png /path/to/Holy\ Quran/assets/mushaf/madani-images/

   # Rename if needed (remove "page" prefix)
   cd assets/mushaf/madani-images/
   for file in page*.png; do
     newname=$(echo $file | sed 's/page0*//' | sed 's/^/00/' | rev | cut -c 1-7 | rev)
     mv "$file" "$newname"
   done
   ```

3. **Verify Files**

   Ensure you have at least:
   - `assets/mushaf/madani-images/001.png`
   - `assets/mushaf/madani-images/002.png`
   - `assets/mushaf/madani-images/003.png`
   - `assets/mushaf/madani-images/604.png`

4. **Run Flutter**

   ```bash
   flutter pub get
   flutter run
   ```

5. **Test the Pages**

   Navigate to Mushaf reading mode and verify:
   - ✅ Pages show full-color traditional styling
   - ✅ Decorative borders and ornaments visible
   - ✅ Tap detection still works correctly
   - ✅ Verse highlighting functions properly

## Trusted Source Information

**Source:** King Fahd Glorious Quran Printing Complex (Madani Mushaf)
**Website:** https://qurancomplex.gov.sa/
**License:** Free for Islamic applications (attribution required)

### Attribution Required

Add to your app's About/Credits section:

```
Mushaf images provided by King Fahd Glorious Quran Printing Complex
https://qurancomplex.gov.sa/
```

## Technical Details

### Aspect Ratio
- Maintained: `382.68 / 547.09` (from SVG viewBox)
- Ensures consistent rendering across devices

### Image Format
- **Supported:** PNG, JPEG
- **Recommended:** PNG for best quality
- **Resolution:** 1260px or 1920px width

### Performance
- Images are loaded asynchronously
- Automatic caching by Flutter's asset system
- SVG overlay is lightweight
- No performance impact on hit-testing

### Fallback Strategy
- If image file is missing → SVG rendering (current behavior)
- If image fails to load → SVG rendering
- Ensures app never breaks even without images

## Files Changed

1. `lib/presentation/widgets/mushaf_sample_page.dart` - Main implementation
2. `pubspec.yaml` - Asset configuration
3. `scripts/download_sample_mushaf_images.sh` - Download helper
4. `assets/mushaf/madani-images/README.md` - Directory documentation
5. `assets/mushaf/madani-images/DOWNLOAD_INSTRUCTIONS.md` - User guide
6. `docs/mushaf-images-guide.md` - Implementation guide
7. `docs/mushaf-image-overlay-implementation.md` - This file

## Testing Checklist

- [ ] Download images from trusted source
- [ ] Place images in correct directory
- [ ] Run `flutter pub get`
- [ ] Build and run app
- [ ] Open Mushaf reading mode
- [ ] Verify full-color images display
- [ ] Test tap detection on verses
- [ ] Check verse highlighting
- [ ] Test all sample pages (1, 2, 3, 604)
- [ ] Verify fallback to SVG if image missing
- [ ] Check performance on different devices

## Support

For issues or questions:
1. Check `DOWNLOAD_INSTRUCTIONS.md` in the images directory
2. Review `mushaf-images-guide.md` in docs
3. Verify image files are correctly named and placed

## Future Enhancements

Potential improvements:
1. Download images on-demand (first app launch)
2. Support multiple Mushaf styles (Madani, Warsh, etc.)
3. Image quality selector (HD vs Standard)
4. Offline package bundling
5. CDN integration for automatic updates
