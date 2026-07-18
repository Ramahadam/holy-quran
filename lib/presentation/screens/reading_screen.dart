import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qcf_quran/qcf_quran.dart';
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
const _bismillahAllahWord = 'ٱللَّهِ';
const _bismillahLastWord = 'ٱلرَّحِيمِ';
const _bismillahText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
const _bismillahFontSize = 28.0;
const _bismillahLineHeight = 1.7;
const _classicPageHorizontalPadding = 8.0;
const _classicPageVerticalPadding = 12.0;
const _classicVerseVerticalPadding = 4.0;
const _classicArabicMinFontSize = 24.0;
const _classicArabicMaxFontSize = 30.0;
const _classicArabicWidthScale = 0.078;
const _classicArabicLineHeight = 1.6;
const _classicAyahMarkerFontScale = 0.88;
const _classicAyahMarkerLineHeight = 1.0;
const _totalPages = 604;
const _mushafPageContextStripHeight = 32.0;
const _mushafPageNumberOverlayDuration = Duration(milliseconds: 1500);
final _classicEmbeddedMarkerPattern = RegExp(
  r'\s*(?:۞|۩|۝\s*[٠-٩0-9]*|[ۖۗۘۙۚۛۜ])\s*',
);
final _classicInlineAnnotationPattern = RegExp(r'[ۣ۪ۭ۟۠ۡۢۤۧۨ۫۬]');
final _whitespacePattern = RegExp(r'\s+');

enum ReadingMode { classic, mushaf }

void _openVerseDetail(BuildContext context, Verse verse) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => VerseDetailScreen(verse: verse),
    ),
  );
}

double _classicFontSizeForWidth(double width) =>
    (width * _classicArabicWidthScale)
        .clamp(_classicArabicMinFontSize, _classicArabicMaxFontSize)
        .toDouble();

Object _classicParagraphGroupFor(Verse verse) => verse.surahNumber;

List<TextSpan> _classicArabicTextSpans(
  Verse verse, {
  GestureRecognizer? recognizer,
  TextStyle? style,
}) {
  final text = _classicDisplayArabicText(verse);
  final leadingSpaceCount = text.length - text.trimLeft().length;
  final leadingSpace = text.substring(0, leadingSpaceCount);
  final trimmedText = text.substring(leadingSpaceCount);

  if (!trimmedText.startsWith(_bismillahOpeningWord)) {
    return [TextSpan(text: text, recognizer: recognizer, style: style)];
  }

  final bismillahEnd = _findBismillahEnd(trimmedText);
  return [
    if (leadingSpace.isNotEmpty)
      TextSpan(text: leadingSpace, recognizer: recognizer, style: style),
    TextSpan(
      text: trimmedText.substring(0, bismillahEnd),
      recognizer: recognizer,
      style: (style ?? const TextStyle()).copyWith(
        fontFamily: _kfgqpcHafsFontFamily,
        fontSize: _bismillahFontSize,
        height: _bismillahLineHeight,
      ),
    ),
    TextSpan(
      text: trimmedText.substring(bismillahEnd),
      recognizer: recognizer,
      style: style,
    ),
  ];
}

String _classicDisplayArabicText(Verse verse) {
  final text = _normalizedClassicArabicText(verse);
  if (_hasEmbeddedBismillah(verse)) {
    return text.substring(_findBismillahEnd(text)).trimLeft();
  }
  return text;
}

String _normalizedClassicArabicText(Verse verse) => verse.arabicText
    .replaceAll(_classicInlineAnnotationPattern, '')
    .replaceAll(_classicEmbeddedMarkerPattern, ' ')
    .replaceAll(_whitespacePattern, ' ')
    .trim();

bool _hasEmbeddedBismillah(Verse verse) {
  if (verse.surahNumber != 1 || verse.verseNumber != 1) return false;
  final text = _normalizedClassicArabicText(verse);
  return text.startsWith(_bismillahOpeningWord) &&
      text.contains(_bismillahLastWord);
}

int? _classicJuzForVerse(Verse verse) {
  final juz = getJuzNumber(verse.surahNumber, verse.verseNumber);
  return juz >= 1 && juz <= 30 ? juz : null;
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
    final targetMode = _readingMode == ReadingMode.classic
        ? ReadingMode.mushaf
        : ReadingMode.classic;
    final targetLabel = targetMode == ReadingMode.mushaf ? 'Mushaf' : 'Classic';
    final targetIcon = targetMode == ReadingMode.mushaf
        ? Icons.image_outlined
        : Icons.menu_book;

    return AppBar(
      toolbarHeight: 56,
      title: Text(
        'Page $_currentPage',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      centerTitle: true,
      actions: [
        TextButton.icon(
          onPressed: () => _setReadingMode(targetMode),
          icon: Icon(targetIcon),
          label: Text(targetLabel),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _setReadingMode(ReadingMode mode) {
    setState(() {
      _readingMode = mode;
      _showMushafControls = false;
      if (mode == ReadingMode.mushaf) {
        _currentPageFirstVerseId = null;
        _showMushafPageNumberOverlay = true;
      } else {
        _currentPageFirstVerseId = widget.initialVerseId;
        _didScrollToInitialClassicVerse = false;
        _hideMushafPageNumberOverlay();
      }
    });
    if (mode == ReadingMode.mushaf) {
      _scheduleMushafPageNumberOverlayHide();
      _prefetchMushafPages(_currentPage);
    }
  }

  void _toggleMushafControls() {
    if (_readingMode != ReadingMode.mushaf) return;

    final showControls = !_showMushafControls;
    setState(() {
      _showMushafControls = showControls;
      _showMushafPageNumberOverlay = showControls;
    });
    if (showControls) {
      _scheduleMushafPageNumberOverlayHide();
    } else {
      _hideMushafPageNumberOverlay();
    }
  }

  void _prefetchMushafPages(int page) {
    for (final adjacentPage in mushafAdjacentPagesFor(page)) {
      unawaited(
        ref
            .read(versesByPageProvider(adjacentPage).future)
            .then<void>((_) {})
            .catchError((Object error) {
              debugPrint(
                'Failed to prefetch Mushaf page $adjacentPage: $error',
              );
            }),
      );
    }
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

    void showImmersiveControls() {
      setState(() {
        _showMushafControls = true;
        _showMushafPageNumberOverlay = true;
      });
      _scheduleMushafPageNumberOverlayHide();
    }

    final readerStack = Stack(
      children: [
        reader,
        if (showMushafPageNumber)
          _MushafPageNumberOverlay(pageNumber: _currentPage),
      ],
    );
    final body = _readingMode == ReadingMode.mushaf
        ? SafeArea(
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isMushafImmersive ? showImmersiveControls : null,
                  child: _MushafPageContextStrip(pageNumber: _currentPage),
                ),
                Expanded(child: readerStack),
              ],
            ),
          )
        : readerStack;

    return Scaffold(appBar: showAppBar ? _buildAppBar() : null, body: body);
  }

  Widget _buildClassicScroll() {
    final versesAsync = ref.watch(
      classicVersesProvider(widget.surah.surahNumber),
    );

    return versesAsync.when(
      data: (verses) {
        if (verses.isEmpty) {
          return const Center(child: Text('No verses in this surah.'));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _currentPageFirstVerseId ??= verses.first.verseId;
        });

        final initialClassicVerseId =
            widget.initialVerseId ?? '${widget.surah.surahNumber}:1';

        return _ClassicSurahContent(
          surah: widget.surah,
          verses: verses,
          initialVerseId: initialClassicVerseId,
          useEagerScroll: widget.initialVerseId != null,
          shouldScrollToInitialVerse:
              widget.initialVerseId != null && !_didScrollToInitialClassicVerse,
          onInitialVerseScrolled: () {
            if (!mounted) return;
            setState(() => _didScrollToInitialClassicVerse = true);
          },
          onVerseFocused: (verseId) => _currentPageFirstVerseId = verseId,
          onVerseVisible: (verse) {
            if (widget.initialVerseId != null &&
                !_didScrollToInitialClassicVerse) {
              return;
            }
            _currentPageFirstVerseId = verse.verseId;
            if (verse.page != _currentPage) {
              setState(() => _currentPage = verse.page);
            }
          },
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
          _prefetchMushafPages(pageNum);
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
          onPageTap: pageNum == _currentPage ? _toggleMushafControls : null,
        );
      },
    );
  }
}

@visibleForTesting
List<int> mushafAdjacentPagesFor(int page) => [
  if (page > 1) page - 1,
  if (page < _totalPages) page + 1,
];

String _toArabicPageNumber(int number) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number
      .toString()
      .split('')
      .map((digit) => arabicDigits[int.parse(digit)])
      .join();
}

({String surah, String juz}) _mushafPageContext(int pageNumber) {
  final ranges = getPageData(pageNumber);
  final first = ranges.first;
  final last = ranges.last;
  final firstSurah = int.parse(first['surah'].toString());
  final lastSurah = int.parse(last['surah'].toString());
  final firstVerse = int.parse(first['start'].toString());
  final lastVerse = int.parse(last['end'].toString());
  final firstSurahName = getSurahNameArabic(firstSurah);
  final lastSurahName = getSurahNameArabic(lastSurah);
  final surah = firstSurah == lastSurah
      ? 'سورة $firstSurahName'
      : 'سورة $firstSurahName – $lastSurahName';
  final firstJuz = getJuzNumber(firstSurah, firstVerse);
  final lastJuz = getJuzNumber(lastSurah, lastVerse);
  final juz = firstJuz == lastJuz
      ? mushafJuzLabel(firstJuz)
      : '${mushafJuzLabel(firstJuz)} – '
            '${mushafJuzLabel(lastJuz).replaceFirst('الجزء ', '')}';

  return (surah: surah, juz: juz);
}

class _MushafPageContextStrip extends StatelessWidget {
  final int pageNumber;

  const _MushafPageContextStrip({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final pageContext = _mushafPageContext(pageNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTheme.darkSurface.withValues(alpha: .9)
        : const Color(0xFFF7EEDB).withValues(alpha: .9);
    final borderColor = isDark
        ? AppTheme.darkIslamicGreenBorder.withValues(alpha: .72)
        : const Color(0xFFB98B42).withValues(alpha: .42);
    final textColor = isDark
        ? AppTheme.darkTextPrimary
        : const Color(0xFF2B2113);

    return SizedBox(
      width: double.infinity,
      height: _mushafPageContextStripHeight,
      child: IgnorePointer(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: '${pageContext.surah}، ${pageContext.juz}',
          child: DecoratedBox(
            key: const ValueKey('mushafPageContextStrip'),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            pageContext.juz,
                            key: const ValueKey('mushafPageJuzText'),
                            maxLines: 1,
                            textDirection: TextDirection.rtl,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            pageContext.surah,
                            key: const ValueKey('mushafPageSurahText'),
                            maxLines: 1,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: textColor,
                              fontFamily: mushafSurahTitleFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  final VoidCallback? onPageTap;

  const _QuranPage({
    super.key,
    required this.page,
    required this.readingMode,
    this.onFirstVerseResolved,
    this.onVerseHit,
    this.onPageTap,
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
          final allBookmarks = <String>{};
          for (final surahNumber in surahNumbers) {
            final bookmarks = ref.watch(bookmarksBySurahProvider(surahNumber));
            final verseIds = bookmarks.valueOrNull;
            if (verseIds != null) allBookmarks.addAll(verseIds);
          }

          return MushafSamplePage(
            page: widget.page,
            onPageTap: widget.onPageTap,
            bookmarkedVerseIds: allBookmarks,
            onVerseLongPress: (verseId) {
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
  final bool useEagerScroll;
  final bool shouldScrollToInitialVerse;
  final VoidCallback onInitialVerseScrolled;
  final ValueChanged<String>? onVerseFocused;
  final ValueChanged<Verse>? onVerseVisible;

  const _ClassicSurahContent({
    required this.surah,
    required this.verses,
    required this.initialVerseId,
    required this.useEagerScroll,
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
  late List<Verse> _verses;
  final GlobalKey _initialVerseKey = GlobalKey();
  final Set<String> _additionalBookmarks = {};
  String? _lastReportedVisibleVerseId;
  bool _isLoadingAdjacentSurah = false;

  @override
  void initState() {
    super.initState();
    _verses = List<Verse>.of(widget.verses);
    _scrollController = ScrollController();
    _scrollController.addListener(_updateVisibleVerse);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateVisibleVerse();
    });
  }

  @override
  void didUpdateWidget(covariant _ClassicSurahContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah.surahNumber != widget.surah.surahNumber ||
        oldWidget.verses != widget.verses) {
      _verses = List<Verse>.of(widget.verses);
      _additionalBookmarks.clear();
      _lastReportedVisibleVerseId = null;
    }
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
    final bookmarks = {...?bookmarksAsync.valueOrNull, ..._additionalBookmarks};

    if (widget.shouldScrollToInitialVerse && widget.initialVerseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final context = _initialVerseKey.currentContext;
        final startsAtInitialVerse =
            _verses.isNotEmpty &&
            _verses.first.verseId == widget.initialVerseId;
        if (!startsAtInitialVerse && context != null) {
          await Scrollable.ensureVisible(
            context,
            alignment: 0.1,
            duration: Duration.zero,
          );
        }
        widget.onInitialVerseScrolled();
      });
    }

    final contentWidgets = _buildVerseWidgets(context, bookmarks);
    final scrollable = widget.useEagerScroll
        ? SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: _classicPageHorizontalPadding,
              vertical: _classicPageVerticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: contentWidgets,
            ),
          )
        : ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: _classicPageHorizontalPadding,
              vertical: _classicPageVerticalPadding,
            ),
            itemCount: contentWidgets.length,
            itemBuilder: (context, index) => contentWidgets[index],
          );

    return RefreshIndicator(
      onRefresh: _loadPreviousSurah,
      child: NotificationListener<OverscrollNotification>(
        onNotification: (notification) {
          if (notification.overscroll > 0) {
            unawaited(_loadNextSurah());
          }
          return false;
        },
        child: scrollable,
      ),
    );
  }

  Future<void> _loadNextSurah() async {
    if (_isLoadingAdjacentSurah || _verses.isEmpty) return;
    final nextSurahNumber = _verses.last.surahNumber + 1;
    if (nextSurahNumber > 114) return;
    await _loadAdjacentSurah(nextSurahNumber, prepend: false);
  }

  Future<void> _loadPreviousSurah() async {
    if (_isLoadingAdjacentSurah || _verses.isEmpty) return;
    final previousSurahNumber = _verses.first.surahNumber - 1;
    if (previousSurahNumber < 1) return;
    await _loadAdjacentSurah(previousSurahNumber, prepend: true);
  }

  Future<void> _loadAdjacentSurah(
    int surahNumber, {
    required bool prepend,
  }) async {
    _isLoadingAdjacentSurah = true;
    try {
      final results = await Future.wait([
        ref.read(versesBySurahProvider(surahNumber).future),
        ref.read(bookmarksBySurahProvider(surahNumber).future),
      ]);
      if (!mounted) return;
      final verses = results[0] as List<Verse>;
      final bookmarks = results[1] as Set<String>;
      if (verses.isEmpty) return;
      setState(() {
        _verses = prepend ? [...verses, ..._verses] : [..._verses, ...verses];
        _additionalBookmarks.addAll(bookmarks);
      });
    } finally {
      _isLoadingAdjacentSurah = false;
    }
  }

  void _updateVisibleVerse() {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (_verses.isEmpty || maxScrollExtent <= 0) return;

    final progress = (_scrollController.offset / maxScrollExtent).clamp(
      0.0,
      1.0,
    );
    final index = (progress * (_verses.length - 1)).round().clamp(
      0,
      _verses.length - 1,
    );
    final visibleVerse = _verses[index];

    if (visibleVerse.verseId != _lastReportedVisibleVerseId) {
      _lastReportedVisibleVerseId = visibleVerse.verseId;
      widget.onVerseVisible?.call(visibleVerse);
    }
  }

  List<Widget> _buildVerseWidgets(BuildContext context, Set<String> bookmarks) {
    final widgets = <Widget>[];
    var paragraphVerses = <Verse>[];
    Object? currentParagraphGroup;
    int? lastSurah;
    int? lastJuz;

    void flushParagraph() {
      if (paragraphVerses.isEmpty) return;

      final initialVerseId = widget.initialVerseId;
      final containsInitialVerse =
          widget.useEagerScroll &&
          initialVerseId != null &&
          paragraphVerses.any((verse) => verse.verseId == initialVerseId);

      if (containsInitialVerse) {
        widgets.add(SizedBox(key: _initialVerseKey, height: 1));
      }

      widgets.add(
        _ClassicVerseParagraph(
          verses: List<Verse>.unmodifiable(paragraphVerses),
          bookmarks: bookmarks,
          onVerseFocused: widget.onVerseFocused,
        ),
      );
      paragraphVerses = <Verse>[];
      currentParagraphGroup = null;
    }

    for (final verse in _verses) {
      final juz = _classicJuzForVerse(verse);
      if (juz != null && juz != lastJuz) {
        flushParagraph();
        if (lastJuz != null) {
          widgets.add(const SizedBox(height: 12));
        }
        widgets.add(_ClassicJuzDivider(juz: juz));
        lastJuz = juz;
      }

      if (verse.surahNumber != lastSurah) {
        flushParagraph();
        if (lastSurah != null) {
          widgets.add(const SizedBox(height: 16));
        }
        final hasEmbeddedBismillah = _hasEmbeddedBismillah(verse);
        widgets.add(
          _ClassicSurahOpening(
            surahNumber: verse.surahNumber,
            showBismillah:
                hasEmbeddedBismillah || _shouldShowBismillahBeforeVerse(verse),
            onBismillahLongPress: hasEmbeddedBismillah
                ? () {
                    widget.onVerseFocused?.call(verse.verseId);
                    _openVerseDetail(context, verse);
                  }
                : null,
          ),
        );
        lastSurah = verse.surahNumber;
      }

      if (verse.verseId == widget.initialVerseId &&
          paragraphVerses.isNotEmpty) {
        flushParagraph();
      }

      final paragraphGroup = _classicParagraphGroupFor(verse);
      if (currentParagraphGroup != null &&
          currentParagraphGroup != paragraphGroup) {
        flushParagraph();
      }
      currentParagraphGroup = paragraphGroup;
      paragraphVerses.add(verse);
    }

    flushParagraph();
    return widgets;
  }

  bool _shouldShowBismillahBeforeVerse(Verse verse) =>
      verse.verseNumber == 1 &&
      verse.surahNumber != 1 &&
      verse.surahNumber != 9;
}

class _BismillahHeader extends StatelessWidget {
  final VoidCallback? onLongPress;

  const _BismillahHeader({this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.headlineLarge?.copyWith(
      fontFamily: _kfgqpcHafsFontFamily,
      fontSize: _bismillahFontSize,
      fontWeight: FontWeight.w400,
      height: _bismillahLineHeight,
    );
    final bismillah = Semantics(
      header: true,
      label: _bismillahText,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(
          key: const ValueKey('classicBismillah'),
          TextSpan(
            style: baseStyle,
            children: [
              const TextSpan(text: 'بِسْمِ '),
              TextSpan(
                text: _bismillahAllahWord,
                style: const TextStyle(color: AppTheme.bismillahAllah),
              ),
              const TextSpan(text: ' ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'),
            ],
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
    if (onLongPress == null) return bismillah;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: bismillah,
    );
  }
}

class _ClassicSurahOpening extends ConsumerWidget {
  final int surahNumber;
  final bool showBismillah;
  final VoidCallback? onBismillahLongPress;

  const _ClassicSurahOpening({
    required this.surahNumber,
    required this.showBismillah,
    this.onBismillahLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahListProvider);
    final surahName = surahAsync.whenOrNull(
      data: (surahs) => surahs
          .where((s) => s.surahNumber == surahNumber)
          .firstOrNull
          ?.nameArabic,
    );
    final label = 'سورة ${surahName ?? _toArabicNumeral(surahNumber)}';
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      key: const ValueKey('classicSurahOpening'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Semantics(
            header: true,
            child: ConstrainedBox(
              key: const ValueKey('classicSurahTitle'),
              constraints: const BoxConstraints(maxWidth: 320),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.22),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.45),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: mushafSurahTitleFontFamily,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
          if (showBismillah)
            _BismillahHeader(onLongPress: onBismillahLongPress),
        ],
      ),
    );
  }
}

class _ClassicJuzDivider extends StatelessWidget {
  final int juz;

  const _ClassicJuzDivider({required this.juz});

  @override
  Widget build(BuildContext context) {
    final label = mushafJuzLabel(juz);
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Padding(
        key: ValueKey('classicJuzDivider-$juz'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          ],
        ),
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

class _ClassicVerseParagraph extends StatefulWidget {
  final List<Verse> verses;
  final Set<String> bookmarks;
  final ValueChanged<String>? onVerseFocused;

  const _ClassicVerseParagraph({
    required this.verses,
    required this.bookmarks,
    this.onVerseFocused,
  });

  @override
  State<_ClassicVerseParagraph> createState() => _ClassicVerseParagraphState();
}

class _ClassicVerseParagraphState extends State<_ClassicVerseParagraph> {
  final Map<String, LongPressGestureRecognizer> _recognizers = {};

  @override
  void didUpdateWidget(covariant _ClassicVerseParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verses != widget.verses ||
        oldWidget.onVerseFocused != widget.onVerseFocused) {
      _disposeRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final paragraph = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: _classicVerseVerticalPadding,
      ),
      child: SizedBox(
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fontSize = _classicFontSizeForWidth(constraints.maxWidth);
            return RichText(
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              textScaler: MediaQuery.textScalerOf(context),
              textWidthBasis: TextWidthBasis.parent,
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  height: _classicArabicLineHeight,
                  color: _baseTextColor(context),
                ),
                children: _buildVerseSpans(context, fontSize),
              ),
            );
          },
        ),
      ),
    );

    if (widget.verses.length != 1) {
      return paragraph;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _focusVerse(widget.verses.single),
      child: paragraph,
    );
  }

  Color? _baseTextColor(BuildContext context) {
    if (widget.verses.length == 1 &&
        widget.bookmarks.contains(widget.verses.single.verseId)) {
      return Theme.of(context).colorScheme.onPrimaryContainer;
    }
    return Theme.of(context).textTheme.headlineLarge?.color;
  }

  List<InlineSpan> _buildVerseSpans(BuildContext context, double fontSize) {
    final bookmarkedColor = Theme.of(context).colorScheme.onPrimaryContainer;
    final markerColor = Theme.of(context).brightness == Brightness.light
        ? AppTheme.classicAyahMarker
        : AppTheme.goldAccent;
    final baseStyleIsBookmarked =
        widget.verses.length == 1 &&
        widget.bookmarks.contains(widget.verses.single.verseId);
    final spans = <InlineSpan>[];

    for (final verse in widget.verses) {
      final recognizer = widget.verses.length == 1
          ? null
          : _verseRecognizer(verse);
      final verseStyle =
          widget.bookmarks.contains(verse.verseId) && !baseStyleIsBookmarked
          ? TextStyle(color: bookmarkedColor)
          : null;

      spans.addAll(
        _classicArabicTextSpans(
          verse,
          recognizer: recognizer,
          style: verseStyle,
        ),
      );
      spans.add(
        TextSpan(
          // A non-breaking space keeps the ayah marker attached to the final
          // word instead of allowing it to become orphaned on the next line.
          text: '\u00a0${_toArabicNumeral(verse.verseNumber)} ',
          recognizer: recognizer,
          style: TextStyle(
            fontFamily: _kfgqpcHafsFontFamily,
            color: markerColor,
            fontSize: fontSize * _classicAyahMarkerFontScale,
            fontWeight: FontWeight.w500,
            height: _classicAyahMarkerLineHeight,
          ),
        ),
      );
    }

    return spans;
  }

  LongPressGestureRecognizer _verseRecognizer(Verse verse) {
    return _recognizers.putIfAbsent(
      verse.verseId,
      () =>
          LongPressGestureRecognizer()..onLongPress = () => _focusVerse(verse),
    );
  }

  void _focusVerse(Verse verse) {
    widget.onVerseFocused?.call(verse.verseId);
    _openVerseDetail(context, verse);
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
            final fontSize = _classicFontSizeForWidth(constraints.maxWidth);
            final markerColor = Theme.of(context).brightness == Brightness.light
                ? AppTheme.classicAyahMarker
                : AppTheme.goldAccent;
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
                  ..._classicArabicTextSpans(verse),
                  TextSpan(
                    text: ' ${_toArabicNumeral(verse.verseNumber)} ',
                    style: TextStyle(
                      color: markerColor,
                      fontSize: fontSize * _classicAyahMarkerFontScale,
                      fontWeight: FontWeight.w500,
                      height: _classicAyahMarkerLineHeight,
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
}
