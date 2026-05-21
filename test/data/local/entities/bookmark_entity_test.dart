import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/data/local/entities/bookmark_entity.dart';

void main() {
  group('BookmarkEntity', () {
    final testDate = DateTime(2024, 1, 1, 10, 30);

    test('fromDomain converts domain model to entity', () {
      final bookmark = Bookmark(
        verseId: '1:1',
        timestamp: testDate,
        note: 'Important verse',
      );

      final entity = BookmarkEntity.fromDomain(bookmark);

      expect(entity.verseId, '1:1');
      expect(entity.timestamp, testDate);
      expect(entity.note, 'Important verse');
    });

    test('fromDomain handles null note', () {
      final bookmark = Bookmark(
        verseId: '2:255',
        timestamp: testDate,
      );

      final entity = BookmarkEntity.fromDomain(bookmark);

      expect(entity.verseId, '2:255');
      expect(entity.timestamp, testDate);
      expect(entity.note, isNull);
    });

    test('toDomain converts entity to domain model', () {
      final entity = BookmarkEntity()
        ..verseId = '3:190'
        ..timestamp = testDate
        ..note = 'Study this verse';

      final bookmark = entity.toDomain();

      expect(bookmark.verseId, '3:190');
      expect(bookmark.timestamp, testDate);
      expect(bookmark.note, 'Study this verse');
    });

    test('roundtrip conversion preserves all data', () {
      final original = Bookmark(
        verseId: '18:109',
        timestamp: testDate,
        note: 'Beautiful verse about knowledge',
      );

      final entity = BookmarkEntity.fromDomain(original);
      final result = entity.toDomain();

      expect(result, equals(original));
      expect(result.verseId, original.verseId);
      expect(result.timestamp, original.timestamp);
      expect(result.note, original.note);
    });

    test('roundtrip conversion preserves null note', () {
      final original = Bookmark(
        verseId: '1:1',
        timestamp: testDate,
        note: null,
      );

      final entity = BookmarkEntity.fromDomain(original);
      final result = entity.toDomain();

      expect(result, equals(original));
      expect(result.note, isNull);
    });

    test('handles timestamp precision correctly', () {
      final preciseTime = DateTime(2024, 12, 31, 23, 59, 59, 999, 999);
      final bookmark = Bookmark(
        verseId: '1:1',
        timestamp: preciseTime,
      );

      final entity = BookmarkEntity.fromDomain(bookmark);
      final result = entity.toDomain();

      expect(result.timestamp, preciseTime);
      expect(result.timestamp.microsecond, 999);
    });

    test('handles empty strings correctly', () {
      final bookmark = Bookmark(
        verseId: '',
        timestamp: testDate,
        note: '',
      );

      final entity = BookmarkEntity.fromDomain(bookmark);
      final result = entity.toDomain();

      expect(result.verseId, '');
      expect(result.note, '');
    });

    test('handles multi-line notes', () {
      final bookmark = Bookmark(
        verseId: '2:255',
        timestamp: testDate,
        note: 'Line 1\nLine 2\nLine 3',
      );

      final entity = BookmarkEntity.fromDomain(bookmark);
      final result = entity.toDomain();

      expect(result.note, 'Line 1\nLine 2\nLine 3');
    });

    test('handles special characters in notes', () {
      final bookmark = Bookmark(
        verseId: '1:1',
        timestamp: testDate,
        note: 'Note with émojis 📖 and symbols: @#\$%',
      );

      final entity = BookmarkEntity.fromDomain(bookmark);
      final result = entity.toDomain();

      expect(result.note, 'Note with émojis 📖 and symbols: @#\$%');
    });
  });
}
