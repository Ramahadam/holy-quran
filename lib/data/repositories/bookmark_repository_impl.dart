import 'package:isar/isar.dart';

import '../../domain/models/bookmark.dart';
import '../local/entities/bookmark_entity.dart';
import '../local/isar_service.dart';
import 'bookmark_repository.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  @override
  Future<void> addBookmark(String verseId, DateTime timestamp) async {
    final isar = await IsarService.getInstance();
    final entity = BookmarkEntity.fromDomain(
      Bookmark(verseId: verseId, timestamp: timestamp),
    );
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
  Future<bool> isBookmarked(String verseId) async {
    final isar = await IsarService.getInstance();
    final entity = await isar.bookmarkEntitys.getByVerseId(verseId);
    return entity != null;
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
  Future<int> getBookmarkCount() async {
    final isar = await IsarService.getInstance();
    return isar.bookmarkEntitys.count();
  }
}
