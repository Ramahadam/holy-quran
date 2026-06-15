import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/backup/quran_backup_codec.dart';
import '../../data/backup/quran_backup_file_service.dart';
import '../../data/backup/quran_backup_service.dart';
import '../../data/feedback/anonymous_feedback_service.dart';
import '../../data/feedback/feedback_prompt_service.dart';
import '../../data/repositories/bookmark_repository.dart';
import '../../data/repositories/bookmark_repository_impl.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../data/repositories/reading_position_repository.dart';
import '../../data/repositories/reading_position_repository_impl.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/reading_position.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String projectUrl = String.fromEnvironment('PROJECT_URL');
const String supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);
const String publishableKey = String.fromEnvironment('PUBLISHABLE_KEY');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

String get configuredSupabaseUrl =>
    supabaseUrl.isNotEmpty ? supabaseUrl : projectUrl;

String get configuredSupabaseKey => supabasePublishableKey.isNotEmpty
    ? supabasePublishableKey
    : publishableKey.isNotEmpty
    ? publishableKey
    : supabaseAnonKey;

bool get isSupabaseFeedbackConfigured =>
    configuredSupabaseUrl.isNotEmpty && configuredSupabaseKey.isNotEmpty;

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepositoryImpl();
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepositoryImpl();
});

final readingPositionRepositoryProvider = Provider<ReadingPositionRepository>((
  ref,
) {
  return ReadingPositionRepositoryImpl();
});

final quranBackupCodecProvider = Provider<QuranBackupCodec>((ref) {
  return QuranBackupCodec();
});

final quranBackupServiceProvider = Provider<QuranBackupService>((ref) {
  return QuranBackupService(
    bookmarkRepository: ref.watch(bookmarkRepositoryProvider),
    readingPositionRepository: ref.watch(readingPositionRepositoryProvider),
    codec: ref.watch(quranBackupCodecProvider),
  );
});

final quranBackupFileServiceProvider = Provider<QuranBackupFileService>((ref) {
  return QuranBackupFileService(
    backupService: ref.watch(quranBackupServiceProvider),
  );
});

final anonymousFeedbackServiceProvider = Provider<AnonymousFeedbackService>((
  ref,
) {
  final transport = isSupabaseFeedbackConfigured
      ? SupabaseFeedbackTransport(client: Supabase.instance.client)
      : const UnconfiguredFeedbackTransport();
  return AnonymousFeedbackService(transport: transport);
});

final feedbackPromptStoreProvider = Provider<FeedbackPromptStore>((ref) {
  return SharedPreferencesFeedbackPromptStore();
});

final feedbackPromptServiceProvider = Provider<FeedbackPromptController>((ref) {
  try {
    return FeedbackPromptService(store: ref.watch(feedbackPromptStoreProvider));
  } catch (_) {
    return const DisabledFeedbackPromptController();
  }
});

final feedbackPromptShouldShowProvider = FutureProvider<bool>((ref) {
  return ref.watch(feedbackPromptServiceProvider).shouldPrompt();
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

final versesBySurahProvider = FutureProvider.family<List<Verse>, int>((
  ref,
  surahNumber,
) async {
  await ref.watch(initializeDataProvider.future);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getVersesBySurah(surahNumber);
});

final versesByPageProvider = FutureProvider.family<List<Verse>, int>((
  ref,
  page,
) async {
  await ref.watch(initializeDataProvider.future);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getVersesByPage(page);
});

final startPageForSurahProvider = FutureProvider.family<int, int>((
  ref,
  surahNumber,
) async {
  await ref.watch(initializeDataProvider.future);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getStartPageForSurah(surahNumber);
});

final pageForVerseProvider = FutureProvider.family<int, String>((
  ref,
  verseId,
) async {
  await ref.watch(initializeDataProvider.future);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getPageForVerse(verseId);
});

final lastReadPositionProvider = FutureProvider<ReadingPosition?>((ref) async {
  return ref.watch(readingPositionRepositoryProvider).getLastPosition();
});

final recentBookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {
  return ref.watch(bookmarkRepositoryProvider).getRecentBookmarks();
});

final bookmarksBySurahProvider = FutureProvider.family<Set<String>, int>((
  ref,
  surahNumber,
) async {
  return ref
      .watch(bookmarkRepositoryProvider)
      .getBookmarkedVerseIdsBySurah(surahNumber);
});
