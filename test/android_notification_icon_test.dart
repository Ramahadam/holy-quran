import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release resource shrinking keeps the reminder notification icon', () {
    // The icon is referenced only by name from Dart, which the release
    // resource shrinker cannot see.
    final scheduler = File(
      'lib/data/notifications/prayer_reminder_scheduler.dart',
    ).readAsStringSync();
    expect(
      scheduler,
      contains("AndroidInitializationSettings('ic_notification')"),
    );
    expect(
      File(
        'android/app/src/main/res/drawable/ic_notification.xml',
      ).existsSync(),
      isTrue,
    );

    final keepRules = File('android/app/src/main/res/raw/keep.xml');
    expect(keepRules.existsSync(), isTrue);
    expect(keepRules.readAsStringSync(), contains('@drawable/ic_notification'));
  });
}
