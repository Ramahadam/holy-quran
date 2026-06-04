# Quick Start: Get Mushaf Images Working Now

## 5-Minute Setup

### Step 1: Download the Image Package (2 minutes)

1. Open your browser
2. Go to: **https://github.com/quran/quran_android/releases**
3. Find the latest release
4. Click on `quran_images_1260.zip` to download (or `quran_images_1920.zip` for higher quality)
5. Wait for download to complete (~50-100 MB)

### Step 2: Extract Images (1 minute)

```bash
# Navigate to your downloads folder
cd ~/Downloads

# Extract the zip file
unzip quran_images_1260.zip

# This creates files: page001.png, page002.png, ..., page604.png
```

### Step 3: Copy to Project (1 minute)

```bash
# Copy images to your Holy Quran project
cp page*.png "/Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images/"

# Navigate to the images directory
cd "/Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images/"

# Rename files (remove "page" prefix, keep zero-padding)
for file in page*.png; do
  newname=$(echo $file | sed 's/page//')
  mv "$file" "$newname"
done

# Verify you have the files
ls -lh 001.png 002.png 003.png 604.png
```

### Step 4: Run the App (1 minute)

```bash
# Go back to project root
cd "/Users/ram/Desktop/Holy Quran"

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Step 5: Test It! (30 seconds)

1. Open the app
2. Navigate to Mushaf reading mode
3. You should see **beautiful full-color traditional Mushaf pages** instead of plain black text!
4. Tap on verses - hit detection still works perfectly!

## Expected Result

### Before (SVG only):
```
┌─────────────────────┐
│                     │
│  بِسْمِ اللَّهِ     │ ← Black text
│  الرَّحْمَٰنِ       │ ← White background
│  الرَّحِيمِ         │ ← No decoration
│                     │
└─────────────────────┘
```

### After (Full-color images):
```
┌─────────────────────┐
│ ╔═══════════════╗   │ ← Colorful borders
│ ║ بِسْمِ اللَّهِ ║   │ ← Traditional styling
│ ║ الرَّحْمَٰنِ    ║   │ ← Ornamental markers
│ ║ الرَّحِيمِ      ║   │ ← Beautiful design
│ ╚═══════════════╝   │ ← Rich colors
└─────────────────────┘
```

## Troubleshooting

### "Images not showing"

Check file names:
```bash
cd "/Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images/"
ls 001.png 002.png 003.png 604.png
```

Files should be named exactly: `001.png`, `002.png`, etc. (with zero-padding)

### "Cannot find files"

Make sure images are in the correct directory:
```bash
pwd
# Should show: /Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images
```

### "Still seeing black text"

1. Stop the app
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run `flutter run` again

## Alternative: Just Test with One Page

If you want to test quickly with just one page:

1. Download only `page001.png`
2. Rename it to `001.png`
3. Put it in `assets/mushaf/madani-images/`
4. Open page 1 in the app
5. You'll see the beautiful page!

## What You'll Get

✅ **Traditional Madani Mushaf styling**
✅ **Colorful decorative borders**
✅ **Ornamental verse markers**
✅ **High-quality, readable text**
✅ **Comfortable for long reading sessions**
✅ **Trusted source (King Fahd Complex)**
✅ **Hit-testing still works perfectly**

## Time Investment

- **Setup:** 5 minutes (one-time)
- **Result:** Beautiful, traditional Quran reading experience
- **Worth it?** Absolutely! 🌟

## Need Help?

See detailed guides:
- `assets/mushaf/madani-images/DOWNLOAD_INSTRUCTIONS.md`
- `docs/mushaf-images-guide.md`
- `docs/mushaf-image-overlay-implementation.md`
