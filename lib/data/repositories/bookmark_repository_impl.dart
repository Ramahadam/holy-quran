import 'package:isar/isar.dart';

import '../../domain/models/bookmark.dart';
import '../local/entities/bookmark_entity.dart';
import '../local/isar_service.dart';
import 'bookmark_repository.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.bookmarkEntitys.put(BookmarkEntity.fromDomain(bookmark));
    });
  }

  @override
  Future<void> removeBookmark(String verseId) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.bookmarkEntitys.filter().verseIdEqualTo(verseId).deleteAll();
    });
  }

  @override
  Future<bool> isBookmarked(String verseId) async {
    final isar = await IsarService.getInstance();
    final count =
        await isar.bookmarkEntitys.filter().verseIdEqualTo(verseId).count();
    return count > 0;
  }

  @override
  Future<List<Bookmark>> getBookmarksBySurah(int surahNumber) async {
    final isar = await IsarService.getInstance();
    final prefix = '$surahNumber:';
    final entities = await isar.bookmarkEntitys
        .filter()
        .verseIdStartsWith(prefix)
        .findAll();
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Bookmark>> getAllBookmarks() async {
    final isar = await IsarService.getInstance();
    final entities = await isar.bookmarkEntitys.where().findAll();
    return entities.map((e) => e.toDomain()).toList();
  }
}
