import 'package:isar/isar.dart';

import '../../domain/models/bookmark.dart';
import '../local/entities/bookmark_entity.dart';
import '../local/isar_service.dart';
import 'bookmark_repository.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  @override
  Future<void> addBookmark(String verseId, DateTime timestamp) async {
    await saveBookmark(Bookmark(verseId: verseId, timestamp: timestamp));
  }

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {
    final isar = await IsarService.getInstance();
    final entity = BookmarkEntity.fromDomain(bookmark);
    await isar.writeTxn(() async {
      await isar.bookmarkEntitys.putByVerseId(entity);
    });
  }

  @override
  Future<void> removeBookmark(String verseId) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.bookmarkEntitys.deleteByVerseId(verseId);
    });
  }

  @override
  Future<List<Bookmark>> getAllBookmarks() async {
    final isar = await IsarService.getInstance();
    final entities = await isar.bookmarkEntitys
        .where()
        .sortByTimestampDesc()
        .findAll();
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Bookmark>> getRecentBookmarks({int limit = 3}) async {
    final isar = await IsarService.getInstance();
    final entities = await isar.bookmarkEntitys
        .where()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<Set<String>> getBookmarkedVerseIdsBySurah(int surahNumber) async {
    final isar = await IsarService.getInstance();
    final entities = await isar.bookmarkEntitys
        .filter()
        .surahNumberEqualTo(surahNumber)
        .findAll();
    return entities.map((e) => e.verseId).toSet();
  }

  @override
  Future<void> replaceAllBookmarks(List<Bookmark> bookmarks) async {
    final isar = await IsarService.getInstance();
    final entities = bookmarks.map(BookmarkEntity.fromDomain).toList();
    await isar.writeTxn(() async {
      await isar.bookmarkEntitys.clear();
      await isar.bookmarkEntitys.putAllByVerseId(entities);
    });
  }
}
