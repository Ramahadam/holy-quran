import 'dart:async';

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
const _bismillahOpeningWord = 'بِسْمِ';
const _bismillahLastWord = 'ٱلرَّحِيمِ';
const _bismillahFontSize = 28.0;
const _bismillahLineHeight = 2.0;
const _classicPageHorizontalPadding = 8.0;
const _classicPageVerticalPadding = 12.0;
const _classicVerseVerticalPadding = 8.0;
const _classicArabicMinFontSize = 30.0;
const _classicArabicMaxFontSize = 36.0;
const _classicArabicWidthScale = 0.092;
const _classicArabicLineHeight = 2.05;
const _classicAyahMarkerFontScale = 0.75;
const _totalPages = 604;
const _mushafPageNumberOverlayDuration = Duration(milliseconds: 1500);

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
  bool _showMushafPageNumberOverlay = false;
  Timer? _mushafPageNumberOverlayTimer;
  DateTime? _openedAt;
  ProviderContainer? _providerContainer;
  bool _didRecordSessionStart = false;
  bool _didScrollToInitialClassicVerse = false;

  late final ReadingPositionRepository _positionRepo;

  @override
  void initState() {
    super.initState();
    _positionRepo = ref.read(readingPositionRepositoryProvider);
    _openedAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerContainer = ProviderScope.containerOf(context, listen: false);
    if (_didRecordSessionStart) return;
    _didRecordSessionStart = true;
    final openedAt = _openedAt;
    if (openedAt != null) {
      _recordFeedbackPromptEngagement(openedAt);
    }
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
    _mushafPageNumberOverlayTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _saveReadingPosition() {
    final now = DateTime.now();
    final verseId = '${widget.surah.surahNumber}:1';
    final id = _currentPageFirstVerseId ?? verseId;
    _positionRepo
        .savePosition(ReadingPosition(verseId: id, lastReadAt: now))
        .catchError((Object e) {
          debugPrint('Failed to save reading position: $e');
        });
    _recordFeedbackPromptEngagement(now);
  }

  void _recordFeedbackPromptEngagement(DateTime timestamp) {
    try {
      final future = ref
          .read(feedbackPromptServiceProvider)
          .recordReadingSession(now: timestamp);
      unawaited(
        future
            .then((_) {
              _providerContainer?.invalidate(feedbackPromptShouldShowProvider);
            })
            .catchError((Object e) {
              debugPrint('Failed to record feedback prompt engagement: $e');
            }),
      );
    } catch (e) {
      debugPrint('Failed to start feedback prompt engagement recording: $e');
    }
  }

  String? _currentPageFirstVerseId;

  void _initPageController(int startPage) {
    if (_resolved) return;
    _resolved = true;
    _currentPage = startPage;
    _currentPageFirstVerseId = widget.initialVerseId;
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
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        children: [
          Text(
            'القرآن الكريم',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
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
                if (mode == ReadingMode.mushaf) {
                  _currentPageFirstVerseId = null;
                  _showMushafPageNumberOverlay = true;
                } else {
                  _currentPageFirstVerseId = widget.initialVerseId;
                  _hideMushafPageNumberOverlay();
                }
              });
              if (mode == ReadingMode.mushaf) {
                _scheduleMushafPageNumberOverlayHide();
              }
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

  void _scheduleMushafPageNumberOverlayHide() {
    _mushafPageNumberOverlayTimer?.cancel();
    _mushafPageNumberOverlayTimer = Timer(_mushafPageNumberOverlayDuration, () {
      if (!mounted) return;
      setState(() {
        _showMushafPageNumberOverlay = false;
      });
    });
  }

  void _hideMushafPageNumberOverlay() {
    _mushafPageNumberOverlayTimer?.cancel();
    _showMushafPageNumberOverlay = false;
  }

  Widget _buildPageView() {
    final showAppBar =
        _readingMode == ReadingMode.classic || _showMushafControls;
    final isMushafImmersive =
        _readingMode == ReadingMode.mushaf && !_showMushafControls;
    final showMushafPageNumber =
        _readingMode == ReadingMode.mushaf &&
        (_showMushafControls || _showMushafPageNumberOverlay);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setImmersiveMode(isMushafImmersive);
    });

    final reader = _readingMode == ReadingMode.classic
        ? _buildClassicScroll()
        : _buildMushafPageView();

    return Scaffold(
      appBar: showAppBar ? _buildAppBar() : null,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_readingMode == ReadingMode.mushaf && _showMushafControls) {
                setState(() {
                  _showMushafControls = false;
                  _hideMushafPageNumberOverlay();
                });
              }
            },
            child: reader,
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
                    _showMushafPageNumberOverlay = true;
                  });
                  _scheduleMushafPageNumberOverlayHide();
                },
              ),
            ),
          if (showMushafPageNumber)
            _MushafPageNumberOverlay(pageNumber: _currentPage),
        ],
      ),
    );
  }

  Widget _buildClassicScroll() {
    final versesAsync = ref.watch(
      versesBySurahProvider(widget.surah.surahNumber),
    );

    return versesAsync.when(
      data: (verses) {
        if (verses.isEmpty) {
          return const Center(child: Text('No verses in this surah.'));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _currentPageFirstVerseId ??= verses.first.verseId;
        });

        return _ClassicSurahContent(
          surah: widget.surah,
          verses: verses,
          initialVerseId: widget.initialVerseId,
          shouldScrollToInitialVerse:
              widget.initialVerseId != null && !_didScrollToInitialClassicVerse,
          onInitialVerseScrolled: () {
            _didScrollToInitialClassicVerse = true;
          },
          onVerseFocused: (verseId) => _currentPageFirstVerseId = verseId,
          onVerseVisible: (verseId) => _currentPageFirstVerseId = verseId,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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

  Widget _buildMushafPageView() {
    return PageView.builder(
      controller: _pageController,
      reverse: true,
      itemCount: _totalPages,
      onPageChanged: (index) {
        final pageNum = index + 1;
        setState(() {
          _currentPage = pageNum;
          _currentPageFirstVerseId = null;
          _showMushafPageNumberOverlay = _readingMode == ReadingMode.mushaf;
        });
        if (_readingMode == ReadingMode.mushaf) {
          _scheduleMushafPageNumberOverlayHide();
        }
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
  }
}

String _toArabicPageNumber(int number) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number
      .toString()
      .split('')
      .map((digit) => arabicDigits[int.parse(digit)])
      .join();
}

class _MushafPageNumberOverlay extends StatelessWidget {
  final int pageNumber;

  const _MushafPageNumberOverlay({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTheme.darkSurface.withValues(alpha: .92)
        : const Color(0xFFF7EEDB).withValues(alpha: .92);
    final borderColor = isDark
        ? AppTheme.darkIslamicGreenBorder
        : const Color(0xFFB98B42).withValues(alpha: .46);
    final textColor = isDark
        ? AppTheme.darkTextPrimary
        : const Color(0xFF2B2113);

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomPadding + 10,
      child: IgnorePointer(
        child: Center(
          child: DecoratedBox(
            key: const ValueKey('mushafPageNumberOverlay'),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .28 : .12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Text(
                _toArabicPageNumber(pageNumber),
                key: const ValueKey('mushafPageNumberText'),
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
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
      loading: () => const Center(child: CircularProgressIndicator()),
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
              style: Theme.of(context).textTheme.bodySmall,
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

class _ClassicSurahContent extends ConsumerStatefulWidget {
  final Surah surah;
  final List<Verse> verses;
  final String? initialVerseId;
  final bool shouldScrollToInitialVerse;
  final VoidCallback onInitialVerseScrolled;
  final ValueChanged<String>? onVerseFocused;
  final ValueChanged<String>? onVerseVisible;

  const _ClassicSurahContent({
    required this.surah,
    required this.verses,
    required this.initialVerseId,
    required this.shouldScrollToInitialVerse,
    required this.onInitialVerseScrolled,
    this.onVerseFocused,
    this.onVerseVisible,
  });

  @override
  ConsumerState<_ClassicSurahContent> createState() =>
      _ClassicSurahContentState();
}

class _ClassicSurahContentState extends ConsumerState<_ClassicSurahContent> {
  late final ScrollController _scrollController;
  String? _lastReportedVisibleVerseId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateVisibleVerse);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateVisibleVerse();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateVisibleVerse);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(
      bookmarksBySurahProvider(widget.surah.surahNumber),
    );
    final bookmarks = bookmarksAsync.valueOrNull ?? {};

    if (widget.shouldScrollToInitialVerse && widget.initialVerseId != null) {
      final initialVerseKey = GlobalObjectKey(
        'classicVerse-${widget.initialVerseId}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = initialVerseKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.1,
            duration: Duration.zero,
          );
        }
        widget.onInitialVerseScrolled();
      });
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: _classicPageHorizontalPadding,
        vertical: _classicPageVerticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildVerseWidgets(context, bookmarks),
      ),
    );
  }

  void _updateVisibleVerse() {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (widget.verses.isEmpty || maxScrollExtent <= 0) return;

    final progress = (_scrollController.offset / maxScrollExtent).clamp(
      0.0,
      1.0,
    );
    final index = (progress * (widget.verses.length - 1)).round().clamp(
      0,
      widget.verses.length - 1,
    );
    final visibleVerseId = widget.verses[index].verseId;

    if (visibleVerseId != _lastReportedVisibleVerseId) {
      _lastReportedVisibleVerseId = visibleVerseId;
      widget.onVerseVisible?.call(visibleVerseId);
    }
  }

  List<Widget> _buildVerseWidgets(BuildContext context, Set<String> bookmarks) {
    final widgets = <Widget>[];
    int? lastSurah;

    for (final verse in widget.verses) {
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
          key: GlobalObjectKey('classicVerse-${verse.verseId}'),
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            widget.onVerseFocused?.call(verse.verseId);
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontFamily: _kfgqpcHafsFontFamily,
          fontSize: _bismillahFontSize,
          fontWeight: FontWeight.w400,
          height: _bismillahLineHeight,
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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Center(
        child: Text(
          surahName ?? 'سورة $surahNumber',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: _kfgqpcHafsFontFamily,
            color: Theme.of(context).colorScheme.primary,
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
      padding: const EdgeInsets.symmetric(
        vertical: _classicVerseVerticalPadding,
      ),
      child: SizedBox(
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fontSize = _fontSizeForWidth(constraints.maxWidth);
            return RichText(
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              textScaler: MediaQuery.textScalerOf(context),
              textWidthBasis: TextWidthBasis.parent,
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontFamily: _kfgqpcHafsFontFamily,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  height: _classicArabicLineHeight,
                  color: isBookmarked
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).textTheme.headlineLarge?.color,
                ),
                children: [
                  ..._arabicTextSpans,
                  if (!_hasEmbeddedAyahMarker)
                    TextSpan(
                      text: ' ۝${_toArabicNumeral(verse.verseNumber)} ',
                      style: TextStyle(
                        color: AppTheme.goldAccent,
                        fontSize: fontSize * _classicAyahMarkerFontScale,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _fontSizeForWidth(double width) => (width * _classicArabicWidthScale)
      .clamp(_classicArabicMinFontSize, _classicArabicMaxFontSize)
      .toDouble();

  bool get _hasEmbeddedAyahMarker => verse.arabicText.contains('۝');

  List<TextSpan> get _arabicTextSpans {
    final leadingSpaceCount =
        verse.arabicText.length - verse.arabicText.trimLeft().length;
    final leadingSpace = verse.arabicText.substring(0, leadingSpaceCount);
    final trimmedText = verse.arabicText.substring(leadingSpaceCount);

    if (!trimmedText.startsWith(_bismillahOpeningWord)) {
      return [TextSpan(text: verse.arabicText)];
    }

    final bismillahEnd = _findBismillahEnd(trimmedText);
    return [
      if (leadingSpace.isNotEmpty) TextSpan(text: leadingSpace),
      TextSpan(
        text: trimmedText.substring(0, bismillahEnd),
        style: const TextStyle(
          fontSize: _bismillahFontSize,
          height: _bismillahLineHeight,
        ),
      ),
      TextSpan(text: trimmedText.substring(bismillahEnd)),
    ];
  }

  int _findBismillahEnd(String text) {
    final lastWordStart = text.indexOf(_bismillahLastWord);
    if (lastWordStart == -1) {
      return text.length;
    }
    return lastWordStart + _bismillahLastWord.length;
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
