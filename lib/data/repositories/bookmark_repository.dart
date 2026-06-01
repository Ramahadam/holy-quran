import '../../domain/models/bookmark.dart';

abstract class BookmarkRepository {
  Future<void> addBookmark(String verseId, DateTime timestamp);

  Future<void> saveBookmark(Bookmark bookmark);

  Future<void> removeBookmark(String verseId);

  Future<List<Bookmark>> getAllBookmarks();

  Future<List<Bookmark>> getRecentBookmarks({int limit = 3});

  Future<Set<String>> getBookmarkedVerseIdsBySurah(int surahNumber);

  Future<void> replaceAllBookmarks(List<Bookmark> bookmarks);
}
