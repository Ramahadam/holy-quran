import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final buildScript = File('android/app/build.gradle.kts').readAsStringSync();
  final androidIgnore = File('android/.gitignore').readAsStringSync();
  final releaseGuide = File('docs/release-builds.md').readAsStringSync();

  group('Android release signing policy', () {
    test('never signs a release with the debug signing configuration', () {
      expect(buildScript, isNot(contains('signingConfigs.getByName("debug")')));
      expect(buildScript, contains('create("release")'));
      expect(
        buildScript,
        contains('signingConfig = signingConfigs.getByName("release")'),
      );
    });

    test('supports ignored local properties and protected CI properties', () {
      expect(buildScript, contains('rootProject.file("key.properties")'));
      expect(buildScript, contains('providers.gradleProperty'));
      for (final propertyName in [
        'releaseStoreFile',
        'releaseStorePassword',
        'releaseKeyAlias',
        'releaseKeyPassword',
      ]) {
        expect(buildScript, contains('"$propertyName"'));
        expect(releaseGuide, contains('ORG_GRADLE_PROJECT_$propertyName'));
      }
      expect(androidIgnore, contains('key.properties'));
      expect(androidIgnore, contains('**/*.jks'));
    });

    test('validates required signing inputs only for release builds', () {
      expect(buildScript, contains('validateReleaseSigning'));
      expect(buildScript, contains('preReleaseBuild'));
      expect(buildScript, contains('GradleException'));
    });

    test('documents setup and artifact certificate verification', () {
      expect(releaseGuide, contains('android/key.properties'));
      expect(releaseGuide, contains('ORG_GRADLE_PROJECT_releaseStoreFile'));
      expect(releaseGuide, contains('keytool -printcert -jarfile'));
      expect(releaseGuide, contains('CN=Android Debug'));
    });
  });
}
