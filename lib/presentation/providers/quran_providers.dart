import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepositoryImpl();
});

final dataLoadedProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(quranRepositoryProvider);
  return repo.isDataLoaded();
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
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getVersesBySurah(surahNumber);
});
