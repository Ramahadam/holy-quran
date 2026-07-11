import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';

abstract class QuranRepository {
  Future<void> loadQuranData();

  Future<List<Verse>> getVersesBySurah(int surahNumber);

  Future<List<Verse>> getAllVerses();

  Future<List<Verse>> getVersesByPage(int page);

  Future<Verse?> getVerseById(String verseId);

  Future<List<Surah>> getAllSurahs();

  Future<Surah?> getSurahByNumber(int surahNumber);

  Future<bool> isDataLoaded();

  Future<int> getPageForVerse(String verseId);

  Future<int> getStartPageForSurah(int surahNumber);
}
