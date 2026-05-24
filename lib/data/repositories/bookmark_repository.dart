import '../../domain/models/bookmark.dart';

abstract class BookmarkRepository {
  Future<void> addBookmark(Bookmark bookmark);

  Future<void> removeBookmark(String verseId);

  Future<bool> isBookmarked(String verseId);

  Future<List<Bookmark>> getBookmarksBySurah(int surahNumber);

  Future<List<Bookmark>> getAllBookmarks();
}
