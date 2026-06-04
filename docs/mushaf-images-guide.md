# Mushaf Image Assets Guide

## Trusted Source: King Fahd Glorious Quran Printing Complex (Madani Mushaf)

### Option 1: Download from Quran Android App (Recommended)

1. Visit the Quran Android repository: https://github.com/quran/quran_android
2. Download the image databases from their releases:
   - `quran_images_1260.zip` (1260px width - good for tablets)
   - `quran_images_1920.zip` (1920px width - high quality)
3. Extract the zip file to get page images (page001.png through page604.png)
4. Place images in: `assets/mushaf/madani-images/`

### Option 2: Extract from Quran.com Mobile App

1. Download the official Quran.com app for iOS/Android
2. The app downloads high-quality Madani Mushaf images
3. Extract images from app data (requires root/jailbreak access)

### Option 3: Official King Fahd Complex

1. Visit: https://qurancomplex.gov.sa/
2. Request permission for app integration
3. They may provide direct access to image assets

### Option 4: Use Pre-hosted CDN (If Available)

The following CDN patterns may work (check availability):
- `https://cdn.qurancomplex.gov.sa/images/page{pageNumber}.png`
- `https://images.quran.com/...` (varies by their current infrastructure)

## Image Requirements

- **Format**: PNG or JPEG
- **Naming**: `001.png` through `604.png` (zero-padded 3 digits)
- **Resolution**: Recommended 1260px or 1920px width
- **Quality**: High resolution for comfortable reading
- **Source**: Must be from King Fahd Complex (Madani Mushaf)

## Directory Structure

```
assets/mushaf/madani-images/
├── 001.png
├── 002.png
├── 003.png
├── ...
└── 604.png
```

## License Note

King Fahd Complex allows free use of their Mushaf for Islamic applications.
Ensure proper attribution in your app's about/credits section.

## Next Steps

Once you have the images:
1. Place them in `assets/mushaf/madani-images/`
2. Update `pubspec.yaml` to include the image assets
3. The app will automatically use them with SVG overlay for hit-testing
