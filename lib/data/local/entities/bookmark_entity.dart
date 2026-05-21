import 'package:isar/isar.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';

part 'bookmark_entity.g.dart';

/// Isar database entity for Bookmark model.
/// Auto-increment ID for database management.
@collection
class BookmarkEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String verseId;

  late DateTime timestamp;
  String? note;

  BookmarkEntity();

  /// Create entity from domain model
  BookmarkEntity.fromDomain(Bookmark bookmark) {
    verseId = bookmark.verseId;
    timestamp = bookmark.timestamp;
    note = bookmark.note;
  }

  /// Convert entity to domain model
  Bookmark toDomain() {
    return Bookmark(
      verseId: verseId,
      timestamp: timestamp,
      note: note,
    );
  }
}
