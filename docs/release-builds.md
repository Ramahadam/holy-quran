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

## Android Release Signing

Android release builds use a production upload key and never fall back to the
debug certificate. Keep the keystore and its passwords outside version control.
See Flutter's [Android release guide](https://docs.flutter.dev/deployment/android#sign-the-app)
and Android's [app-signing guidance](https://developer.android.com/studio/publish/app-signing).

For a local release build, create `android/key.properties` with the upload-key
values supplied by the release owner:

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=<keystore password>
keyAlias=<upload key alias>
keyPassword=<upload key password>
```

Both `android/key.properties` and keystore files are ignored by Git. Do not add
either with a force-add command.

For CI, provision the keystore as a protected secret file and expose its path
and credentials as Gradle project properties. Gradle maps these protected
environment variables to the properties consumed by the build:

- `ORG_GRADLE_PROJECT_releaseStoreFile`
- `ORG_GRADLE_PROJECT_releaseStorePassword`
- `ORG_GRADLE_PROJECT_releaseKeyAlias`
- `ORG_GRADLE_PROJECT_releaseKeyPassword`

Release signing fails with a list of missing properties or a missing-keystore
error. Debug builds do not require release-signing properties.

After building the App Bundle, print its signer certificate:

```sh
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Confirm that the owner is not `CN=Android Debug, O=Android, C=US` and that the
SHA-256 fingerprint matches the upload certificate recorded in Google Play
Console. The release owner must perform this check before uploading an artifact.

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

The Cloudflare Worker URL defaults to the production URL. CI can inject a
different public endpoint and version explicitly from protected CI variables:

```sh
flutter build appbundle --release \
  --dart-define=CLOUDFLARE_API_BASE_URL="$CLOUDFLARE_API_BASE_URL" \
  --dart-define=APP_VERSION="$APP_VERSION"
```

These Dart defines are compiled into the client and therefore must not contain
secrets. Keep Quran Foundation credentials in Cloudflare Worker secrets. If a
CI job needs credentials to deploy the Worker, supply them through the CI
secret store directly to the deployment command; do not write a tracked config
file.
