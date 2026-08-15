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
import '../../l10n/l10n.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/mushaf_reader_chrome.dart';
import '../widgets/mushaf_sample_page.dart';
import '../widgets/reader_app_bar.dart';
import 'verse_detail_screen.dart';

part '../widgets/reading_classic_content.dart';

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
    final currentModeLabel = _readingMode == ReadingMode.classic
        ? context.l10n.classic
        : context.l10n.mushaf;
    final targetMode = _readingMode == ReadingMode.classic
        ? ReadingMode.mushaf
        : ReadingMode.classic;
    final targetLabel = targetMode == ReadingMode.mushaf
        ? context.l10n.mushaf
        : context.l10n.classic;
    final targetIcon = targetMode == ReadingMode.mushaf
        ? Icons.image_outlined
        : Icons.menu_book;

    return ReaderAppBar(
      surahName: widget.surah.nameArabic,
      contextLabel:
          '${context.l10n.pageNumber(_currentPage)} · $currentModeLabel',
      switchModeLabel: targetLabel,
      switchModeIcon: targetIcon,
      onSwitchMode: () => _setReadingMode(targetMode),
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
    final showMushafPageNumber =
        _readingMode == ReadingMode.mushaf &&
        (_showMushafControls || _showMushafPageNumberOverlay);

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

    if (_readingMode == ReadingMode.mushaf) {
      return MushafReaderChrome(
        pageNumber: _currentPage,
        showControls: showAppBar,
        showPageNumber: showMushafPageNumber,
        appBar: _buildAppBar(),
        reader: reader,
        onShowControls: showImmersiveControls,
      );
    }

    return Scaffold(appBar: _buildAppBar(), body: reader);
  }

  Widget _buildClassicScroll() {
    final versesAsync = ref.watch(
      classicVersesProvider(widget.surah.surahNumber),
    );

    return versesAsync.when(
      data: (verses) {
        if (verses.isEmpty) {
          return Center(child: Text(context.l10n.noVersesInSurah));
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
            context.l10n.verseLoadError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMushafPageView() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: PageView.builder(
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
      ),
    );
  }
}

@visibleForTesting
List<int> mushafAdjacentPagesFor(int page) => [
  if (page > 1) page - 1,
  if (page < _totalPages) page + 1,
];

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
          return Center(child: Text(context.l10n.noVersesOnPage));
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
            context.l10n.verseLoadError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
