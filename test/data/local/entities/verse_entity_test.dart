import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/data/local/entities/verse_entity.dart';

void main() {
  group('VerseEntity', () {
    test('fromDomain converts domain model to entity', () {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        translation: 'In the name of Allah, the Most Gracious, the Most Merciful',
      );

      final entity = VerseEntity.fromDomain(verse);

      expect(entity.verseId, '1:1');
      expect(entity.surahNumber, 1);
      expect(entity.verseNumber, 1);
      expect(entity.arabicText, 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
      expect(
          entity.translation,
          'In the name of Allah, the Most Gracious, the Most Merciful');
    });

    test('fromDomain handles null translation', () {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      );

      final entity = VerseEntity.fromDomain(verse);

      expect(entity.translation, isNull);
    });

    test('toDomain converts entity to domain model', () {
      final entity = VerseEntity()
        ..verseId = '2:255'
        ..surahNumber = 2
        ..verseNumber = 255
        ..arabicText = 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ'
        ..translation = 'Allah - there is no deity except Him'
        ..page = 42;

      final verse = entity.toDomain();

      expect(verse.verseId, '2:255');
      expect(verse.surahNumber, 2);
      expect(verse.verseNumber, 255);
      expect(verse.arabicText, 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ');
      expect(verse.translation, 'Allah - there is no deity except Him');
      expect(verse.page, 42);
    });

    test('roundtrip conversion preserves all data', () {
      const original = Verse(
        verseId: '114:6',
        surahNumber: 114,
        verseNumber: 6,
        arabicText: 'مِنَ الْجِنَّةِ وَالنَّاسِ',
        translation: 'From among the jinn and mankind',
      );

      final entity = VerseEntity.fromDomain(original);
      final result = entity.toDomain();

      expect(result, equals(original));
      expect(result.verseId, original.verseId);
      expect(result.surahNumber, original.surahNumber);
      expect(result.verseNumber, original.verseNumber);
      expect(result.arabicText, original.arabicText);
      expect(result.translation, original.translation);
    });

    test('roundtrip conversion preserves null translation', () {
      const original = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        translation: null,
      );

      final entity = VerseEntity.fromDomain(original);
      final result = entity.toDomain();

      expect(result, equals(original));
      expect(result.translation, isNull);
    });

    test('handles empty strings correctly', () {
      const verse = Verse(
        verseId: '',
        surahNumber: 0,
        verseNumber: 0,
        arabicText: '',
        translation: '',
      );

      final entity = VerseEntity.fromDomain(verse);
      final result = entity.toDomain();

      expect(result.verseId, '');
      expect(result.arabicText, '');
      expect(result.translation, '');
    });

    test('handles special characters in Arabic text', () {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'اَلْحَمْدُ لِلّٰهِ رَبِّ الْعٰلَمِیْنَ',
      );

      final entity = VerseEntity.fromDomain(verse);
      final result = entity.toDomain();

      expect(result.arabicText, verse.arabicText);
    });
  });
}
