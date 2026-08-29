import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const checkCommand = 'bash scripts/check_dart_format.sh';

  group('Dart formatting policy', () {
    test('CI and contributor docs use the same non-mutating check', () {
      final checkerFile = File('scripts/check_dart_format.sh');
      expect(checkerFile.existsSync(), isTrue);

      final checker = checkerFile.readAsStringSync();
      final workflow = File('.github/workflows/quality.yml').readAsStringSync();
      final readme = File('README.md').readAsStringSync();

      expect(
        checker,
        contains('dart format --output=none --set-exit-if-changed'),
      );
      expect(readme, contains(checkCommand));

      final formatStep = workflow.indexOf(
        '- name: Check Dart formatting\n        run: $checkCommand',
      );
      final analyzeStep = workflow.indexOf('- run: flutter analyze');
      expect(formatStep, greaterThanOrEqualTo(0));
      expect(analyzeStep, greaterThan(formatStep));
    });

    test('generated Dart has an explicit inclusion and exclusion policy', () {
      final checkerFile = File('scripts/check_dart_format.sh');
      expect(checkerFile.existsSync(), isTrue);

      final checker = checkerFile.readAsStringSync();
      final readme = File('README.md').readAsStringSync();

      expect(checker, contains("'*.dart'"));
      expect(checker, contains("':(exclude,glob)**/*.g.dart'"));
      expect(readme, contains('`*.g.dart`'));
      expect(readme, contains('pinned Isar'));
      expect(readme, contains('generator'));
      expect(readme, contains('Flutter localization'));
    });
  });
}
