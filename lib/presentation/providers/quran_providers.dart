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

final lastReadPositionProvider = FutureProvider<ReadingPosition?>((ref) async {
  return ref.read(readingPositionRepositoryProvider).getLastPosition();
});

final bookmarksBySurahProvider =
    FutureProvider.family<Set<String>, int>((ref, surahNumber) async {
  final bookmarks = await ref
      .read(bookmarkRepositoryProvider)
      .getBookmarksBySurah(surahNumber);
  return bookmarks.map((b) => b.verseId).toSet();
});
