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
    test('uses smaller Bismillah text throughout Juz 30', () {
      expect(mushafInsertedBasmalaTextScaleForPage(581), 1.16);
      expect(mushafInsertedBasmalaTextScaleForPage(582), 1.0);
      expect(mushafInsertedBasmalaTextScaleForPage(600), 1.0);
      expect(mushafInsertedBasmalaTextScaleForPage(604), 1.0);
    });

    test('uses tighter Bismillah line height throughout Juz 30', () {
      expect(mushafInsertedBasmalaLineHeightForPage(581), closeTo(2.332, .001));
      expect(mushafInsertedBasmalaLineHeightForPage(582), 1.72);
      expect(mushafInsertedBasmalaLineHeightForPage(600), 1.72);
      expect(mushafInsertedBasmalaLineHeightForPage(604), 1.72);
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
      expect(mushafPageHeaderHeight, 57);
      expect(mushafPageContentTopInset, mushafPageHeaderHeight);
      expect(mushafSingleSlotChromeHeight, mushafPageHeaderHeight);
      expect(mushafSurahTitleFontSize, 18);
      expect(mushafSurahTitleFontFamily, 'KFGQPCHafsUthmanicScript');
      expect(mushafJuzTitleFontSize, 18);
    });

    testWidgets('renders decorated header metadata without footer chrome', (
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

      expect(find.text(getSurahNameArabic(2)), findsOneWidget);
      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(getSurahNameArabic(2))).style?.fontSize,
        mushafSurahTitleFontSize,
      );
      expect(
        tester.widget<Text>(find.text(getSurahNameArabic(2))).style?.fontFamily,
        mushafSurahTitleFontFamily,
      );
      expect(
        tester.widget<Text>(find.text(getSurahNameArabic(2))).style?.color,
        tester.widget<Text>(find.text('الجزء الأول')).style?.color,
      );
      expect(
        tester.widget<Text>(find.text(getSurahNameArabic(2))).style?.fontWeight,
        tester.widget<Text>(find.text('الجزء الأول')).style?.fontWeight,
      );
      expect(
        tester.widget<Text>(find.text('الجزء الأول')).style?.fontSize,
        mushafJuzTitleFontSize,
      );
      expect(
        tester.widget<Text>(find.text('الجزء الأول')).style?.fontWeight,
        FontWeight.w700,
      );
      expect(
        find.byKey(const ValueKey('mushafFooterSingleSlotChrome')),
        findsNothing,
      );
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

      expect(find.text(getSurahNameArabic(1)), findsOneWidget);
      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mushafHeaderBackground')),
        findsOneWidget,
      );
      expect(find.byType(HeaderWidget), findsNothing);
    });

    testWidgets('uses single-slot decoration for middle surah openings', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 360,
            height: 760,
            child: MushafQcfPage(
              pageNumber: 595,
              theme: QcfThemeData(
                pageBackgroundColor: Colors.transparent,
                verseTextColor: Colors.black,
                verseNumberColor: Colors.black,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mushafInlineSurahHeader')),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('mushafSingleSlotChromeBackground')),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.data?.startsWith('surah') == true,
        ),
        findsNothing,
      );
      final surahTitleTexts = tester.widgetList<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('mushafInlineSurahHeader')),
          matching: find.byType(Text),
        ),
      );
      expect(surahTitleTexts, isNotEmpty);
      for (final title in surahTitleTexts) {
        expect(title.data, isNotNull);
        expect(title.data!.contains(RegExp(r'[\u0600-\u06FF]')), isTrue);
        expect(title.style?.fontSize, mushafSurahTitleFontSize);
        expect(title.style?.fontFamily, mushafSurahTitleFontFamily);
        expect(title.style?.color, const Color(0xFF2B2113));
        expect(title.style?.fontWeight, FontWeight.w700);
        expect(title.textDirection, TextDirection.rtl);
      }
      expect(find.byType(HeaderWidget), findsNothing);
    });
  });
}
