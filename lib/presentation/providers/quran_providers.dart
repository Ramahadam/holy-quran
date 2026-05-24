import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/bookmark_repository.dart';
import '../../data/repositories/bookmark_repository_impl.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../data/repositories/reading_position_repository.dart';
import '../../data/repositories/reading_position_repository_impl.dart';
import '../../domain/models/reading_position.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepositoryImpl();
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepositoryImpl();
});

final readingPositionRepositoryProvider =
    Provider<ReadingPositionRepository>((ref) {
  return ReadingPositionRepositoryImpl();
});

final initializeDataProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(quranRepositoryProvider);
  await repo.loadQuranData();
});

final surahListProvider = FutureProvider<List<Surah>>((ref) async {
  await ref.watch(initializeDataProvider.future);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getAllSurahs();
});

final versesBySurahProvider =
    FutureProvider.family<List<Verse>, int>((ref, surahNumber) async {
  await ref.watch(initializeDataProvider.future);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getVersesBySurah(surahNumber);
});

final versesByPageProvider =
    FutureProvider.family<List<Verse>, int>((ref, page) async {
  await ref.watch(initializeDataProvider.future);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getVersesByPage(page);
});

final startPageForSurahProvider =
    FutureProvider.family<int, int>((ref, surahNumber) async {
  await ref.watch(initializeDataProvider.future);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getStartPageForSurah(surahNumber);
});

final pageForVerseProvider =
    FutureProvider.family<int, String>((ref, verseId) async {
  await ref.watch(initializeDataProvider.future);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getPageForVerse(verseId);
});

final lastReadPositionProvider = FutureProvider<ReadingPosition?>((ref) async {
  return ref.watch(readingPositionRepositoryProvider).getLastPosition();
});

final bookmarksBySurahProvider =
    FutureProvider.family<Set<String>, int>((ref, surahNumber) async {
  return ref
      .watch(bookmarkRepositoryProvider)
      .getBookmarkedVerseIdsBySurah(surahNumber);
});
