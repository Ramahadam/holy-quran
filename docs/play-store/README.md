# Google Play listing assets — #150

Status: **draft, awaiting owner approval**. Do not upload until the icon,
feature graphics, screenshots, and both language versions of the copy are approved.

## Files

- `assets/branding/holy-quran-icon.svg`: editable master icon, with an open-book
  emblem and arch, using the app's green and warm paper palette.
- `icon-512.png`: 512×512 RGBA Play listing icon, without baked-in rounded corners.
- `en-US/feature-graphic.png` and `ar/feature-graphic.png`: 1024×500 RGB localized
  feature graphics; corresponding SVG sources remain editable.
- `en-US/` and `ar/`: title, short description, full description, and phone
  screenshots. Copy is supplied as plain UTF-8 text for Play Console.
- Android launcher: all five legacy density PNGs; adaptive vector foreground and
  green background for API 26+, plus a themed monochrome layer for API 33+.

The emblem uses graphic strokes, not Quran text or invented Arabic calligraphy.
The foreground stays within the adaptive icon's safe area. No generator package
or runtime dependency is added.

## Requirements checked

- Titles ≤30 characters; short descriptions ≤80; full descriptions ≤4,000.
- Play icon 512×512 PNG under 1 MB.
- Feature graphics exactly 1024×500, no alpha channel.
- Phone screenshots captured from the real release-mode application at
  1080×1920. No fabricated UI or debug banner.

Sources checked 2026-10-11:
[Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151),
[adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).

## Release and approval notes

The screenshot build is release mode signed with a development key, solely for
local inspection. Production signing and Play uploads belong to #148 and #151.
No private user data or real feedback submissions are used in screenshots.

The open #143 Sajda-marker issue is outside this change. Screenshots use
Al-Fatihah and other unaffected reading content. #146 also remains open;
several of its fixes are already present on main. Refresh screenshots after any
further visual changes before publishing the listing.

Before upload, the owner should approve the name, emblem, graphics, Arabic
wording, English wording, and screenshots. This issue remains open until approval.

## Local verification

- Android x86_64 release APK builds and installs on the Android 15 16 KB emulator.
- The installed adaptive icon was inspected in the launcher's circular mask.
- All density PNG dimensions, adaptive XML parsing, store image dimensions and
  color modes, all eight screenshot dimensions, and copy length limits pass.
- Screenshots show the existing English Home localization limitation tracked by
  #146: the continue-reading Surah name remains Arabic. Do not alter screenshots
  to hide it; recapture that screen after the code is fixed.
- `review-preview.png` is a contact sheet for owner review, not an upload asset.
- No Dart behavior changed; no application test rerun was needed for this asset
  change. Monochrome resources compile, but themed-icon behavior on other
  launchers still needs a final device review before publication.
