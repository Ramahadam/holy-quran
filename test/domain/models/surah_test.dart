import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/surah.dart';

void main() {
  group('Surah', () {
    test('creates instance with required fields', () {
      final surah = Surah(
        surahNumber: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        numberOfVerses: 7,
      );

      expect(surah.surahNumber, 1);
      expect(surah.nameArabic, 'الفاتحة');
      expect(surah.nameEnglish, 'Al-Fatihah');
      expect(surah.numberOfVerses, 7);
    });

    test('equality based on surahNumber', () {
      final surah1 = Surah(
        surahNumber: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        numberOfVerses: 7,
      );
      final surah2 = Surah(
        surahNumber: 1,
        nameArabic: 'Different Name',
        nameEnglish: 'Different Name',
        numberOfVerses: 10,
      );
      final surah3 = Surah(
        surahNumber: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'Al-Baqarah',
        numberOfVerses: 286,
      );

      expect(surah1, equals(surah2));
      expect(surah1, isNot(equals(surah3)));
    });

    test('hashCode based on surahNumber', () {
      final surah1 = Surah(
        surahNumber: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        numberOfVerses: 7,
      );
      final surah2 = Surah(
        surahNumber: 1,
        nameArabic: 'Different Name',
        nameEnglish: 'Different Name',
        numberOfVerses: 10,
      );

      expect(surah1.hashCode, equals(surah2.hashCode));
    });

    test('handles edge cases', () {
      // Test with minimum valid surah number
      final surah1 = Surah(
        surahNumber: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        numberOfVerses: 7,
      );
      expect(surah1.surahNumber, 1);

      // Test with maximum valid surah number
      final surah114 = Surah(
        surahNumber: 114,
        nameArabic: 'الناس',
        nameEnglish: 'An-Nas',
        numberOfVerses: 6,
      );
      expect(surah114.surahNumber, 114);

      // Test with empty strings (should be allowed, validation can be added later)
      final surahEmptyNames = Surah(
        surahNumber: 1,
        nameArabic: '',
        nameEnglish: '',
        numberOfVerses: 0,
      );
      expect(surahEmptyNames.nameArabic, '');
      expect(surahEmptyNames.nameEnglish, '');
    });
  });
}
