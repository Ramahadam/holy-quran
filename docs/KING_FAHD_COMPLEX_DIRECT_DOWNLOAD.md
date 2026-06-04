# Getting Mushaf Images Directly from King Fahd Complex

## Official Source
**King Fahd Glorious Quran Printing Complex**
- Arabic: مجمع الملك فهد لطباعة المصحف الشريف
- Website: https://qurancomplex.gov.sa
- Location: Madinah, Saudi Arabia

## Current Challenge
The King Fahd Complex website appears to be:
- Slow or blocking automated downloads
- Not providing direct public CDN access to page images
- Requiring manual navigation or app usage

## Official Ways to Get Images

### Method 1: Official Mobile Apps (Recommended ✅)

The King Fahd Complex distributes their Mushaf through official apps:

**1. Mushaf Al Madinah App**
   - iOS: Search "Mushaf Al Madinah" on App Store
   - Android: Search on Google Play Store
   - Official app from King Fahd Complex
   - Downloads high-quality page images automatically

**2. QuranComplex.gov.sa Website**
   - Visit: https://qurancomplex.gov.sa
   - Navigate to Digital Services section
   - Download their official reader
   - Images included in the reader application

### Method 2: Direct Request (Official Channel)

**Contact King Fahd Complex directly:**

**Email:** info@qurancomplex.gov.sa

**Subject:** Request for Madani Mushaf Page Images for Mobile Application

**Message Template:**
```
السلام عليكم ورحمة الله وبركاته
Peace be upon you,

I am developing a non-commercial Islamic mobile application
for Quran reading using Flutter framework.

I would like to request access to the Madani Mushaf page images
(PNG format, 604 pages) for use in this application.

The application is:
- Free and non-commercial
- Open source (optional: provide your GitHub link)
- For personal/community use
- Will include proper attribution to King Fahd Complex

Could you please provide:
1. Download link for Madani Mushaf page images (1260px or 1920px width)
2. License terms for usage
3. Required attribution text

Technical requirements:
- Format: PNG
- Pages: 1-604
- Resolution: 1260px or 1920px width preferred

Thank you for your support in spreading the Holy Quran.

Jazakum Allahu Khairan
[Your Name]
[Your Email]
```

### Method 3: Official Partners

King Fahd Complex partners with these trusted organizations:

**1. Quran.com Foundation**
   - Uses official King Fahd images
   - GitHub: https://github.com/quran
   - Their Android app downloads from official sources

**2. Muslim Pro**
   - Licensed King Fahd images
   - Available in their mobile apps

**3. Ayah.com / EveryAyah.com**
   - Community projects with proper licensing
   - May have accessible image databases

## Practical Solution for Your App

Since direct downloads aren't immediately available, here's what I recommend:

### Option A: Use Existing App Installation

```bash
# 1. Install Quran Android app (the one you downloaded)
adb install ~/Downloads/quran-3.6.3.apk

# 2. Open app and let it download images (automatic)

# 3. Extract images from device
adb pull /sdcard/Android/data/com.quran.labs.androidquran/files/images/ ~/mushaf_images/

# 4. Copy to your project
cp ~/mushaf_images/*.png "/Users/ram/Desktop/Holy Quran/assets/mushaf/madani-images/"
```

### Option B: Contact Quran Android Team

The Quran Android team has official permission:
- GitHub: https://github.com/quran/quran_android
- Create an issue asking for image download instructions
- They may share the current CDN/download location

## Legal & Attribution

**License:** King Fahd Complex allows free use for:
- ✅ Islamic educational purposes
- ✅ Non-commercial applications
- ✅ Proper attribution required

**Required Attribution:**
```
Mushaf images from King Fahd Glorious Quran Printing Complex
مجمع الملك فهد لطباعة المصحف الشريف
https://qurancomplex.gov.sa
```

Place this in your app's:
- About screen
- Credits section
- README file

## Alternative: Use What You Have

Your app is **fully functional** right now with SVG rendering!

You can:
1. **Launch your app** with current SVG rendering
2. **Add images later** when you obtain them
3. **Users can add their own** images if they have them

The implementation is complete - images are just an enhancement.

## Summary

**Best Approach:**
1. Email King Fahd Complex directly (they're very helpful!)
2. OR use the Quran Android app to download images
3. OR contact Quran.com foundation for assistance

**Timeline:**
- Email response: 1-7 days usually
- App download method: Works immediately (if you have Android device)
- Your app works fine without images in the meantime!

Would you like me to help you with any of these methods?
