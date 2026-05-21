import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';

void main() {
  group('Bookmark', () {
    final testDate = DateTime(2024, 1, 1);

    test('creates instance with required fields', () {
      final bookmark = Bookmark(
        id: 1,
        verseId: '1:1',
        timestamp: testDate,
      );

      expect(bookmark.id, 1);
      expect(bookmark.verseId, '1:1');
      expect(bookmark.timestamp, testDate);
      expect(bookmark.note, isNull);
    });

    test('creates instance with note', () {
      final bookmark = Bookmark(
        id: 1,
        verseId: '1:1',
        timestamp: testDate,
        note: 'Important verse',
      );

      expect(bookmark.note, 'Important verse');
    });

    test('equality based on id', () {
      final bookmark1 = Bookmark(
        id: 1,
        verseId: '1:1',
        timestamp: testDate,
      );
      final bookmark2 = Bookmark(
        id: 1,
        verseId: '2:1',
        timestamp: testDate,
      );
      final bookmark3 = Bookmark(
        id: 2,
        verseId: '1:1',
        timestamp: testDate,
      );

      expect(bookmark1, equals(bookmark2));
      expect(bookmark1, isNot(equals(bookmark3)));
    });
  });
}
