import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reading_position_repository.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/reading_position.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/verse_card.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  final Surah surah;

  const ReadingScreen({super.key, required this.surah});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  String? _lastVisibleVerseId;
  late final ReadingPositionRepository _positionRepo;

  @override
  void initState() {
    super.initState();
    _positionRepo = ref.read(readingPositionRepositoryProvider);
  }

  @override
  void dispose() {
    _saveReadingPosition();
    super.dispose();
  }

  void _saveReadingPosition() {
    final verseId = _lastVisibleVerseId;
    if (verseId == null) return;
    _positionRepo.savePosition(
      ReadingPosition(verseId: verseId, lastReadAt: DateTime.now()),
    );
  }

  Future<void> _toggleBookmark(Verse verse, Set<String> bookmarked) async {
    final repo = ref.read(bookmarkRepositoryProvider);
    if (bookmarked.contains(verse.verseId)) {
      await repo.removeBookmark(verse.verseId);
    } else {
      await repo.addBookmark(
        Bookmark(verseId: verse.verseId, timestamp: DateTime.now()),
      );
    }
    ref.invalidate(bookmarksBySurahProvider(widget.surah.surahNumber));
  }

  @override
  Widget build(BuildContext context) {
    final versesAsync = ref.watch(versesBySurahProvider(widget.surah.surahNumber));
    final bookmarksAsync =
        ref.watch(bookmarksBySurahProvider(widget.surah.surahNumber));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.surah.nameArabic,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.islamicGreen,
                  ),
              textDirection: TextDirection.rtl,
            ),
            Text(
              widget.surah.nameEnglish,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: versesAsync.when(
        data: (verses) {
          final bookmarked = bookmarksAsync.valueOrNull ?? {};
          return NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) {
              final ctx = notification.context;
              if (ctx != null && verses.isNotEmpty) {
                final index = _estimateVisibleIndex(
                    notification.metrics, verses.length);
                if (index >= 0 && index < verses.length) {
                  _lastVisibleVerseId = verses[index].verseId;
                }
              }
              return false;
            },
            child: ListView.builder(
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final verse = verses[index];
                if (_lastVisibleVerseId == null && index == 0) {
                  _lastVisibleVerseId = verse.verseId;
                }
                return VerseCard(
                  verse: verse,
                  isBookmarked: bookmarked.contains(verse.verseId),
                  onBookmarkToggle: () => _toggleBookmark(verse, bookmarked),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.islamicGreen),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load verses.\nPlease restart the app.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  int _estimateVisibleIndex(ScrollMetrics metrics, int itemCount) {
    if (metrics.maxScrollExtent <= 0) return 0;
    final fraction = metrics.pixels / metrics.maxScrollExtent;
    return (fraction * (itemCount - 1)).round().clamp(0, itemCount - 1);
  }
}
