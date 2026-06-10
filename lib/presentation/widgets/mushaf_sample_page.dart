import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';
// ignore: implementation_imports
import 'package:qcf_quran/src/data/quran_text.dart';

import '../theme/app_theme.dart';
import 'mushaf_hit_testing.dart';

const _qcfBasmalaFontFamily = 'QCF_P001';
const _referenceBasmalaTextScale = 1.16;
const _referenceBasmalaHeightScale = 1.06;
const _compactBasmalaTextScale = 1.08;
const _compactBasmalaLineHeight = 1.9;
const _allahHighlightColor = Color(0xFFB34437);

@visibleForTesting
const double mushafPageHeaderHeight = 56;

@visibleForTesting
const double mushafPageContentTopInset = mushafPageHeaderHeight;

class MushafSampleAssets {
  static const Set<int> sampleCoordinatePages = {1, 2, 3, 604};
  static const String coordinatesPath =
      'assets/mushaf/madani-svg-sample/coordinates.sample.json';

  static bool containsPage(int page) => page >= 1 && page <= 604;

  static String svgPathForPage(int page) {
    final pageName = page.toString().padLeft(3, '0');
    return 'assets/mushaf/madani-svg-sample/$pageName.svg';
  }
}

class MushafSamplePage extends StatefulWidget {
  static const double aspectRatio = 382.68 / 547.09;

  final int page;
  final ValueChanged<MushafHitResult>? onHit;
  final ValueChanged<String>? onVerseTap;

  const MushafSamplePage({
    super.key,
    required this.page,
    this.onHit,
    this.onVerseTap,
  });

  @override
  State<MushafSamplePage> createState() => _MushafSamplePageState();
}

class _MushafSamplePageState extends State<MushafSamplePage> {
  final GlobalKey _pageKey = GlobalKey();
  Future<MushafCoordinateRepository>? _coordinateRepository;

  Future<MushafCoordinateRepository> _loadCoordinateRepository() {
    return _coordinateRepository ??= MushafCoordinateRepository.loadFromAsset(
      DefaultAssetBundle.of(context),
      MushafSampleAssets.coordinatesPath,
    );
  }

  Future<void> _handleTapUp(TapUpDetails details) async {
    if (widget.onHit == null) return;

    final renderObject = _pageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final normalizedPoint = MushafPageGeometry.normalizedPoint(
      localPosition: renderObject.globalToLocal(details.globalPosition),
      size: renderObject.size,
    );
    if (normalizedPoint == null) return;

    final repository = await _loadCoordinateRepository();
    if (!mounted) return;

    final hit = repository.hitTest(
      page: widget.page,
      normalizedPoint: normalizedPoint,
    );
    if (hit != null) widget.onHit?.call(hit);
  }

  @override
  Widget build(BuildContext context) {
    if (!MushafSampleAssets.containsPage(widget.page)) {
      return _UnsupportedMushafSamplePage(page: widget.page);
    }

    return ColoredBox(
      color: AppTheme.mushafBackground,
      child: SafeArea(
        child: SizedBox.expand(
          child: GestureDetector(
            key: _pageKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: _handleTapUp,
            child: MushafQcfPage(
              pageNumber: widget.page,
              theme: _qcfTheme,
              onTap: (surahNumber, verseNumber) {
                widget.onVerseTap?.call('$surahNumber:$verseNumber');
              },
              onLongPress: (surahNumber, verseNumber) {
                widget.onVerseTap?.call('$surahNumber:$verseNumber');
              },
            ),
          ),
        ),
      ),
    );
  }

  QcfThemeData get _qcfTheme => const QcfThemeData(
    pageBackgroundColor: Colors.transparent,
    verseTextColor: Color(0xFF17120C),
    verseNumberColor: Color(0xFF4D3518),
    basmalaColor: Color(0xFF17120C),
    headerTextColor: Color(0xFF17120C),
    headerBackgroundColor: Color(0x00FFFFFF),
    verseHeight: 2.08,
    letterSpacing: 0,
    wordSpacing: 0,
    headerBorderRadius: 8,
  );
}

class MushafQcfPage extends StatelessWidget {
  final int pageNumber;
  final QcfThemeData theme;
  final void Function(int surahNumber, int verseNumber)? onTap;
  final void Function(int surahNumber, int verseNumber)? onLongPress;

  const MushafQcfPage({
    super.key,
    required this.pageNumber,
    required this.theme,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _MushafPageFrame(),
        LayoutBuilder(
          builder: (context, constraints) {
            final contentHeight =
                constraints.maxHeight - _contentTopInset - _contentBottomInset;
            final contentWidth =
                constraints.maxWidth - (_contentHorizontalInset * 2);
            final contentScale = mushafContentScaleForPage(
              pageNumber: pageNumber,
              contentHeight: contentHeight,
            );
            final mediaQuery = MediaQuery.of(context);

            return Padding(
              padding: const EdgeInsets.only(
                top: _contentTopInset,
                left: _contentHorizontalInset,
                right: _contentHorizontalInset,
                bottom: _contentBottomInset,
              ),
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  size: Size(contentWidth, contentHeight),
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: _InspiredQcfPage(
                  pageNumber: pageNumber,
                  theme: theme,
                  sp: _scale * contentScale,
                  h: _heightScale,
                  contentScale: contentScale,
                  onTap: onTap,
                  onLongPress: onLongPress,
                ),
              ),
            );
          },
        ),
        _MushafPageHeader(pageNumber: pageNumber),
        _MushafPageFooter(pageNumber: pageNumber),
      ],
    );
  }

  // Tuning knobs for the empty space between the frame and the Quran text.
  static const double _contentTopInset = mushafPageContentTopInset;
  static const double _contentHorizontalInset = 0;
  static const double _contentBottomInset = 0;

  double get _scale {
    if (pageNumber == 1) return 1.16;
    if (pageNumber == 2) return 1.06;
    return 1.08;
  }

  double get _heightScale {
    if (pageNumber == 1) return 1.06;
    if (pageNumber == 2) return 1.02;
    return 1.0;
  }
}

@visibleForTesting
double mushafContentScaleForPage({
  required int pageNumber,
  required double contentHeight,
}) {
  const referenceContentHeight = 848.0;
  const minimumContentScale = .62;
  const maximumOpeningPageScale = 1.0;
  const maximumReadingPageScale = 1.18;

  final maximumScale = pageNumber == 1 || pageNumber == 2
      ? maximumOpeningPageScale
      : maximumReadingPageScale;
  final scale = contentHeight / referenceContentHeight;
  if (scale > maximumScale) return maximumScale;
  if (scale < minimumContentScale) return minimumContentScale;
  return scale;
}

@visibleForTesting
bool mushafPageStartsWithSurah({required int pageNumber}) {
  final first = getPageData(pageNumber).first;
  return int.parse(first['start'].toString()) == 1;
}

@visibleForTesting
double mushafInsertedBasmalaTextScaleForPage(int pageNumber) {
  if (_usesCompactInsertedBasmala(pageNumber)) {
    return _compactBasmalaTextScale;
  }
  return _referenceBasmalaTextScale;
}

@visibleForTesting
double mushafInsertedBasmalaLineHeightForPage(int pageNumber) {
  if (_usesCompactInsertedBasmala(pageNumber)) {
    return _compactBasmalaLineHeight;
  }
  return 2.2 * _referenceBasmalaHeightScale;
}

bool _usesCompactInsertedBasmala(int pageNumber) {
  return pageNumber >= 595 && pageNumber <= 600;
}

@visibleForTesting
String mushafJuzLabel(int juz) {
  const names = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرون',
    'الحادي والعشرون',
    'الثاني والعشرون',
    'الثالث والعشرون',
    'الرابع والعشرون',
    'الخامس والعشرون',
    'السادس والعشرون',
    'السابع والعشرون',
    'الثامن والعشرون',
    'التاسع والعشرون',
    'الثلاثون',
  ];

  if (juz >= 1 && juz <= names.length) {
    return 'الجزء ${names[juz - 1]}';
  }
  return 'الجزء ${convertToArabicNumber(juz.toString())}';
}

class _MushafPageHeader extends StatelessWidget {
  final int pageNumber;

  const _MushafPageHeader({required this.pageNumber});

  static const double _height = mushafPageHeaderHeight;
  static const String _backgroundAsset =
      'assets/mushaf/chrome/quran_header_surah_juzah_empty_slots_v2.png';

  @override
  Widget build(BuildContext context) {
    final pageData = getPageData(pageNumber);
    final first = pageData.first;
    final surah = int.parse(first['surah'].toString());
    final verse = int.parse(first['start'].toString());
    final juz = getJuzNumber(surah, verse);
    final surahStyle = TextStyle(
      color: const Color(0xFF2B2113),
      fontFamily: SurahFontHelper.fontFamily,
      package: 'qcf_quran',
      fontSize: 18,
      height: 1,
    );
    final metaStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF2B2113),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: _height,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _backgroundAsset,
              key: const ValueKey('mushafHeaderBackground'),
              fit: BoxFit.fill,
            ),
            Transform.translate(
              offset: const Offset(0, 1),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      key: const ValueKey('mushafHeaderSurahSlot'),
                      padding: const EdgeInsetsDirectional.only(
                        start: 28,
                        end: 34,
                      ),
                      child: Center(
                        child: Text(
                          'surah${surah.toString().padLeft(3, '0')}',
                          style: surahStyle,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      key: const ValueKey('mushafHeaderJuzSlot'),
                      padding: const EdgeInsetsDirectional.only(
                        start: 34,
                        end: 28,
                      ),
                      child: Center(
                        child: Text(
                          mushafJuzLabel(juz),
                          style: metaStyle,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                key: const ValueKey('mushafHeaderDivider'),
                width: 1,
                height: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafPageFooter extends StatelessWidget {
  final int pageNumber;

  const _MushafPageFooter({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF2B2113),
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1,
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 34,
      child: _MushafFrameBand(
        horizontalPadding: 18,
        child: Center(
          child: Text(
            convertToArabicNumber(pageNumber.toString()),
            style: textStyle,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _MushafFrameBand extends StatelessWidget {
  final Widget child;
  final double horizontalPadding;

  const _MushafFrameBand({required this.child, this.horizontalPadding = 12});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/mainframe.png',
          package: 'qcf_quran',
          fit: BoxFit.fill,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ],
    );
  }
}

class _InspiredQcfPage extends StatefulWidget {
  final int pageNumber;
  final QcfThemeData theme;
  final double sp;
  final double h;
  final double contentScale;
  final void Function(int surahNumber, int verseNumber)? onTap;
  final void Function(int surahNumber, int verseNumber)? onLongPress;

  const _InspiredQcfPage({
    required this.pageNumber,
    required this.theme,
    required this.sp,
    required this.h,
    required this.contentScale,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<_InspiredQcfPage> createState() => _InspiredQcfPageState();
}

class _InspiredQcfPageState extends State<_InspiredQcfPage> {
  final Map<String, GestureRecognizer> _recognizers = {};

  @override
  void didUpdateWidget(covariant _InspiredQcfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.onTap != widget.onTap ||
        oldWidget.onLongPress != widget.onLongPress) {
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
    final ranges = getPageData(widget.pageNumber);
    final pageFont = 'QCF_P${widget.pageNumber.toString().padLeft(3, '0')}';
    final baseFontSize = getFontSize(widget.pageNumber, context) * widget.sp;
    final screenSize = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final theme = _scaledTheme(widget.theme, widget.contentScale);
    final verseSpans = <InlineSpan>[];
    final pageStartsWithSurah = mushafPageStartsWithSurah(
      pageNumber: widget.pageNumber,
    );

    if (widget.pageNumber == 1 || widget.pageNumber == 2) {
      verseSpans.add(
        WidgetSpan(
          child: SizedBox(
            height: screenSize.height * .175 * widget.contentScale,
          ),
        ),
      );
    }

    for (final r in ranges) {
      final surah = int.parse(r['surah'].toString());
      final start = int.parse(r['start'].toString());
      final end = int.parse(r['end'].toString());

      for (var verse = start; verse <= end; verse += 1) {
        if (verse == start && verse == 1) {
          final isPageOpeningSurah = pageStartsWithSurah && r == ranges.first;
          if (widget.theme.showHeader && !isPageOpeningSurah) {
            verseSpans.add(
              WidgetSpan(
                child: HeaderWidget(suraNumber: surah, theme: theme),
              ),
            );
          }
          if (widget.theme.showBasmala &&
              widget.pageNumber != 1 &&
              widget.pageNumber != 187) {
            verseSpans.addAll(_buildInsertedBasmalaSpans(context));
          }
        }

        verseSpans.addAll(
          _buildVerseSpans(
            surah: surah,
            verse: verse,
            isFirstVerseOnPage: verse == ranges[0]['start'],
            pageFont: pageFont,
          ),
        );
      }
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Text.rich(
              TextSpan(children: verseSpans),
              locale: const Locale('ar'),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: pageFont,
                package: 'qcf_quran',
                fontSize: isPortrait
                    ? baseFontSize
                    : (widget.pageNumber == 1 || widget.pageNumber == 2)
                    ? 20 * widget.sp
                    : baseFontSize - (17 * widget.sp),
                color: widget.theme.verseTextColor,
                height: isPortrait
                    ? (widget.pageNumber == 1 || widget.pageNumber == 2)
                          ? 2.2 * widget.h
                          : widget.theme.verseHeight * widget.h
                    : 4 * widget.h,
                letterSpacing: widget.theme.letterSpacing,
                wordSpacing: widget.theme.wordSpacing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  QcfThemeData _scaledTheme(QcfThemeData theme, double scale) {
    if (scale >= .999) return theme;

    return theme.copyWith(
      headerWidthLarge: theme.headerWidthLarge * scale,
      headerWidthSmall: theme.headerWidthSmall * scale,
      headerFontSizeLarge: theme.headerFontSizeLarge * scale,
      headerFontSizeSmall: theme.headerFontSizeSmall * scale,
    );
  }

  List<InlineSpan> _buildVerseSpans({
    required int surah,
    required int verse,
    required bool isFirstVerseOnPage,
    required String pageFont,
  }) {
    final recognizer = _verseRecognizer(surah, verse);
    final verseText = getVerseQCF(surah, verse, verseEndSymbol: false);
    final displayText = isFirstVerseOnPage && verseText.isNotEmpty
        ? '${verseText.substring(0, 1)}\u200A${verseText.substring(1)}'
        : verseText;
    final allahGlyphIndexes = _allahGlyphIndexes(surah, verse, displayText);
    final spans = <InlineSpan>[];

    for (var i = 0; i < displayText.length; i += 1) {
      final char = displayText[i];
      spans.add(
        TextSpan(
          text: char,
          recognizer: recognizer,
          style: allahGlyphIndexes.contains(i)
              ? const TextStyle(color: _allahHighlightColor)
              : null,
        ),
      );
    }

    spans.add(
      TextSpan(
        text: getVerseNumberQCF(surah, verse),
        recognizer: recognizer,
        style: TextStyle(
          fontFamily: pageFont,
          package: 'qcf_quran',
          color: widget.theme.verseNumberColor,
          height: widget.theme.verseNumberHeight * widget.h,
        ),
      ),
    );

    if (mushafQcfVerseEndsWithLineBreak(surah: surah, verse: verse)) {
      spans.add(TextSpan(text: '\n', recognizer: recognizer));
    }

    return spans;
  }

  List<InlineSpan> _buildInsertedBasmalaSpans(BuildContext context) {
    final verseText = getVerseQCF(1, 1, verseEndSymbol: false);
    final displayText =
        '${verseText.substring(0, 1)}\u200A${verseText.substring(1)}';
    final allahGlyphIndexes = _allahGlyphIndexes(1, 1, displayText);
    final fontSize =
        getFontSize(1, context) *
        mushafInsertedBasmalaTextScaleForPage(widget.pageNumber) *
        widget.contentScale;
    final lineHeight = mushafInsertedBasmalaLineHeightForPage(
      widget.pageNumber,
    );
    final spans = <InlineSpan>[];

    for (var i = 0; i < displayText.length; i += 1) {
      spans.add(
        TextSpan(
          text: displayText[i],
          style: TextStyle(
            fontFamily: _qcfBasmalaFontFamily,
            package: 'qcf_quran',
            fontSize: fontSize,
            height: lineHeight,
            color: allahGlyphIndexes.contains(i) ? _allahHighlightColor : null,
          ),
        ),
      );
    }

    spans.add(const TextSpan(text: '\n'));
    return spans;
  }

  GestureRecognizer? _verseRecognizer(int surah, int verse) {
    if (widget.onTap != null) {
      final key = 'tap:$surah:$verse';
      return _recognizers.putIfAbsent(
        key,
        () =>
            TapGestureRecognizer()
              ..onTap = () => widget.onTap?.call(surah, verse),
      );
    }
    if (widget.onLongPress != null) {
      final key = 'long:$surah:$verse';
      return _recognizers.putIfAbsent(
        key,
        () =>
            LongPressGestureRecognizer()
              ..onLongPress = () => widget.onLongPress?.call(surah, verse),
      );
    }
    return null;
  }

  Set<int> _allahGlyphIndexes(int surah, int verse, String displayText) {
    final normalText = _normalVerseText(surah, verse);
    if (normalText == null) return const {};

    final words = normalText.split(RegExp(r'\s+'));
    final glyphIndexes = <int>[];
    for (var i = 0; i < displayText.length; i += 1) {
      if (displayText[i] != '\n' && displayText[i] != '\u200A') {
        glyphIndexes.add(i);
      }
    }
    if (words.isEmpty || glyphIndexes.isEmpty) return const {};

    final highlighted = <int>{};
    for (var wordIndex = 0; wordIndex < words.length; wordIndex += 1) {
      if (!_isAllahWord(words[wordIndex])) continue;

      final start = (wordIndex / words.length * glyphIndexes.length).floor();
      final end = ((wordIndex + 1) / words.length * glyphIndexes.length).ceil();
      for (var glyph = start; glyph < end; glyph += 1) {
        if (glyph >= 0 && glyph < glyphIndexes.length) {
          highlighted.add(glyphIndexes[glyph]);
        }
      }
    }

    return highlighted;
  }

  String? _normalVerseText(int surah, int verse) {
    for (final row in quranText) {
      if (row['surah_number'] == surah && row['verse_number'] == verse) {
        return row['text_normal']?.toString();
      }
    }
    return null;
  }

  bool _isAllahWord(String word) {
    final normalized = word.replaceAll(RegExp(r'[^\u0600-\u06FF]'), '');
    return normalized.contains('الله');
  }
}

@visibleForTesting
bool mushafQcfVerseEndsWithLineBreak({required int surah, required int verse}) {
  return getVerseQCF(surah, verse).endsWith('\n');
}

class _MushafPageFrame extends StatelessWidget {
  const _MushafPageFrame();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.mushafPage),
      child: CustomPaint(
        painter: _MushafFramePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MushafFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final separatorPaint = Paint()
      ..color = const Color(0xFFB8A67A)
      ..strokeWidth = .8;
    canvas.drawLine(Offset.zero, Offset(0, size.height), separatorPaint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      separatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MushafFramePainter oldDelegate) {
    return false;
  }
}

class _UnsupportedMushafSamplePage extends StatelessWidget {
  final int page;

  const _UnsupportedMushafSamplePage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Mushaf page must be between 1 and 604.\nCurrent page: $page',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
