import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The owner chose one Arabic launcher name on every device (#206).
const _appName = 'القرآن الكريم';

void main() {
  test('Android launcher label is the Arabic app name', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="$_appName"'));
  });

  test('iOS display name is the Arabic app name', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      RegExp(
        r'<key>CFBundleDisplayName</key>\s*<string>([^<]*)</string>',
      ).firstMatch(plist)?.group(1),
      _appName,
    );
  });
}
