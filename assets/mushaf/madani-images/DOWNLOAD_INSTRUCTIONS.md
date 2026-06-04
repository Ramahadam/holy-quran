# Download Instructions for Madani Mushaf Images

## Quick Start (Recommended Method)

### Step 1: Download Image Database from Quran Android

1. Go to: https://github.com/quran/quran_android/releases
2. Look for the latest release
3. Download `quran_images_1260.zip` or `quran_images_1920.zip`
4. Extract the zip file
5. You'll find files named: `page001.png`, `page002.png`, ..., `page604.png`
6. Copy these files to this directory (`assets/mushaf/madani-images/`)
7. Rename them to match the expected format: `001.png`, `002.png`, etc.

### Step 2: Rename Files (if needed)

If the files are named `page001.png`, rename them:

```bash
cd assets/mushaf/madani-images/
for file in page*.png; do
  newname=$(echo $file | sed 's/page\([0-9]*\)\.png/\1.png/')
  mv "$file" "$newname"
done
```

### Step 3: Verify

Check that you have at least these files for sample pages:
- `001.png`
- `002.png`
- `003.png`
- `604.png`

## Alternative: Direct Download (If Available)

Some trusted CDN sources that may host these images:

1. **Quran.com Infrastructure:**
   - Check: `https://quran-cdn.com/images/...`
   - May require authentication or may have changed structure

2. **Muslim Pro / Similar Apps:**
   - These apps download images during first run
   - Check app data directory after installation

## Verification

After downloading, verify the images:
```bash
cd assets/mushaf/madani-images/
file 001.png 002.png 003.png 604.png
```

You should see output like:
```
001.png: PNG image data, 1260 x 1800, ...
```

## Need Help?

See the main guide: `docs/mushaf-images-guide.md`

## License & Attribution

These images are from the King Fahd Glorious Quran Printing Complex (Madani Mushaf).
- Free for Islamic applications
- Proper attribution required
- No commercial use without permission

Attribution text for your app:
```
Mushaf images provided by King Fahd Glorious Quran Printing Complex
https://qurancomplex.gov.sa/
```
