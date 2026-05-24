abstract class BookmarkRepository {
  Future<void> addBookmark(String verseId, DateTime timestamp);

  Future<void> removeBookmark(String verseId);

  Future<bool> isBookmarked(String verseId);

  Future<Set<String>> getBookmarkedVerseIdsBySurah(int surahNumber);

  Future<int> getBookmarkCount();
}
