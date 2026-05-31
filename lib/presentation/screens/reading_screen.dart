import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reading_position_repository.dart';
import '../../domain/models/reading_position.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import 'verse_detail_screen.dart';
import '../widgets/mushaf_sample_page.dart';

const _kfgqpcHafsFontFamily = 'KFGQPCHafsUthmanicScript';
const _totalPages = 604;

enum ReadingMode { classic, mushaf }

void _openVerseDetail(BuildContext context, Verse verse) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => VerseDetailScreen(verse: verse),
    ),
  );
}

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
  ReadingMode _readingMode = ReadingMode.classic;
  bool _showMushafControls = false;

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
        final pageAsync = ref.watch(
          pageForVerseProvider(widget.initialVerseId!),
        );
        return pageAsync.when(
          data: (page) {
            _initPageController(page);
            return _buildPageView();
          },
          loading: () => _buildLoading(),
          error: (_, _) {
            // Fallback: start at surah's first page.
            final startAsync = ref.watch(
              startPageForSurahProvider(widget.surah.surahNumber),
            );
            return startAsync.when(
              data: (page) {
                _initPageController(page);
                return _buildPageView();
              },
              loading: () => _buildLoading(),
              error: (_, _) {
                _initPageController(1);
                return _buildPageView();
              },
            );
          },
        );
      } else {
        final startAsync = ref.watch(
          startPageForSurahProvider(widget.surah.surahNumber),
        );
        return startAsync.when(
          data: (page) {
            _initPageController(page);
            return _buildPageView();
          },
          loading: () => _buildLoading(),
          error: (_, _) {
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.islamicGreen),
            textDirection: TextDirection.rtl,
          ),
          Text(
            'Page $_currentPage',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SegmentedButton<ReadingMode>(
            showSelectedIcon: false,
            selected: {_readingMode},
            segments: const [
              ButtonSegment(
                value: ReadingMode.classic,
                icon: Icon(Icons.menu_book),
                label: Text('Classic'),
              ),
              ButtonSegment(
                value: ReadingMode.mushaf,
                icon: Icon(Icons.image_outlined),
                label: Text('Mushaf'),
              ),
            ],
            onSelectionChanged: (selection) {
              final mode = selection.single;
              setState(() {
                _readingMode = mode;
                _showMushafControls = false;
              });
            },
          ),
        ),
      ),
    );
  }

  void _setImmersiveMode(bool immersive) {
    if (immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Widget _buildPageView() {
    final showAppBar =
        _readingMode == ReadingMode.classic || _showMushafControls;
    final isMushafImmersive =
        _readingMode == ReadingMode.mushaf && !_showMushafControls;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setImmersiveMode(isMushafImmersive);
    });

    final pageView = PageView.builder(
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
          readingMode: _readingMode,
          onFirstVerseResolved: pageNum == _currentPage
              ? (verseId) => _currentPageFirstVerseId ??= verseId
              : null,
          onVerseHit: pageNum == _currentPage
              ? (verseId) => _currentPageFirstVerseId = verseId
              : null,
        );
      },
    );

    return Scaffold(
      appBar: showAppBar ? _buildAppBar() : null,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_readingMode == ReadingMode.mushaf && _showMushafControls) {
                setState(() {
                  _showMushafControls = false;
                });
              }
            },
            child: pageView,
          ),
          if (isMushafImmersive)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 56,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _showMushafControls = true;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _QuranPage extends ConsumerStatefulWidget {
  final int page;
  final ReadingMode readingMode;
  final ValueChanged<String>? onFirstVerseResolved;
  final ValueChanged<String>? onVerseHit;

  const _QuranPage({
    super.key,
    required this.page,
    required this.readingMode,
    this.onFirstVerseResolved,
    this.onVerseHit,
  });

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

        if (widget.readingMode == ReadingMode.mushaf) {
          return MushafSamplePage(
            page: widget.page,
            onVerseTap: (verseId) {
              widget.onVerseHit?.call(verseId);
              final verse = verses
                  .where((verse) => verse.verseId == verseId)
                  .firstOrNull;
              if (verse != null) {
                _openVerseDetail(context, verse);
              }
            },
          );
        }

        return _QuranPageContent(
          verses: verses,
          page: widget.page,
          surahNumbers: surahNumbers,
          onVerseFocused: widget.onVerseHit,
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.red),
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
  final ValueChanged<String>? onVerseFocused;

  const _QuranPageContent({
    required this.verses,
    required this.page,
    required this.surahNumbers,
    this.onVerseFocused,
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
                children: _buildVerseWidgets(context, allBookmarks),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$page',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVerseWidgets(BuildContext context, Set<String> bookmarks) {
    final widgets = <Widget>[];
    int? lastSurah;

    for (final verse in verses) {
      // Show surah header when the surah changes within a page.
      if (verse.surahNumber != lastSurah) {
        if (lastSurah != null) {
          widgets.add(const SizedBox(height: 16));
        }
        widgets.add(_SurahHeader(surahNumber: verse.surahNumber));
        if (_shouldShowBismillahBeforeVerse(verse)) {
          widgets.add(const _BismillahHeader());
        }
        lastSurah = verse.surahNumber;
      }

      final isBookmarked = bookmarks.contains(verse.verseId);
      widgets.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            onVerseFocused?.call(verse.verseId);
            _openVerseDetail(context, verse);
          },
          child: _ArabicVerse(verse: verse, isBookmarked: isBookmarked),
        ),
      );
    }

    return widgets;
  }

  bool _shouldShowBismillahBeforeVerse(Verse verse) =>
      verse.verseNumber == 1 &&
      verse.surahNumber != 1 &&
      verse.surahNumber != 9;
}

class _BismillahHeader extends StatelessWidget {
  const _BismillahHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontFamily: _kfgqpcHafsFontFamily,
          fontSize: 26,
          fontWeight: FontWeight.w400,
          height: 2.0,
          color: AppTheme.islamicGreen,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _SurahHeader extends ConsumerWidget {
  final int surahNumber;

  const _SurahHeader({required this.surahNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahListProvider);
    final surahName = surahAsync.whenOrNull(
      data: (surahs) => surahs
          .where((s) => s.surahNumber == surahNumber)
          .firstOrNull
          ?.nameArabic,
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
            fontFamily: _kfgqpcHafsFontFamily,
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
            fontFamily: _kfgqpcHafsFontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w400,
            height: 2.2,
            color: isBookmarked ? AppTheme.islamicGreen : AppTheme.textPrimary,
          ),
          children: [
            ..._arabicTextSpans,
            TextSpan(
              text: ' ۝${_toArabicNumeral(verse.verseNumber)} ',
              style: TextStyle(color: AppTheme.goldAccent, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> get _arabicTextSpans {
    final leadingSpaceCount =
        verse.arabicText.length - verse.arabicText.trimLeft().length;
    final leadingSpace = verse.arabicText.substring(0, leadingSpaceCount);
    final trimmedText = verse.arabicText.substring(leadingSpaceCount);
    const bismillah = 'بِسْمِ';

    if (!trimmedText.startsWith(bismillah)) {
      return [TextSpan(text: verse.arabicText)];
    }

    final bismillahEnd = _findBismillahEnd(trimmedText);
    return [
      if (leadingSpace.isNotEmpty) TextSpan(text: leadingSpace),
      TextSpan(
        text: trimmedText.substring(0, bismillahEnd),
        style: const TextStyle(
          color: AppTheme.islamicGreen,
          fontSize: 28,
          height: 2.0,
        ),
      ),
      TextSpan(text: trimmedText.substring(bismillahEnd)),
    ];
  }

  int _findBismillahEnd(String text) {
    const lastWord = 'ٱلرَّحِيمِ';
    final lastWordStart = text.indexOf(lastWord);
    if (lastWordStart == -1) {
      return text.length;
    }
    return lastWordStart + lastWord.length;
  }

  String _toArabicNumeral(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}
