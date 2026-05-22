import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/core/utils/checksum_validator.dart';

void main() {
  group('ChecksumValidator', () {
    test('calculateSHA256 returns correct hash for known input', () {
      const testString = 'Hello, World!';
      final hash = ChecksumValidator.calculateSHA256(testString);

      expect(
        hash,
        'dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f',
      );
    });

    test('calculateSHA256FromBytes returns correct hash', () {
      final bytes = Uint8List.fromList(utf8.encode('Hello, World!'));
      final hash = ChecksumValidator.calculateSHA256FromBytes(bytes);

      expect(
        hash,
        'dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f',
      );
    });

    test('verify returns true for matching checksum', () {
      const content = 'Test content';
      final checksum = ChecksumValidator.calculateSHA256(content);

      expect(ChecksumValidator.verify(content, checksum), true);
    });

    test('verify returns false for non-matching checksum', () {
      const content = 'Test content';
      const wrongChecksum = 'wrong_hash';

      expect(ChecksumValidator.verify(content, wrongChecksum), false);
    });

    test('verify is case-insensitive', () {
      const content = 'Hello, World!';
      const lowercaseHash =
          'dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f';
      const uppercaseHash =
          'DFFD6021BB2BD5B0AF676290809EC3A53191DD81C7F70A4B28688A362182986F';

      expect(ChecksumValidator.verify(content, lowercaseHash), true);
      expect(ChecksumValidator.verify(content, uppercaseHash), true);
    });

    test('verifyBytes returns true for matching checksum', () {
      final bytes = Uint8List.fromList(utf8.encode('Test content'));
      final checksum = ChecksumValidator.calculateSHA256FromBytes(bytes);

      expect(ChecksumValidator.verifyBytes(bytes, checksum), true);
    });

    test('verifyBytes returns false for non-matching checksum', () {
      final bytes = Uint8List.fromList(utf8.encode('Test content'));
      const wrongChecksum = 'wrong_hash';

      expect(ChecksumValidator.verifyBytes(bytes, wrongChecksum), false);
    });

    test('empty string has deterministic hash', () {
      const emptyString = '';
      final hash = ChecksumValidator.calculateSHA256(emptyString);

      expect(
        hash,
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('unicode content is handled correctly', () {
      const arabicText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
      final hash1 = ChecksumValidator.calculateSHA256(arabicText);
      final hash2 = ChecksumValidator.calculateSHA256(arabicText);

      expect(hash1, hash2);
      expect(hash1.length, 64);
    });
  });
}
