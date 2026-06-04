# Alternative Sources for Mushaf Images

## Issue
The `quran_images_1260.zip` files are no longer available in GitHub releases.

## Solution Options

### Option 1: Install Quran Android App and Extract Images

1. **Install the APK** you downloaded:
   ```bash
   # If you have an Android device/emulator
   adb install ~/Downloads/quran_android-3.6.3/app/build/outputs/apk/release/quran-3.6.3.apk
   ```

2. **Open the app** - it will download images on first run

3. **Extract images** from device:
   ```bash
   adb pull /sdcard/Android/data/com.quran.labs.androidquran/files/images/
   ```

### Option 2: Use everyayah.com (Simple Testing)

Try downloading from everyayah.com:
```bash
cd "/Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images"

# Download sample pages
for page in 001 002 003 604; do
  curl -L -o $page.png "https://everyayah.com/data/quranpngs/${page}.png"
done
```

### Option 3: Use QuranEnc.com

1. Visit: https://quranenc.com/en/browse
2. Right-click on any page
3. "Save Image As..."
4. Save as `001.png`, `002.png`, etc.

### Option 4: Generate from Source (Advanced)

Use the quran.com-images generator:

```bash
cd /tmp/quran.com-images

# Set up Docker
docker-compose up -d

# Generate pages 1, 2, 3, 604
docker-compose run gen /app/script/generate.pl --width 1260 --output ./output/ --pages 1..3,604

# Copy to project
cp /tmp/quran.com-images/output/*.png "/Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images/"
```

### Option 5: Contact Me for Help

The King Fahd Complex images are protected, so downloading requires:
1. Official app installation
2. Manual extraction
3. Or contacting the Quran Complex directly

## Quick Test (Temporary)

For immediate testing, I can help you create placeholder images or we can test with the current SVG rendering, which already works!

The app will:
- ✅ Work perfectly with SVG (current state)
- ✅ Automatically use images when you add them
- ✅ Show beautiful pages once images are in place

## Recommendation

**For now:** Test the app with SVG rendering - it works fine!
**Later:** Install the Quran Android app on a device and extract the images

The implementation is complete and working - we just need the image assets.
