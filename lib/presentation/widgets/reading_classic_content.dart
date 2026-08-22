part of '../screens/reading_screen.dart';

const _kfgqpcHafsFontFamily = AppTheme.quranFontFamily;
const _bismillahOpeningWord = 'بِسۡمِ';
const _bismillahAllahWord = 'ٱللَّهِ';
const _bismillahLastWord = 'ٱلرَّحِيمِ';
const _bismillahText = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';
const _bismillahFontSize = 28.0;
const _bismillahLineHeight = 1.7;
const _classicPageHorizontalPadding = 24.0;
const _classicPageVerticalPadding = 12.0;
const _classicVerseVerticalPadding = 4.0;
const _classicArabicMinFontSize = 24.0;
const _classicArabicMaxFontSize = 30.0;
const _classicArabicWidthScale = 0.086;
const _classicArabicLineHeight = 1.6;
const _classicAyahMarkerFontScale = 0.88;
const _classicAyahMarkerLineHeight = 1.0;
final _classicEmbeddedMarkerPattern = RegExp(
  r'\s*(?:۞|۩|۝\s*[٠-٩0-9]*|[ۖۗۘۙۚۛۜ])\s*',
);
final _whitespacePattern = RegExp(r'\s+');

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
  final GlobalKey _scrollViewKey = GlobalKey();
  final Map<String, GlobalKey<_ClassicVerseParagraphState>> _paragraphKeys = {};
  final Set<String> _additionalBookmarks = {};
  String? _lastReportedVisibleVerseId;
  bool _visibleVerseUpdateScheduled = false;
  bool _isLoadingAdjacentSurah = false;

  @override
  void initState() {
    super.initState();
    _verses = List<Verse>.of(widget.verses);
    _scrollController = ScrollController();
    _scrollController.addListener(_scheduleVisibleVerseUpdate);
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
    _scrollController.removeListener(_scheduleVisibleVerseUpdate);
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
            alignment: 0,
            duration: Duration.zero,
          );
        }
        widget.onInitialVerseScrolled();
      });
    }

    final contentWidgets = _buildVerseWidgets(context, bookmarks);
    final scrollable = widget.useEagerScroll
        ? SingleChildScrollView(
            key: _scrollViewKey,
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
            key: _scrollViewKey,
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

  void _scheduleVisibleVerseUpdate() {
    if (_visibleVerseUpdateScheduled) return;
    _visibleVerseUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibleVerseUpdateScheduled = false;
      if (mounted) _updateVisibleVerse();
    });
  }

  void _updateVisibleVerse() {
    if (!_scrollController.hasClients) return;

    final scrollView = _scrollViewKey.currentContext?.findRenderObject();
    if (_verses.isEmpty || scrollView is! RenderBox) return;

    final viewport = scrollView.localToGlobal(Offset.zero) & scrollView.size;
    ({Verse verse, double top})? firstVisible;
    for (final key in _paragraphKeys.values) {
      final candidate = key.currentState?.firstVisibleVerseWithin(viewport);
      if (candidate != null &&
          (firstVisible == null || candidate.top < firstVisible.top)) {
        firstVisible = candidate;
      }
    }

    final visibleVerse = firstVisible?.verse;
    if (visibleVerse != null &&
        visibleVerse.verseId != _lastReportedVisibleVerseId) {
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
          key: _paragraphKeys.putIfAbsent(
            paragraphVerses.first.verseId,
            () => GlobalKey<_ClassicVerseParagraphState>(),
          ),
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
              const TextSpan(text: 'بِسۡمِ '),
              TextSpan(
                text: _bismillahAllahWord,
                style: const TextStyle(color: AppTheme.quranRed),
              ),
              const TextSpan(text: ' ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ'),
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
            label: label,
            excludeSemantics: true,
            child: Padding(
              key: const ValueKey('classicSurahTitle'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: mushafSurahTitleFontFamily,
                  color: colorScheme.primary,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    super.key,
    required this.verses,
    required this.bookmarks,
    this.onVerseFocused,
  });

  @override
  State<_ClassicVerseParagraph> createState() => _ClassicVerseParagraphState();
}

class _ClassicVerseParagraphState extends State<_ClassicVerseParagraph> {
  final Map<String, LongPressGestureRecognizer> _recognizers = {};
  final GlobalKey _richTextKey = GlobalKey();
  late List<int> _verseTextEnds;

  @override
  void initState() {
    super.initState();
    _verseTextEnds = _calculateVerseTextEnds();
  }

  @override
  void didUpdateWidget(covariant _ClassicVerseParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verses != widget.verses ||
        oldWidget.onVerseFocused != widget.onVerseFocused) {
      _disposeRecognizers();
    }
    if (oldWidget.verses != widget.verses) {
      _verseTextEnds = _calculateVerseTextEnds();
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
              key: _richTextKey,
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

  ({Verse verse, double top})? firstVisibleVerseWithin(Rect viewport) {
    final paragraph = _richTextKey.currentContext?.findRenderObject();
    if (paragraph is! RenderParagraph) return null;

    final paragraphOrigin = paragraph.localToGlobal(Offset.zero);
    final paragraphBounds = paragraphOrigin & paragraph.size;
    if (paragraph.size.isEmpty || !paragraphBounds.overlaps(viewport)) {
      return null;
    }

    final localTop = (viewport.top - paragraphOrigin.dy).clamp(
      0.0,
      paragraph.size.height - 1,
    );
    // Classic text flows right-to-left, so the right edge resolves the first
    // readable text position on the top visible line.
    final textPosition = paragraph.getPositionForOffset(
      Offset(paragraph.size.width, localTop),
    );

    var lowerBound = 0;
    var upperBound = _verseTextEnds.length;
    while (lowerBound < upperBound) {
      final middle = (lowerBound + upperBound) >> 1;
      if (textPosition.offset < _verseTextEnds[middle]) {
        upperBound = middle;
      } else {
        lowerBound = middle + 1;
      }
    }
    final verseIndex = lowerBound.clamp(0, widget.verses.length - 1);
    final visibleTop = paragraphBounds.top < viewport.top
        ? viewport.top
        : paragraphBounds.top;
    return (verse: widget.verses[verseIndex], top: visibleTop);
  }

  List<int> _calculateVerseTextEnds() {
    var textEnd = 0;
    final verseTextEnds = <int>[];
    for (final verse in widget.verses) {
      textEnd +=
          _classicDisplayArabicText(verse).length +
          '\u00a0${_toArabicNumeral(verse.verseNumber)} '.length;
      verseTextEnds.add(textEnd);
    }
    return verseTextEnds;
  }

  List<InlineSpan> _buildVerseSpans(BuildContext context, double fontSize) {
    final bookmarkedColor = Theme.of(context).colorScheme.onPrimaryContainer;
    final markerColor = Theme.of(context).brightness == Brightness.light
        ? AppTheme.quranAyahMarker
        : AppTheme.quranGold;
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
                ? AppTheme.quranAyahMarker
                : AppTheme.quranGold;
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
