# ⚡ Download Mushaf Images NOW - Step by Step

## Option 1: Direct Download Link (Fastest)

### Step 1: Click this link
https://github.com/quran/quran_android/releases/download/v3.6.3/quran_images_1260.zip

**OR** for higher quality:
https://github.com/quran/quran_android/releases/download/v3.6.3/quran_images_1920.zip

This will start downloading immediately (~50-100 MB)

### Step 2: Extract the ZIP file
- Double-click the downloaded `quran_images_1260.zip` file
- It will extract to a folder with 604 PNG files

### Step 3: Copy Files to Project

Open Terminal and run:

```bash
# Navigate to the extracted folder (adjust path if needed)
cd ~/Downloads/quran_images_1260

# Copy all images to your project
cp page*.png "/Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images/"

# Navigate to project images directory
cd "/Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images"

# Rename files (remove "page" prefix)
for file in page*.png; do
  newname=$(echo $file | sed 's/page//')
  mv "$file" "$newname"
done

# Verify you have the files
ls -lh 001.png 002.png 003.png 604.png
```

### Step 4: Test It!

```bash
cd "/Users/ram/Desktop/Holy Quran"
flutter pub get
flutter run
```

---

## Option 2: Alternative Mirror (If GitHub is slow)

Try these alternative download sources:

1. **Quran.com App Data**
   - Install Quran.com app
   - Images download automatically
   - Export from app data

2. **Direct from Project Repository**
   Visit: https://github.com/quran/quran-images
   (Check if this repository exists and has image files)

---

## Quick Verification

After copying, check:
```bash
cd "/Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images"
ls -1 | head -10
```

You should see:
```
001.png
002.png
003.png
004.png
...
```

## If Links Don't Work

1. Go to: https://github.com/quran/quran_android/releases
2. Find the latest release (v3.6.3 or newer)
3. Look for `quran_images_1260.zip` or `quran_images_1920.zip`
4. Click to download
5. Follow steps 2-4 above

---

## Expected File Size

- `quran_images_1260.zip`: ~50 MB
- `quran_images_1920.zip`: ~100 MB
- Each PNG file: ~80-150 KB

## Help! It's Not Working

If you encounter issues:

1. **Files not found after extract?**
   - Check Downloads folder
   - Look for a folder named `quran_images_1260` or similar

2. **Rename script not working?**
   - Do it manually: rename `page001.png` → `001.png`, `page002.png` → `002.png`, etc.
   - You only need pages 1, 2, 3, and 604 for testing

3. **Images still not showing in app?**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 🎯 Pro Tip: Test with Just One Page First

To test quickly:
1. Download only `page001.png` from the zip
2. Rename to `001.png`
3. Put in `assets/mushaf/madani-images/`
4. Run app and check page 1

If that works, copy all the rest!

---

## What You'll See After Setup

**BEFORE:** Plain black Arabic text on white background

**AFTER:**
- ✨ Colorful decorative borders
- 🎨 Traditional ornamental verse markers
- 📖 Beautiful Madani Mushaf styling
- 🌟 Professional reading experience

Just like the screenshot you showed me!

---

## Ready? Let's Do This! 🚀

1. Click the download link at the top
2. Wait for download to complete
3. Run the copy commands
4. Launch the app
5. Enjoy! 🎉
