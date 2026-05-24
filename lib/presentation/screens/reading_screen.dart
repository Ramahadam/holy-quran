import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reading_position_repository.dart';
import '../../domain/models/reading_position.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';

const _totalPages = 604;

class ReadingScreen extends ConsumerStatefulWidget {
  final Surah surah;
  final String? initialVerseId;

  const ReadingScreen({super.key, required this.surah, this.initialVerseId});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  PageController? _pageController;
  int _currentPage = 1;
  bool _resolved = false;

  late final ReadingPositionRepository _positionRepo;

  @override
  void initState() {
    super.initState();
    _positionRepo = ref.read(readingPositionRepositoryProvider);
  }

  @override
  void deactivate() {
    _saveReadingPosition();
    if (mounted) ref.invalidate(lastReadPositionProvider);
    super.deactivate();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _saveReadingPosition() {
    // Save the first verse on the current page as the reading position.
    final verseId = '${widget.surah.surahNumber}:1';
    // We'll use a more precise verseId from _currentPageFirstVerse if available.
    final id = _currentPageFirstVerseId ?? verseId;
    _positionRepo
        .savePosition(ReadingPosition(verseId: id, lastReadAt: DateTime.now()))
        .catchError((Object e) {
      debugPrint('Failed to save reading position: $e');
    });
  }

  String? _currentPageFirstVerseId;

  void _initPageController(int startPage) {
    if (_resolved) return;
    _resolved = true;
    _currentPage = startPage;
    _pageController = PageController(initialPage: startPage - 1);
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the starting page.
    if (!_resolved) {
      if (widget.initialVerseId != null) {
        final pageAsync = ref.watch(pageForVerseProvider(widget.initialVerseId!));
        return pageAsync.when(
          data: (page) {
            _initPageController(page);
            return _buildPageView();
          },
          loading: () => _buildLoading(),
          error: (_, __) {
            // Fallback: start at surah's first page.
            final startAsync =
                ref.watch(startPageForSurahProvider(widget.surah.surahNumber));
            return startAsync.when(
              data: (page) {
                _initPageController(page);
                return _buildPageView();
              },
              loading: () => _buildLoading(),
              error: (_, __) {
                _initPageController(1);
                return _buildPageView();
              },
            );
          },
        );
      } else {
        final startAsync =
            ref.watch(startPageForSurahProvider(widget.surah.surahNumber));
        return startAsync.when(
          data: (page) {
            _initPageController(page);
            return _buildPageView();
          },
          loading: () => _buildLoading(),
          error: (_, __) {
            _initPageController(1);
            return _buildPageView();
          },
        );
      }
    }
    return _buildPageView();
  }

  Widget _buildLoading() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: const Center(
        child: CircularProgressIndicator(color: AppTheme.islamicGreen),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        children: [
          Text(
            'القرآن الكريم',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.islamicGreen,
                ),
            textDirection: TextDirection.rtl,
          ),
          Text(
            'Page $_currentPage',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: PageView.builder(
        controller: _pageController,
        reverse: true,
        itemCount: _totalPages,
        onPageChanged: (index) {
          final pageNum = index + 1;
          _currentPage = pageNum;
          _currentPageFirstVerseId = null;
          setState(() {});
        },
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          return _QuranPage(
            key: ValueKey(pageNum),
            page: pageNum,
            onFirstVerseResolved: pageNum == _currentPage
                ? (verseId) => _currentPageFirstVerseId ??= verseId
                : null,
          );
        },
      ),
    );
  }
}

class _QuranPage extends ConsumerStatefulWidget {
  final int page;
  final ValueChanged<String>? onFirstVerseResolved;

  const _QuranPage({super.key, required this.page, this.onFirstVerseResolved});

  @override
  ConsumerState<_QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends ConsumerState<_QuranPage> {
  bool _didResolve = false;

  @override
  Widget build(BuildContext context) {
    final versesAsync = ref.watch(versesByPageProvider(widget.page));

    return versesAsync.when(
      data: (verses) {
        if (verses.isEmpty) {
          return const Center(child: Text('No verses on this page.'));
        }

        if (!_didResolve && widget.onFirstVerseResolved != null) {
          _didResolve = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onFirstVerseResolved?.call(verses.first.verseId);
          });
        }

        final surahNumbers = verses.map((v) => v.surahNumber).toSet();

        return _QuranPageContent(
          verses: verses,
          page: widget.page,
          surahNumbers: surahNumbers,
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
    );
  }
}

class _QuranPageContent extends ConsumerWidget {
  final List<Verse> verses;
  final int page;
  final Set<int> surahNumbers;

  const _QuranPageContent({
    required this.verses,
    required this.page,
    required this.surahNumbers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Collect bookmarks for all surahs on this page.
    final Set<String> allBookmarks = {};
    for (final surahNum in surahNumbers) {
      final bm = ref.watch(bookmarksBySurahProvider(surahNum));
      final set = bm.valueOrNull;
      if (set != null) allBookmarks.addAll(set);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildVerseWidgets(context, ref, allBookmarks),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$page',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVerseWidgets(
      BuildContext context, WidgetRef ref, Set<String> bookmarks) {
    final widgets = <Widget>[];
    int? lastSurah;

    for (final verse in verses) {
      // Show surah header when the surah changes within a page.
      if (verse.surahNumber != lastSurah) {
        if (lastSurah != null) {
          widgets.add(const SizedBox(height: 16));
        }
        widgets.add(_SurahHeader(surahNumber: verse.surahNumber));
        lastSurah = verse.surahNumber;
      }

      final isBookmarked = bookmarks.contains(verse.verseId);
      widgets.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => _toggleBookmark(context, ref, verse, bookmarks),
          child: _ArabicVerse(
            verse: verse,
            isBookmarked: isBookmarked,
          ),
        ),
      );
    }

    return widgets;
  }

  Future<void> _toggleBookmark(BuildContext context, WidgetRef ref, Verse verse,
      Set<String> bookmarks) async {
    final repo = ref.read(bookmarkRepositoryProvider);
    final wasBookmarked = bookmarks.contains(verse.verseId);
    if (wasBookmarked) {
      await repo.removeBookmark(verse.verseId);
    } else {
      await repo.addBookmark(verse.verseId, DateTime.now());
    }
    ref.invalidate(bookmarksBySurahProvider(verse.surahNumber));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasBookmarked ? 'Bookmark removed' : 'Bookmarked'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SurahHeader extends ConsumerWidget {
  final int surahNumber;

  const _SurahHeader({required this.surahNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahListProvider);
    final surahName = surahAsync.whenOrNull(
      data: (surahs) =>
          surahs.where((s) => s.surahNumber == surahNumber).firstOrNull?.nameArabic,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.divider),
          top: BorderSide(color: AppTheme.divider),
        ),
      ),
      child: Center(
        child: Text(
          surahName ?? 'سورة $surahNumber',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.islamicGreen,
                fontWeight: FontWeight.w600,
              ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

class _ArabicVerse extends StatelessWidget {
  final Verse verse;
  final bool isBookmarked;

  const _ArabicVerse({required this.verse, this.isBookmarked = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                height: 2.2,
                color: isBookmarked ? AppTheme.islamicGreen : AppTheme.textPrimary,
              ),
          children: [
            TextSpan(text: verse.arabicText),
            TextSpan(
              text: ' ۝${_toArabicNumeral(verse.verseNumber)} ',
              style: TextStyle(
                color: AppTheme.goldAccent,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _toArabicNumeral(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }
}
