import 'package:isar/isar.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';

part 'reading_position_entity.g.dart';

/// Isar database entity for ReadingPosition model.
/// Unique index on verseId ensures only one reading position per verse.
@collection
class ReadingPositionEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String verseId;

  late DateTime lastReadAt;

  ReadingPositionEntity();

  /// Create entity from domain model
  ReadingPositionEntity.fromDomain(ReadingPosition position) {
    verseId = position.verseId;
    lastReadAt = position.lastReadAt;
  }

  /// Convert entity to domain model
  ReadingPosition toDomain() {
    return ReadingPosition(
      verseId: verseId,
      lastReadAt: lastReadAt,
    );
  }
}
