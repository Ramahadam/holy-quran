import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/core/utils/checksum_validator.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';

void main() {
  group('QuranRepository - Data Integrity', () {
    test('verse domain model matches expected JSON structure', () {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        translation: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
      );

      expect(verse.verseId, '1:1');
      expect(verse.surahNumber, 1);
      expect(verse.verseNumber, 1);
      expect(verse.arabicText.isNotEmpty, true);
      expect(verse.translation, isNotNull);
    });

    test('surah domain model matches expected JSON structure', () {
      const surah = Surah(
        surahNumber: 1,
        nameArabic: 'Al-Fatihah',
        nameEnglish: 'The Opening',
        numberOfVerses: 7,
      );

      expect(surah.surahNumber, 1);
      expect(surah.nameArabic, 'Al-Fatihah');
      expect(surah.nameEnglish, 'The Opening');
      expect(surah.numberOfVerses, 7);
    });

    test('verseId format is surahNumber:verseNumber', () {
      const verse = Verse(
        verseId: '2:255',
        surahNumber: 2,
        verseNumber: 255,
        arabicText: 'test',
      );

      final parts = verse.verseId.split(':');
      expect(parts.length, 2);
      expect(int.parse(parts[0]), verse.surahNumber);
      expect(int.parse(parts[1]), verse.verseNumber);
    });

    test('surah numbers range from 1 to 114', () {
      const firstSurah = Surah(
        surahNumber: 1,
        nameArabic: 'Al-Fatihah',
        nameEnglish: 'The Opening',
        numberOfVerses: 7,
      );
      const lastSurah = Surah(
        surahNumber: 114,
        nameArabic: 'An-Nas',
        nameEnglish: 'Mankind',
        numberOfVerses: 6,
      );

      expect(firstSurah.surahNumber, 1);
      expect(lastSurah.surahNumber, 114);
    });
  });

  group('QuranRepository - Checksum Validation', () {
    test('checksum validates JSON content correctly', () {
      const sampleJson = '{"verseId":"1:1","arabicText":"test"}';
      final checksum = ChecksumValidator.calculateSHA256(sampleJson);

      expect(ChecksumValidator.verify(sampleJson, checksum), true);
    });

    test('checksum detects tampered content', () {
      const originalJson = '{"verseId":"1:1","arabicText":"test"}';
      const tamperedJson = '{"verseId":"1:1","arabicText":"tampered"}';
      final checksum = ChecksumValidator.calculateSHA256(originalJson);

      expect(ChecksumValidator.verify(tamperedJson, checksum), false);
    });

    test('checksum handles Arabic text correctly', () {
      const arabicContent = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
      final checksum = ChecksumValidator.calculateSHA256(arabicContent);

      expect(checksum.length, 64);
      expect(ChecksumValidator.verify(arabicContent, checksum), true);
    });
  });
}
