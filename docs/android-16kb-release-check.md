# Android 16 KB release verification

Isar Community 3.3.2 replaces the original Isar 3.1 native runtime. Keep the
existing `holy_quran_db` name, storage directory, collection names, schema IDs,
and properties: the upgrade opens existing databases in place. No deletion,
export/import, or user data reset is needed. The original-runtime fixture in
`test/fixtures/isar_3_1` verifies bookmarks and last-read preservation.

`build_runner` is pinned to 2.10.5 because newer releases select AOT builder
compilation that fails with this project's Dart 3.10.8 build hooks. Regenerate
schemas with `dart run build_runner build --delete-conflicting-outputs`.

## Required artifact check

Configure production signing with `android/key.properties` or protected Gradle
project properties, then run:

```sh
flutter build appbundle --release
export BUNDLETOOL_JAR=/absolute/path/to/bundletool-all.jar
export ZIPALIGN="$ANDROID_HOME/build-tools/35.0.0/zipalign"
bash scripts/check_android_16kb.sh build/app/outputs/bundle/release/app-release.aab
```

The command fails if any arm64-v8a or x86_64 library has a LOAD alignment below
16 KB, the bundle does not request `PAGE_ALIGNMENT_16K`, or any bundletool APK
fails `zipalign -c -P 16 4`. Run it on each final signed release bundle.
It uses Java, Python 3, unzip, Android build-tools 35+, and
[Google bundletool](https://github.com/google/bundletool/releases).
The generated inspection APKs use bundletool's default development signing;
the input bundle must still be the production release artifact.

To check ELF alignment alone for an APK or AAB:

```sh
python3 scripts/check_android_page_alignment.py path/to/artifact.apk
python3 -m unittest discover -s scripts -p test_check_android_page_alignment.py
```

## Required device test

Use an Android 15+ 16 KB emulator/device. Confirm the environment first:

```sh
adb shell getconf PAGE_SIZE
# Must print 16384.
```

Install the old app and create bookmarks and a last-read position. Upgrade
without uninstalling or clearing app data, using the same application ID and
signing key. Confirm both values survive, open Classic and Mushaf reading,
read Quran content, add a bookmark, advance the last-read position, force-stop,
relaunch, and confirm the new local state remains. Also test a clean install.
Record Android version, page size, artifact hash, and results in the release
record. Artifact alignment and desktop persistence tests do not replace this
runtime check.

Reference: [Android's page-size guidance](https://developer.android.com/guide/practices/page-sizes).

## Verification for #147 (2026-10-04)

- Flutter 3.38.9 / Dart 3.10.8, AGP 8.11.1.
- Release-mode AAB built using a development signing key for local inspection;
  SHA-256 `9937bd05f21c738d626b8580552b8fe00a271d99acedb76afaefa934394c4aa4`.
- All 10 ARM64/x86_64 native libraries pass ELF LOAD alignment verification.
- Bundle config requests `PAGE_ALIGNMENT_16K`; all 86 generated APKs pass
  `zipalign -c -P 16 4` with build-tools 35.0.0 / bundletool 1.18.3.
- Original Isar 3.1 fixture retains bookmarks and last-read state, accepts a
  position update, and retains it after reopening.
- 347 non-golden Flutter tests pass (one skipped), analysis and format pass;
  five alignment-checker tests pass.
- Android 15 x86_64 `google_apis_ps16k` revision 5 emulator reports `16384`.
  Release APK installs and launches; Classic reading, verse details, bookmarking,
  and Mushaf page rendering work. A saved `1:2` bookmark and last-read `2:1`
  remain visible after force-stop and relaunch.

Repeat the artifact check on the final production-signed release bundle.
