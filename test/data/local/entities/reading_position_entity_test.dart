import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';
import 'package:holy_quran_app/data/local/entities/reading_position_entity.dart';

void main() {
  group('ReadingPositionEntity', () {
    final testDate = DateTime(2024, 1, 1, 10, 30);

    test('fromDomain converts domain model to entity', () {
      final position = ReadingPosition(
        verseId: '2:255',
        lastReadAt: testDate,
      );

      final entity = ReadingPositionEntity.fromDomain(position);

      expect(entity.verseId, '2:255');
      expect(entity.lastReadAt, testDate);
    });

    test('toDomain converts entity to domain model', () {
      final entity = ReadingPositionEntity()
        ..verseId = '18:110'
        ..lastReadAt = testDate;

      final position = entity.toDomain();

      expect(position.verseId, '18:110');
      expect(position.lastReadAt, testDate);
    });

    test('roundtrip conversion preserves all data', () {
      final original = ReadingPosition(
        verseId: '114:6',
        lastReadAt: testDate,
      );

      final entity = ReadingPositionEntity.fromDomain(original);
      final result = entity.toDomain();

      expect(result, equals(original));
      expect(result.verseId, original.verseId);
      expect(result.lastReadAt, original.lastReadAt);
    });

    test('handles timestamp precision correctly', () {
      final preciseTime = DateTime(2024, 12, 31, 23, 59, 59, 999, 999);
      final position = ReadingPosition(
        verseId: '1:1',
        lastReadAt: preciseTime,
      );

      final entity = ReadingPositionEntity.fromDomain(position);
      final result = entity.toDomain();

      expect(result.lastReadAt, preciseTime);
      expect(result.lastReadAt.microsecond, 999);
    });

    test('handles different verseId formats', () {
      final testCases = [
        '1:1', // First verse
        '2:286', // Last verse of Al-Baqarah
        '114:6', // Last verse of Quran
        '18:109', // Random verse
      ];

      for (final verseId in testCases) {
        final position = ReadingPosition(
          verseId: verseId,
          lastReadAt: testDate,
        );

        final entity = ReadingPositionEntity.fromDomain(position);
        final result = entity.toDomain();

        expect(result.verseId, verseId, reason: 'Failed for verseId: $verseId');
      }
    });

    test('handles empty verseId', () {
      final position = ReadingPosition(
        verseId: '',
        lastReadAt: testDate,
      );

      final entity = ReadingPositionEntity.fromDomain(position);
      final result = entity.toDomain();

      expect(result.verseId, '');
    });

    test('handles various timestamp values', () {
      final timestamps = [
        DateTime(2024, 1, 1), // Start of year
        DateTime(2024, 12, 31, 23, 59, 59), // End of year
        DateTime.now(), // Current time
        DateTime(1970, 1, 1), // Unix epoch
      ];

      for (final timestamp in timestamps) {
        final position = ReadingPosition(
          verseId: '1:1',
          lastReadAt: timestamp,
        );

        final entity = ReadingPositionEntity.fromDomain(position);
        final result = entity.toDomain();

        expect(result.lastReadAt, timestamp);
      }
    });

    test('unique index ensures one position per verse', () {
      // This is a documentation test - the unique index is enforced
      // by Isar at the database level, not the mapper
      final position1 = ReadingPosition(
        verseId: '1:1',
        lastReadAt: testDate,
      );

      final laterDate = testDate.add(const Duration(days: 1));
      final position2 = ReadingPosition(
        verseId: '1:1',
        lastReadAt: laterDate,
      );

      final entity1 = ReadingPositionEntity.fromDomain(position1);
      final entity2 = ReadingPositionEntity.fromDomain(position2);

      // Both entities have same verseId
      expect(entity1.verseId, entity2.verseId);
      // But different timestamps
      expect(entity1.lastReadAt, isNot(equals(entity2.lastReadAt)));
      // Database unique index would replace entity1 with entity2
    });
  });
}
