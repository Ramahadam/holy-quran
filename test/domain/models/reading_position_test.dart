import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';

void main() {
  group('ReadingPosition', () {
    final testDate = DateTime(2024, 1, 1, 10, 30);

    test('creates instance with required fields', () {
      final position = ReadingPosition(
        verseId: '1:1',
        lastReadAt: testDate,
      );

      expect(position.verseId, '1:1');
      expect(position.lastReadAt, testDate);
    });

    test('equality requires both verseId and lastReadAt to match', () {
      final position1 = ReadingPosition(
        verseId: '1:1',
        lastReadAt: testDate,
      );
      final positionSameVerseDifferentTime = ReadingPosition(
        verseId: '1:1',
        lastReadAt: DateTime(2024, 2, 1),
      );
      final positionSameTimeDifferentVerse = ReadingPosition(
        verseId: '2:1',
        lastReadAt: testDate,
      );
      final positionIdentical = ReadingPosition(
        verseId: '1:1',
        lastReadAt: testDate,
      );

      expect(position1, equals(positionIdentical));
      expect(position1, isNot(equals(positionSameVerseDifferentTime)));
      expect(position1, isNot(equals(positionSameTimeDifferentVerse)));
    });

    test('hashCode includes both verseId and lastReadAt', () {
      final position1 = ReadingPosition(verseId: '1:1', lastReadAt: testDate);
      final positionIdentical = ReadingPosition(verseId: '1:1', lastReadAt: testDate);
      final positionDifferentTime = ReadingPosition(
        verseId: '1:1',
        lastReadAt: DateTime(2024, 2, 1),
      );

      expect(position1.hashCode, equals(positionIdentical.hashCode));
      expect(position1.hashCode, isNot(equals(positionDifferentTime.hashCode)));
    });

    test('handles different verseId formats', () {
      // Standard format
      final position1 = ReadingPosition(
        verseId: '1:1',
        lastReadAt: testDate,
      );
      expect(position1.verseId, '1:1');

      // Last verse of Al-Baqarah
      final position2 = ReadingPosition(
        verseId: '2:286',
        lastReadAt: testDate,
      );
      expect(position2.verseId, '2:286');

      // Last surah
      final position3 = ReadingPosition(
        verseId: '114:6',
        lastReadAt: testDate,
      );
      expect(position3.verseId, '114:6');
    });

    test('handles different timestamps', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));

      final position1 = ReadingPosition(
        verseId: '1:1',
        lastReadAt: now,
      );
      final position2 = ReadingPosition(
        verseId: '1:2',
        lastReadAt: yesterday,
      );
      final position3 = ReadingPosition(
        verseId: '1:3',
        lastReadAt: lastWeek,
      );

      expect(position1.lastReadAt, now);
      expect(position2.lastReadAt, yesterday);
      expect(position3.lastReadAt, lastWeek);
    });

    test('handles edge case verseIds', () {
      // Empty string (should be allowed, validation can be added later)
      final positionEmpty = ReadingPosition(
        verseId: '',
        lastReadAt: testDate,
      );
      expect(positionEmpty.verseId, '');

      // Very long verseId
      final positionLong = ReadingPosition(
        verseId: '114:6:extra:data',
        lastReadAt: testDate,
      );
      expect(positionLong.verseId, '114:6:extra:data');
    });
  });
}
