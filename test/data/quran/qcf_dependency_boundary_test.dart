import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application code does not import QCF package internals', () {
    final privateImports = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains('package:qcf_quran/src/'),
        )
        .map((file) => file.path)
        .toList();

    expect(privateImports, isEmpty);
  });
}
