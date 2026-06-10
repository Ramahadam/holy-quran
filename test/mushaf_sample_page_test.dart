import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/qcf_quran.dart';

import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';

void main() {
  group('mushafContentScaleForPage', () {
    test('lets regular reading pages grow to use tall screens', () {
      final scale = mushafContentScaleForPage(
        pageNumber: 3,
        contentHeight: 1200,
      );

      expect(scale, 1.18);
    });

    test('keeps opening pages from stretching sparse content', () {
      final scale = mushafContentScaleForPage(
        pageNumber: 1,
        contentHeight: 1200,
      );

      expect(scale, 1.0);
    });

    test('keeps very short layouts readable', () {
      final scale = mushafContentScaleForPage(
        pageNumber: 300,
        contentHeight: 400,
      );

      expect(scale, .62);
    });
  });

  group('mushafQcfVerseEndsWithLineBreak', () {
    test('detects QCF verses that should end the printed line', () {
      expect(mushafQcfVerseEndsWithLineBreak(surah: 2, verse: 45), isTrue);
    });

    test('does not force line breaks when QCF data keeps the line open', () {
      expect(mushafQcfVerseEndsWithLineBreak(surah: 2, verse: 46), isFalse);
    });
  });

  group('mushafPageStartsWithSurah', () {
    test('detects opening pages that already render a Surah title', () {
      expect(mushafPageStartsWithSurah(pageNumber: 1), isTrue);
      expect(mushafPageStartsWithSurah(pageNumber: 2), isTrue);
    });

    test('detects regular continuation pages', () {
      expect(mushafPageStartsWithSurah(pageNumber: 3), isFalse);
    });
  });

  group('inserted Bismillah sizing', () {
    test('compacts spacing only on dense late Juz 30 pages', () {
      expect(mushafInsertedBasmalaTextScaleForPage(594), 1.16);
      expect(mushafInsertedBasmalaTextScaleForPage(595), 1.08);
      expect(mushafInsertedBasmalaTextScaleForPage(600), 1.08);
      expect(mushafInsertedBasmalaTextScaleForPage(601), 1.16);
    });

    test('reduces Bismillah line height on dense late Juz 30 pages', () {
      expect(mushafInsertedBasmalaLineHeightForPage(594), closeTo(2.332, .001));
      expect(mushafInsertedBasmalaLineHeightForPage(595), 1.9);
      expect(mushafInsertedBasmalaLineHeightForPage(600), 1.9);
      expect(mushafInsertedBasmalaLineHeightForPage(601), closeTo(2.332, .001));
    });
  });

  group('mushafJuzLabel', () {
    test('renders late juz names without shifting the order', () {
      expect(mushafJuzLabel(27), 'الجزء السابع والعشرون');
      expect(mushafJuzLabel(30), 'الجزء الثلاثون');
    });

    test('falls back to Arabic numerals for unexpected juz values', () {
      expect(mushafJuzLabel(31), 'الجزء ٣١');
    });
  });

  group('MushafQcfPage chrome', () {
    test('keeps page header compact and reserves matching top space', () {
      expect(mushafPageHeaderHeight, 56);
      expect(mushafPageContentTopInset, mushafPageHeaderHeight);
    });

    testWidgets('renders decorated header metadata and footer page number', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 360,
            height: 760,
            child: MushafQcfPage(
              pageNumber: 3,
              theme: QcfThemeData(
                pageBackgroundColor: Colors.transparent,
                verseTextColor: Colors.black,
                verseNumberColor: Colors.black,
              ),
            ),
          ),
        ),
      );

      expect(find.text('surah002'), findsOneWidget);
      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(find.text('٣'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mushafHeaderBackground')),
        findsOneWidget,
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('mushafHeaderBackground')))
            .height,
        mushafPageHeaderHeight,
      );

      final dividerCenter = tester.getCenter(
        find.byKey(const ValueKey('mushafHeaderDivider')),
      );
      final surahSlotCenter = tester.getCenter(
        find.byKey(const ValueKey('mushafHeaderSurahSlot')),
      );
      final juzSlotCenter = tester.getCenter(
        find.byKey(const ValueKey('mushafHeaderJuzSlot')),
      );
      final pageRect = tester.getRect(find.byType(MushafQcfPage));
      expect(dividerCenter.dx, closeTo(pageRect.center.dx, 1));
      expect(
        surahSlotCenter.dx,
        closeTo(pageRect.left + pageRect.width * .25, 1),
      );
      expect(
        juzSlotCenter.dx,
        closeTo(pageRect.left + pageRect.width * .75, 1),
      );
    });

    testWidgets('uses the decorated header on pages that start a surah', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 360,
            height: 760,
            child: MushafQcfPage(
              pageNumber: 1,
              theme: QcfThemeData(
                pageBackgroundColor: Colors.transparent,
                verseTextColor: Colors.black,
                verseNumberColor: Colors.black,
              ),
            ),
          ),
        ),
      );

      expect(find.text('surah001'), findsOneWidget);
      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mushafHeaderBackground')),
        findsOneWidget,
      );
      expect(find.byType(HeaderWidget), findsNothing);
    });
  });
}
