import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran/qcf_quran.dart';

import 'mushaf_sample_page.dart';

const _mushafPageContextStripHeight = 32.0;

class MushafReaderChrome extends StatefulWidget {
  final int pageNumber;
  final bool showControls;
  final bool showPageNumber;
  final PreferredSizeWidget appBar;
  final Widget reader;
  final VoidCallback onShowControls;

  const MushafReaderChrome({
    super.key,
    required this.pageNumber,
    required this.showControls,
    required this.showPageNumber,
    required this.appBar,
    required this.reader,
    required this.onShowControls,
  });

  @override
  State<MushafReaderChrome> createState() => _MushafReaderChromeState();
}

class _MushafReaderChromeState extends State<MushafReaderChrome> {
  @override
  void initState() {
    super.initState();
    _scheduleSystemUiUpdate();
  }

  @override
  void didUpdateWidget(covariant MushafReaderChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showControls != widget.showControls) {
      _scheduleSystemUiUpdate();
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _scheduleSystemUiUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(
        widget.showControls
            ? SystemUiMode.edgeToEdge
            : SystemUiMode.immersiveSticky,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showControls ? widget.appBar : null,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.showControls ? null : widget.onShowControls,
              child: _MushafPageContextStrip(pageNumber: widget.pageNumber),
            ),
            Expanded(
              child: Stack(
                children: [
                  widget.reader,
                  if (widget.showPageNumber)
                    _MushafPageNumberOverlay(pageNumber: widget.pageNumber),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = colors.surface.withValues(alpha: .9);

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
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
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
                                  color: colors.onSurface,
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
                              color: colors.onSurface,
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
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = colors.surface.withValues(alpha: .92);

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
              border: Border.all(color: colors.outlineVariant),
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
                  color: colors.onSurface,
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
