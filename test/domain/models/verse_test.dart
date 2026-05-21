import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/verse.dart';

void main() {
  group('Verse', () {
    test('creates instance with required fields', () {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      );

      expect(verse.verseId, '1:1');
      expect(verse.surahNumber, 1);
      expect(verse.verseNumber, 1);
      expect(verse.arabicText, 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
      expect(verse.translation, isNull);
    });

    test('creates instance with translation', () {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        translation: 'In the name of Allah, the Most Gracious, the Most Merciful',
      );

      expect(verse.translation, isNotNull);
    });

    test('equality based on verseId', () {
      const verse1 = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'Text 1',
      );
      const verse2 = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'Text 2',
      );
      const verse3 = Verse(
        verseId: '1:2',
        surahNumber: 1,
        verseNumber: 2,
        arabicText: 'Text 3',
      );

      expect(verse1, equals(verse2));
      expect(verse1, isNot(equals(verse3)));
    });

    test('hashCode based on verseId', () {
      const verse1 = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'Text',
      );
      const verse2 = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: 'Different Text',
      );

      expect(verse1.hashCode, equals(verse2.hashCode));
    });
  });
}
