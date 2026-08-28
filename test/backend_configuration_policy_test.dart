import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backend configuration policy', () {
    test('ignores environment-specific configuration and private keys', () {
      for (final path in [
        'config/cloudflare.local.json',
        'config/supabase.local.json',
        '.env',
        '.env.local',
        '.env.ci.local',
        'release.pem',
        'release.key',
      ]) {
        final result = Process.runSync('git', [
          'check-ignore',
          '--no-index',
          '--quiet',
          path,
        ]);

        expect(result.exitCode, 0, reason: '$path must be ignored by Git');
      }
    });

    test(
      'does not track environment-specific configuration or private keys',
      () {
        final result = Process.runSync('git', ['ls-files']);
        expect(result.exitCode, 0);

        final trackedSensitivePaths = (result.stdout as String)
            .split('\n')
            .where(
              (path) =>
                  RegExp(r'^config/[^/]+\.local\.json$').hasMatch(path) ||
                  path == '.env' ||
                  path == '.env.local' ||
                  RegExp(r'^\.env\..+\.local$').hasMatch(path) ||
                  RegExp(r'\.(?:pem|key)$').hasMatch(path),
            )
            .toList();

        expect(trackedSensitivePaths, isEmpty);
      },
    );

    test('ships only a sanitized public-client example', () {
      final example =
          jsonDecode(
                File('config/cloudflare.local.example.json').readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(example, {
        'CLOUDFLARE_API_BASE_URL': 'https://your-worker.example.com',
        'APP_VERSION': '0.0.0-local',
      });
      expect(
        example.keys,
        everyElement(
          isNot(matches(RegExp(r'(SECRET|TOKEN|PASSWORD|API_KEY)'))),
        ),
      );
    });
  });
}
