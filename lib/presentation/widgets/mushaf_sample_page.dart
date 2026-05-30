import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';
// ignore: implementation_imports
import 'package:qcf_quran/src/data/quran_text.dart';

import '../theme/app_theme.dart';
import 'mushaf_hit_testing.dart';

class MushafSampleAssets {
  static const Set<int> sampleCoordinatePages = {1, 2, 3, 604};
  static const String coordinatesPath =
      'assets/mushaf/madani-svg-sample/coordinates.sample.json';

  static bool containsPage(int page) => page >= 1 && page <= 604;

  static String svgPathForPage(int page) {
    final pageName = page.toString().padLeft(3, '0');
    return 'assets/mushaf/madani-svg-sample/$pageName.svg';
  }

  static String imagePathForPage(int page) {
    final pageName = page.toString().padLeft(3, '0');
    return 'assets/mushaf/madani-images/$pageName.png';
  }

  /// Check if full-color image asset exists for the page
  static bool hasImageForPage(int page) {
    return false;
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
    basmalaColor: AppTheme.islamicGreen,
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
        _MushafPageHeader(pageNumber: pageNumber),
        LayoutBuilder(
          builder: (context, constraints) {
            final contentHeight =
                constraints.maxHeight - _headerInset - _bottomInset;
            final mediaQuery = MediaQuery.of(context);

            return Padding(
              padding: const EdgeInsets.only(
                top: _headerInset,
                bottom: _bottomInset,
              ),
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  size: Size(constraints.maxWidth, contentHeight),
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: _InspiredQcfPage(
                  pageNumber: pageNumber,
                  theme: theme,
                  sp: _scale,
                  h: _heightScale,
                  onTap: onTap,
                  onLongPress: onLongPress,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static const double _headerInset = 54;
  static const double _bottomInset = 12;

  double get _scale {
    if (pageNumber == 1) return 1.16;
    if (pageNumber == 2) return 1.06;
    return 1.03;
  }

  double get _heightScale {
    if (pageNumber == 1) return 1.06;
    if (pageNumber == 2) return 1.02;
    return 1.0;
  }
}

class _MushafPageHeader extends StatelessWidget {
  final int pageNumber;

  const _MushafPageHeader({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final pageData = getPageData(pageNumber);
    final first = pageData.first;
    final surah = int.parse(first['surah'].toString());
    final verse = int.parse(first['start'].toString());
    final juz = getJuzNumber(surah, verse);
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF2B2113),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.1,
    );

    return Positioned(
      top: 13,
      left: 22,
      right: 22,
      height: 34,
      child: CustomPaint(
        painter: _MushafHeaderRulePainter(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MushafHeaderLabel(
                  text: 'سورة ${getSurahNameArabic(surah)}',
                  style: textStyle,
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                width: 34,
                height: 28,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFFBF2),
                  border: Border.all(color: const Color(0xFF8A7A55)),
                ),
                child: Text(
                  convertToArabicNumber(pageNumber.toString()),
                  style: textStyle?.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _MushafHeaderLabel(
                  text: _juzLabel(juz),
                  style: textStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _juzLabel(int juz) {
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
}

class _MushafHeaderLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const _MushafHeaderLabel({
    required this.text,
    required this.style,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Align(
        alignment: textAlign == TextAlign.left
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _MushafHeaderRulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8A7A55)
      ..strokeWidth = .8;
    canvas.drawLine(
      Offset(0, size.height - 3),
      Offset(size.width, size.height - 3),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height - 3),
      1.8,
      Paint()..color = const Color(0xFF8A7A55),
    );
  }

  @override
  bool shouldRepaint(covariant _MushafHeaderRulePainter oldDelegate) {
    return false;
  }
}

class _InspiredQcfPage extends StatelessWidget {
  final int pageNumber;
  final QcfThemeData theme;
  final double sp;
  final double h;
  final void Function(int surahNumber, int verseNumber)? onTap;
  final void Function(int surahNumber, int verseNumber)? onLongPress;

  const _InspiredQcfPage({
    required this.pageNumber,
    required this.theme,
    required this.sp,
    required this.h,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ranges = getPageData(pageNumber);
    final pageFont = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
    final baseFontSize = getFontSize(pageNumber, context) * sp;
    final screenSize = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final verseSpans = <InlineSpan>[];

    if (pageNumber == 1 || pageNumber == 2) {
      verseSpans.add(
        WidgetSpan(child: SizedBox(height: screenSize.height * .175)),
      );
    }

    for (final r in ranges) {
      final surah = int.parse(r['surah'].toString());
      final start = int.parse(r['start'].toString());
      final end = int.parse(r['end'].toString());

      for (var verse = start; verse <= end; verse += 1) {
        if (verse == start && verse == 1) {
          if (theme.showHeader) {
            verseSpans.add(
              WidgetSpan(
                child: HeaderWidget(suraNumber: surah, theme: theme),
              ),
            );
          }
          if (theme.showBasmala && pageNumber != 1 && pageNumber != 187) {
            verseSpans.add(
              TextSpan(
                text: ' ﱁ  ﱂﱃﱄ\n',
                style: TextStyle(
                  fontFamily: 'QCF_P001',
                  package: 'qcf_quran',
                  fontSize: getScreenType(context) == ScreenType.large
                      ? theme.basmalaFontSizeLarge * sp
                      : theme.basmalaFontSizeSmall * sp,
                  color: theme.basmalaColor,
                ),
              ),
            );
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
                    : (pageNumber == 1 || pageNumber == 2)
                    ? 20 * sp
                    : baseFontSize - (17 * sp),
                color: theme.verseTextColor,
                height: isPortrait
                    ? (pageNumber == 1 || pageNumber == 2)
                          ? 2.2 * h
                          : theme.verseHeight * h
                    : 4 * h,
                letterSpacing: theme.letterSpacing,
                wordSpacing: theme.wordSpacing,
              ),
            ),
          ],
        ),
      ),
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
              ? const TextStyle(color: Color(0xFFB34437))
              : null,
        ),
      );
    }

    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: SizedBox(
          width: 32 * sp,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _AyahNumberMarker(
              number: verse,
              size: 20 * sp,
              onTap: onTap == null ? null : () => onTap?.call(surah, verse),
              onLongPress: onLongPress == null
                  ? null
                  : () => onLongPress?.call(surah, verse),
            ),
          ),
        ),
      ),
    );

    return spans;
  }

  GestureRecognizer? _verseRecognizer(int surah, int verse) {
    if (onTap != null) {
      return TapGestureRecognizer()..onTap = () => onTap?.call(surah, verse);
    }
    if (onLongPress != null) {
      return LongPressGestureRecognizer()
        ..onLongPress = () => onLongPress?.call(surah, verse);
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

class _AyahNumberMarker extends StatelessWidget {
  final int number;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _AyahNumberMarker({
    required this.number,
    required this.size,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final marker = CustomPaint(
      painter: const _AyahNumberMarkerPainter(),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            _toArabicDigits(number),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF2F2416),
              fontSize: size * (number < 100 ? .48 : .36),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );

    if (onTap == null && onLongPress == null) return marker;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: marker,
    );
  }

  static String _toArabicDigits(int value) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return value
        .toString()
        .split('')
        .map((char) => digits[int.parse(char)])
        .join();
  }
}

class _AyahNumberMarkerPainter extends CustomPainter {
  const _AyahNumberMarkerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;
    final fill = Paint()
      ..color = const Color(0xFFF1ECD9)
      ..style = PaintingStyle.fill;
    final ring = Paint()
      ..color = const Color(0xFF6E552D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;
    final innerRing = Paint()
      ..color = const Color(0xFFB8A06B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius - 3.2, innerRing);
  }

  @override
  bool shouldRepaint(covariant _AyahNumberMarkerPainter oldDelegate) => false;
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
