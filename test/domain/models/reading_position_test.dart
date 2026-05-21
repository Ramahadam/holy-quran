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

    test('equality based on verseId', () {
      final position1 = ReadingPosition(
        verseId: '1:1',
        lastReadAt: testDate,
      );
      final position2 = ReadingPosition(
        verseId: '1:1',
        lastReadAt: DateTime(2024, 2, 1),
      );
      final position3 = ReadingPosition(
        verseId: '2:1',
        lastReadAt: testDate,
      );

      expect(position1, equals(position2));
      expect(position1, isNot(equals(position3)));
    });

    test('hashCode based on verseId', () {
      final position1 = ReadingPosition(
        verseId: '1:1',
        lastReadAt: testDate,
      );
      final position2 = ReadingPosition(
        verseId: '1:1',
        lastReadAt: DateTime(2024, 2, 1),
      );

      expect(position1.hashCode, equals(position2.hashCode));
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
