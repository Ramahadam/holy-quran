import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reading_position_repository.dart';
import '../../domain/models/reading_position.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/verse_card.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  final Surah surah;

  /// When set, the list jumps to this verse on first load.
  /// Used by the "Continue Reading" banner to resume at the saved position.
  final String? initialVerseId;

  const ReadingScreen({super.key, required this.surah, this.initialVerseId});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  String? _lastVisibleVerseId;
  bool _didScrollToInitial = false;

  late final ScrollController _scrollController;

  // Repository is stateless — captured once to allow calling it safely in
  // deactivate(), before ref becomes unavailable.
  late final ReadingPositionRepository _positionRepo;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _positionRepo = ref.read(readingPositionRepositoryProvider);
  }

  @override
  void deactivate() {
    // deactivate() fires before the widget leaves the tree, so ref is still
    // live here — this is the correct place to invalidate providers on pop.
    _saveReadingPosition();
    if (mounted) ref.invalidate(lastReadPositionProvider);
    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _saveReadingPosition() {
    final verseId = _lastVisibleVerseId;
    if (verseId == null) return;
    _positionRepo
        .savePosition(ReadingPosition(verseId: verseId, lastReadAt: DateTime.now()))
        .catchError((Object e) {
      debugPrint('Failed to save reading position: $e');
    });
  }

  void _scrollToInitialVerse(List<Verse> verses) {
    if (_didScrollToInitial) return;
    final target = widget.initialVerseId;
    if (target == null) return;

    final index = verses.indexWhere((v) => v.verseId == target);
    if (index <= 0) return; // already at top

    _didScrollToInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) return;
      // Use the same fractional mapping as _estimateVisibleIndex (inverse).
      final fraction = index / (verses.length - 1);
      _scrollController.jumpTo(fraction * maxExtent);
    });
  }

  Future<void> _toggleBookmark(Verse verse, Set<String> bookmarked) async {
    final repo = ref.read(bookmarkRepositoryProvider);
    final wasBookmarked = bookmarked.contains(verse.verseId);
    if (wasBookmarked) {
      await repo.removeBookmark(verse.verseId);
    } else {
      await repo.addBookmark(verse.verseId, DateTime.now());
    }
    ref.invalidate(bookmarksBySurahProvider(widget.surah.surahNumber));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasBookmarked ? 'Bookmark removed' : 'Bookmarked'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          // Seed the position with the first verse when data arrives so that
          // navigating away without scrolling still records a valid position.
          _lastVisibleVerseId ??= verses.isNotEmpty ? verses.first.verseId : null;

          _scrollToInitialVerse(verses);

          final bookmarked = bookmarksAsync.valueOrNull ?? {};
          return NotificationListener<ScrollEndNotification>(
            onNotification: (notification) {
              if (verses.isNotEmpty) {
                // NOTE: pixel-fraction estimation assumes uniform row heights.
                // Actual verse heights vary; this is intentionally approximate.
                final index = _estimateVisibleIndex(
                    notification.metrics, verses.length);
                _lastVisibleVerseId = verses[index].verseId;
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final verse = verses[index];
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
