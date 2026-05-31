import 'package:isar/isar.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';

part 'reading_position_entity.g.dart';

/// Isar database entity for ReadingPosition model.
/// Singleton: exactly one row ever exists, always written at id=1 by the
/// repository. No secondary index needed — all access is by fixed primary key.
@collection
class ReadingPositionEntity {
  Id id = Isar.autoIncrement;

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
    return ReadingPosition(verseId: verseId, lastReadAt: lastReadAt);
  }
}
