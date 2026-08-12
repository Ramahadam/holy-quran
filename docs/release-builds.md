# Mobile Release Builds

## Supported Platforms

Android and iOS are the supported release targets. The macOS, Windows, Linux,
and web directories remain Flutter project scaffolding; adding them as release
targets or removing them requires a separate approved change.

## Product Metadata

The Android application label and iOS display name are **Holy Quran**.

| Platform | Release identifier |
| --- | --- |
| Android | `com.holyquran.holy_quran_app` |
| iOS | `com.holyquran.holyQuranApp` |

Keep these identifiers stable after a store release. Changing either creates a
different store application rather than an update.

## Versioning

The release version is declared in `pubspec.yaml` as `major.minor.patch+build`.
Flutter maps the value before `+` to Android `versionName` and iOS
`CFBundleShortVersionString`; the value after `+` becomes Android `versionCode`
and iOS `CFBundleVersion`.

Before every store upload, update `pubspec.yaml` and use a build number greater
than every previously published build for that platform.

## Build Commands

Run the checks before building a release:

```sh
flutter analyze
flutter test
```

Build the Android App Bundle for Google Play:

```sh
flutter build appbundle --release
```

Build the iOS archive for App Store distribution:

```sh
flutter build ipa --release
```

The Cloudflare Worker URL defaults to the production URL. To use a different
endpoint for a release candidate, provide `CLOUDFLARE_API_BASE_URL` with a
`--dart-define` or a reviewed `--dart-define-from-file` configuration.
