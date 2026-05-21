import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/data/local/entities/surah_entity.dart';

void main() {
  group('SurahEntity', () {
    test('fromDomain converts domain model to entity', () {
      const surah = Surah(
        surahNumber: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        numberOfVerses: 7,
      );

      final entity = SurahEntity.fromDomain(surah);

      expect(entity.surahNumber, 1);
      expect(entity.nameArabic, 'الفاتحة');
      expect(entity.nameEnglish, 'Al-Fatihah');
      expect(entity.numberOfVerses, 7);
    });

    test('toDomain converts entity to domain model', () {
      final entity = SurahEntity()
        ..surahNumber = 2
        ..nameArabic = 'البقرة'
        ..nameEnglish = 'Al-Baqarah'
        ..numberOfVerses = 286;

      final surah = entity.toDomain();

      expect(surah.surahNumber, 2);
      expect(surah.nameArabic, 'البقرة');
      expect(surah.nameEnglish, 'Al-Baqarah');
      expect(surah.numberOfVerses, 286);
    });

    test('roundtrip conversion preserves all data', () {
      const original = Surah(
        surahNumber: 114,
        nameArabic: 'الناس',
        nameEnglish: 'An-Nas',
        numberOfVerses: 6,
      );

      final entity = SurahEntity.fromDomain(original);
      final result = entity.toDomain();

      expect(result, equals(original));
      expect(result.surahNumber, original.surahNumber);
      expect(result.nameArabic, original.nameArabic);
      expect(result.nameEnglish, original.nameEnglish);
      expect(result.numberOfVerses, original.numberOfVerses);
    });

    test('id getter returns surahNumber', () {
      final entity = SurahEntity()
        ..surahNumber = 42
        ..nameArabic = 'الشورى'
        ..nameEnglish = 'Ash-Shura'
        ..numberOfVerses = 53;

      expect(entity.id, 42);
    });

    test('handles boundary values for surahNumber', () {
      // First surah
      const surah1 = Surah(
        surahNumber: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        numberOfVerses: 7,
      );

      // Last surah
      const surah114 = Surah(
        surahNumber: 114,
        nameArabic: 'الناس',
        nameEnglish: 'An-Nas',
        numberOfVerses: 6,
      );

      final entity1 = SurahEntity.fromDomain(surah1);
      final entity114 = SurahEntity.fromDomain(surah114);

      expect(entity1.toDomain(), equals(surah1));
      expect(entity114.toDomain(), equals(surah114));
    });

    test('handles empty strings correctly', () {
      const surah = Surah(
        surahNumber: 1,
        nameArabic: '',
        nameEnglish: '',
        numberOfVerses: 0,
      );

      final entity = SurahEntity.fromDomain(surah);
      final result = entity.toDomain();

      expect(result.nameArabic, '');
      expect(result.nameEnglish, '');
    });
  });
}
