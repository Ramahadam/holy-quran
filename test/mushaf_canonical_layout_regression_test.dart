import 'dart:ui' show BoxHeightStyle;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/qcf_quran.dart';

import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';

const _canonicalPageAspectRatio = 382.68 / 547.09;

void main() {
  setUpAll(() async {
    await (FontLoader(
      mushafSurahTitleFontFamily,
    )..addFont(rootBundle.load('assets/fonts/UthmanicHafs_V22.ttf'))).load();

    for (final page in const [1, 2, 3, 446, 452, 456, 604]) {
      final pageName = page.toString().padLeft(3, '0');
      await (FontLoader('packages/qcf_quran/QCF_P$pageName')..addFont(
            rootBundle.load(
              'packages/qcf_quran/assets/fonts/qcf4/'
              'QCF4${page.toString().padLeft(3, '0')}_X-Regular.woff',
            ),
          ))
          .load();
    }
  });

  group('canonical Mushaf composition', () {
    testWidgets(
      'expands severe phone letterboxing and keeps the canonical fallback',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        for (final size in const [
          Size(320, 568),
          Size(360, 800),
          Size(430, 932),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MushafSamplePage(key: ValueKey(size), page: 3),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final surface = tester.getRect(
            find.byKey(const ValueKey('canonicalMushafPageSurface')),
          );
          expect(surface.width, closeTo(size.width, .01));
          expect(surface.height, closeTo(size.height, .01));
        }

        for (final size in const [
          Size(599, 800),
          Size(800, 1280),
          Size(800, 360),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MushafSamplePage(key: ValueKey(size), page: 3),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final surface = tester.getRect(
            find.byKey(const ValueKey('canonicalMushafPageSurface')),
          );
          expect(
            surface.width / surface.height,
            closeTo(_canonicalPageAspectRatio, .001),
            reason: 'Mushaf fallback changed at $size.',
          );

          final expectedScale = math.min(
            size.width / canonicalMushafPageSize.width,
            size.height / canonicalMushafPageSize.height,
          );
          final expectedSize = canonicalMushafPageSize * expectedScale;
          expect(
            surface.width,
            closeTo(expectedSize.width, .01),
            reason: 'Mushaf fallback was not contain-scaled at $size.',
          );
          expect(
            surface.height,
            closeTo(expectedSize.height, .01),
            reason: 'Mushaf fallback was not contain-scaled at $size.',
          );
        }
      },
    );

    testWidgets('ignores system font scaling on representative pages', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 720);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final baselineParagraphSizes = <int, Size>{};
      final baselineLineCounts = <int, int>{};
      for (final textScale in const [1.0, 1.2, 1.5, 2.0]) {
        for (final page in const [1, 2, 3, 446, 452, 456, 604]) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 720),
                  textScaler: TextScaler.linear(textScale),
                ),
                child: Scaffold(
                  body: MushafSamplePage(
                    key: ValueKey('$page-$textScale'),
                    page: page,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final pageTextFinder = find.byKey(ValueKey('mushafPageText-$page'));
          final pageText = tester.widget<Text>(pageTextFinder);
          expect(
            pageText.textScaler,
            TextScaler.noScaling,
            reason:
                'System font scaling must not repaginate Mushaf page $page.',
          );

          final paragraph = tester.renderObject<RenderParagraph>(
            pageTextFinder,
          );
          final lineCount = _renderedLineCount(paragraph);
          final baselineSize = baselineParagraphSizes[page];
          final baselineLineCount = baselineLineCounts[page];
          if (baselineSize == null || baselineLineCount == null) {
            baselineParagraphSizes[page] = paragraph.size;
            baselineLineCounts[page] = lineCount;
          } else {
            expect(
              paragraph.size,
              baselineSize,
              reason: 'Text scale $textScale changed page $page geometry.',
            );
            expect(
              lineCount,
              baselineLineCount,
              reason: 'Text scale $textScale changed page $page line count.',
            );
          }

          final plainText = paragraph.text.toPlainText(
            includeSemanticsLabels: false,
          );
          final finalGlyphOffset = plainText.trimRight().length - 1;
          final finalGlyphBoxes = paragraph.getBoxesForSelection(
            TextSelection(
              baseOffset: finalGlyphOffset,
              extentOffset: finalGlyphOffset + 1,
            ),
          );
          final surface = tester.getRect(
            find.byKey(const ValueKey('canonicalMushafPageSurface')),
          );
          expect(finalGlyphBoxes, isNotEmpty);
          expect(
            paragraph.localToGlobal(Offset(0, finalGlyphBoxes.last.bottom)).dy,
            lessThanOrEqualTo(surface.bottom + .5),
            reason:
                'Page $page clipped its final glyph at text scale $textScale.',
          );
          expect(tester.takeException(), isNull);
        }
      }

      for (final page in const [3, 446, 452, 456, 604]) {
        expect(
          baselineLineCounts[page],
          15,
          reason: 'Page $page must keep its 15 printed lines.',
        );
      }
    });

    testWidgets('uses no hidden scroll fallback inside a Mushaf page', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MushafSamplePage(page: 452))),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MushafSamplePage),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
    });

    test('representative pages keep their canonical verse boundaries', () {
      expect(getPageData(3), const [
        {'surah': 2, 'start': 6, 'end': 16},
      ]);
      expect(getPageData(446), const [
        {'surah': 37, 'start': 1, 'end': 24},
      ]);
      expect(getPageData(452), const [
        {'surah': 37, 'start': 154, 'end': 182},
      ]);
      expect(getPageData(456), const [
        {'surah': 38, 'start': 43, 'end': 61},
      ]);
      expect(getPageData(604), const [
        {'surah': 112, 'start': 1, 'end': 4},
        {'surah': 113, 'start': 1, 'end': 5},
        {'surah': 114, 'start': 1, 'end': 6},
      ]);
    });

    test('QCF page ranges cover every Quran verse exactly once', () {
      final verseIds = <String>[];
      int? previousSurah;
      int? previousVerse;

      for (var page = 1; page <= 604; page += 1) {
        final ranges = getPageData(page);
        expect(ranges, isNotEmpty, reason: 'Page $page has no verse range.');

        for (final range in ranges) {
          final surah = int.parse(range['surah'].toString());
          final start = int.parse(range['start'].toString());
          final end = int.parse(range['end'].toString());
          expect(start, lessThanOrEqualTo(end));

          for (var verse = start; verse <= end; verse += 1) {
            if (previousSurah != null && previousVerse != null) {
              if (surah == previousSurah) {
                expect(
                  verse,
                  previousVerse + 1,
                  reason:
                      'Verse $surah:$verse is not contiguous on page $page.',
                );
              } else {
                expect(surah, previousSurah + 1);
                expect(verse, 1);
                expect(previousVerse, getVerseCount(previousSurah));
              }
            }
            verseIds.add('$surah:$verse');
            previousSurah = surah;
            previousVerse = verse;
          }
        }
      }

      expect(verseIds, hasLength(6236));
      expect(verseIds.toSet(), hasLength(6236));
      expect(verseIds.first, '1:1');
      expect(verseIds.last, '114:6');
    });
  });
}

int _renderedLineCount(RenderParagraph paragraph) {
  final textLength = paragraph.text
      .toPlainText(includeSemanticsLabels: false)
      .trimRight()
      .length;
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: textLength),
    boxHeightStyle: BoxHeightStyle.max,
  );
  final lineTops = <double>[];
  for (final box in boxes) {
    if (lineTops.every((top) => (top - box.top).abs() > .5)) {
      lineTops.add(box.top);
    }
  }
  return lineTops.length;
}
