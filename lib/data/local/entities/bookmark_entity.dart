import 'package:isar/isar.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';

part 'bookmark_entity.g.dart';

@Name('BookmarkEntity_web_1206')
@collection
class BookmarkEntity {
  Id id = Isar.autoIncrement;

  @Index(name: 'verseId_web_3661', unique: true, replace: true)
  late String verseId;

  @Index(name: 'surahNumber_web_46')
  late int surahNumber;

  late DateTime timestamp;
  String? note;

  BookmarkEntity();

  BookmarkEntity.fromDomain(Bookmark bookmark) {
    verseId = bookmark.verseId;
    surahNumber = int.tryParse(bookmark.verseId.split(':').first) ?? 0;
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
