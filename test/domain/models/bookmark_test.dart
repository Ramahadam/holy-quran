import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';

void main() {
  group('Bookmark', () {
    final testDate = DateTime(2024, 1, 1);

    test('creates instance with required fields', () {
      final bookmark = Bookmark(
        verseId: '1:1',
        timestamp: testDate,
      );

      expect(bookmark.verseId, '1:1');
      expect(bookmark.timestamp, testDate);
      expect(bookmark.note, isNull);
    });

    test('creates instance with note', () {
      final bookmark = Bookmark(
        verseId: '1:1',
        timestamp: testDate,
        note: 'Important verse',
      );

      expect(bookmark.note, 'Important verse');
    });

    test('equality based on verseId and timestamp', () {
      final bookmark1 = Bookmark(
        verseId: '1:1',
        timestamp: testDate,
      );
      final bookmark2 = Bookmark(
        verseId: '1:1',
        timestamp: testDate,
        note: 'Different note',
      );
      final bookmark3 = Bookmark(
        verseId: '2:1',
        timestamp: testDate,
      );
      final bookmark4 = Bookmark(
        verseId: '1:1',
        timestamp: DateTime(2024, 2, 1),
      );

      // Same verseId and timestamp - equal
      expect(bookmark1, equals(bookmark2));

      // Different verseId - not equal
      expect(bookmark1, isNot(equals(bookmark3)));

      // Different timestamp - not equal
      expect(bookmark1, isNot(equals(bookmark4)));
    });

    test('hashCode based on verseId and timestamp', () {
      final bookmark1 = Bookmark(
        verseId: '1:1',
        timestamp: testDate,
      );
      final bookmark2 = Bookmark(
        verseId: '1:1',
        timestamp: testDate,
        note: 'Some note',
      );

      expect(bookmark1.hashCode, equals(bookmark2.hashCode));
    });
  });
}

