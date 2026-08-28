import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';
import 'package:holy_quran_app/presentation/screens/verse_detail_screen.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';
import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';

import '../support/reading_test_fixtures.dart';

void main() {
  group('Classic reader', () {
    testWidgets('renders with initialVerseId without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pageForVerseProvider('1:1').overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(
            home: ReadingScreen(surah: classicSurah1, initialVerseId: '1:1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
    });

    testWidgets('keeps a deep Classic bookmark rendered after rebuilds', (
      tester,
    ) async {
      final verses = classicSurahVerses(60);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pageForVerseProvider('1:40').overrideWith((ref) async => 1),
            classicVersesProvider(1).overrideWith((ref) async => verses),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {'1:40'}),
          ],
          child: const MaterialApp(
            home: ReadingScreen(surah: classicSurah1, initialVerseId: '1:40'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bookmarkedVerse = find.textContaining('آية 40', findRichText: true);
      expect(bookmarkedVerse, findsOneWidget);
      expect(tester.getTopLeft(bookmarkedVerse).dy, lessThan(200));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows verse list when data is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
    });

    testWidgets(
      'uses the bundled Quran font for comfortable Classic typography',
      (tester) async {
        const longVerse = Verse(
          verseId: '1:3',
          surahNumber: 1,
          verseNumber: 3,
          arabicText:
              'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ مَـٰلِكِ يَوْمِ ٱلدِّينِ إِيَّاكَ نَعْبُدُ',
        );

        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 640);
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              startPageForSurahProvider(1).overrideWith((ref) async => 1),
              classicVersesProvider(1).overrideWith((ref) async => [longVerse]),
              bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
                child: ReadingScreen(surah: classicSurah1),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrollView = tester.widget<ListView>(find.byType(ListView));
        final padding = scrollView.padding as EdgeInsets;
        expect(padding.horizontal, 48);

        final richTextFinder = find.textContaining(
          'ٱلرَّحْمَـٰنِ',
          findRichText: true,
        );
        final richText = tester.widget<RichText>(richTextFinder);
        final textSpan = richText.text as TextSpan;
        final style = textSpan.style;
        final markerSpan = textSpan.children!.whereType<TextSpan>().firstWhere(
          (span) => span.text?.contains('٣') ?? false,
        );
        expect(richText.textAlign, TextAlign.justify);
        expect(style?.fontFamily, 'KFGQPCHafsUthmanicScript');
        expect(style?.fontWeight, FontWeight.w400);
        expect(markerSpan.style?.fontFamily, 'KFGQPCHafsUthmanicScript');
        expect(style?.fontSize, closeTo(26.832, .001));
        expect(style?.height, 1.6);
        expect(
          richText.textScaler.scale(style!.fontSize!),
          closeTo(32.1984, .001),
        );
        expect(tester.getSize(richTextFinder).width, 312);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('flows cross-page Classic ayahs in one justified paragraph', (
      tester,
    ) async {
      const firstVerse = Verse(
        verseId: '2:1',
        surahNumber: 2,
        verseNumber: 1,
        arabicText: 'الٓمٓ',
        page: 3,
      );
      const secondVerse = Verse(
        verseId: '2:2',
        surahNumber: 2,
        verseNumber: 2,
        arabicText: 'ذَٰلِكَ ٱلۡكِتَٰبُ',
        page: 2,
      );
      const surah2 = Surah(
        surahNumber: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'The Cow',
        numberOfVerses: 286,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(2).overrideWith((ref) async => 2),
            classicVersesProvider(
              2,
            ).overrideWith((ref) async => [firstVerse, secondVerse]),
            bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [surah2]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: surah2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final richText = tester.widget<RichText>(
        find.textContaining('الٓم', findRichText: true),
      );
      final textSpan = richText.text as TextSpan;

      expect(richText.textAlign, TextAlign.justify);
      expect(textSpan.toPlainText(), 'الٓمٓ\u00a0١ ذَٰلِكَ ٱلۡكِتَٰبُ\u00a0٢ ');
    });

    testWidgets('flows Classic ayahs continuously across ayah 24', (
      tester,
    ) async {
      final verses = classicSurahVerses(25);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(1).overrideWith((ref) async => verses),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: classicSurah1)),
        ),
      );
      await tester.pumpAndSettle();

      final continuousParagraph = find.byWidgetPredicate((widget) {
        if (widget is! RichText) return false;
        final text = widget.text.toPlainText();
        return text.contains('آية 24') && text.contains('آية 25');
      });
      expect(continuousParagraph, findsOneWidget);
    });

    testWidgets('appends one Classic ayah marker when verse text has none', (
      tester,
    ) async {
      const unmarkedVerse = Verse(
        verseId: '1:3',
        surahNumber: 1,
        verseNumber: 3,
        arabicText: 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [unmarkedVerse]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final richText = tester.widget<RichText>(
        find.textContaining('ٱلرَّحْمَـٰنِ', findRichText: true),
      );
      final textSpan = richText.text as TextSpan;
      expect(textSpan.toPlainText(), 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ\u00a0٣ ');
      expect(textSpan.toPlainText(), isNot(contains('﴿')));
      expect(textSpan.toPlainText(), isNot(contains('﴾')));

      final markerSpan = textSpan.children!.whereType<TextSpan>().last;
      expect(markerSpan.text, '\u00a0٣ ');
      expect(markerSpan.style?.color, AppTheme.quranAyahMarker);
      expect(markerSpan.style?.fontWeight, FontWeight.w500);
      expect(
        markerSpan.style?.fontSize,
        greaterThanOrEqualTo(textSpan.style!.fontSize! * 0.85),
      );
      expect(
        markerSpan.style?.fontSize,
        lessThanOrEqualTo(textSpan.style!.fontSize! * 0.9),
      );
      expect(markerSpan.style?.height, 1.0);
    });

    testWidgets('continues Classic scrolling into the next surah', (
      tester,
    ) async {
      const surah2 = Surah(
        surahNumber: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'The Cow',
        numberOfVerses: 1,
      );
      const surah2Verse = Verse(
        verseId: '2:1',
        surahNumber: 2,
        verseNumber: 1,
        arabicText: 'الٓمٓ',
        page: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            versesBySurahProvider(2).overrideWith((ref) async => [surah2Verse]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
            bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
            surahListProvider.overrideWith(
              (ref) async => [classicSurah1, surah2],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('سورة الفاتحة'), findsOneWidget);
      expect(find.text('سورة البقرة'), findsOneWidget);
      expect(find.textContaining('الٓمٓ', findRichText: true), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('opens Classic at the beginning of the selected surah', (
      tester,
    ) async {
      const surah2 = Surah(
        surahNumber: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'The Cow',
        numberOfVerses: 1,
      );
      final surah2Verses = List.generate(
        48,
        (index) => Verse(
          verseId: '2:${index + 1}',
          surahNumber: 2,
          verseNumber: index + 1,
          arabicText: index == 0 ? 'الٓمٓ' : 'آية طويلة للاختبار',
          page: 2 + (index ~/ 6),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(2).overrideWith((ref) async => 2),
            classicVersesProvider(2).overrideWith((ref) async => surah2Verses),
            bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
            surahListProvider.overrideWith(
              (ref) async => [classicSurah1, surah2],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: surah2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<ListView>(find.byType(ListView));
      expect(scrollView.controller!.offset, 0);
      expect(find.textContaining('الٓمٓ', findRichText: true), findsOneWidget);
      expect(find.textContaining('Page 2'), findsOneWidget);
    });

    testWidgets('preserves QPC marks and removes embedded Classic markers', (
      tester,
    ) async {
      const markedVerse = Verse(
        verseId: '1:3',
        surahNumber: 1,
        verseNumber: 3,
        arabicText: '۞ أُو۟لَـٰٓئِكَ ۖ أَنَا۠ أُحْىِۦ ۚ أَلِيمٌۢ بِمَا ۝٣',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(1).overrideWith((ref) async => [markedVerse]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final richText = tester.widget<RichText>(
        find.textContaining('أُو', findRichText: true),
      );
      final text = (richText.text as TextSpan).toPlainText();
      expect(text, 'أُو۟لَـٰٓئِكَ أَنَا۠ أُحْىِۦ أَلِيمٌۢ بِمَا\u00a0٣ ');
      expect(text, isNot(contains('۞')));
      expect(text, isNot(contains('۝')));
      expect(text, isNot(contains('ۖ')));
      expect(text, isNot(contains('ۚ')));
      expect(text, contains('۟'));
      expect(text, contains('۠'));
      expect(text, contains('ۢ'));
      expect(text, isNot(contains('أُو لَـٰٓئِكَ')));
    });

    testWidgets('uses vertical scrolling for Classic and paging for Mushaf', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1, classicVerse2]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1, classicVerse2]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(PageView), findsNothing);

      await tester.tap(find.text('Mushaf'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('uses calm contextual reader chrome in Classic', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(
        find.byKey(const ValueKey('readerAppBar')),
      );
      expect(appBar.preferredSize.height, 68);
      expect(appBar.backgroundColor, AppTheme.light.colorScheme.surface);
      expect(find.byType(SegmentedButton<ReadingMode>), findsNothing);
      expect(find.byKey(const ValueKey('readerHeaderSurah')), findsOneWidget);
      expect(find.byKey(const ValueKey('readerHeaderContext')), findsOneWidget);
      final modeSwitch = tester.widget<TextButton>(
        find.byKey(const ValueKey('readerModeSwitch')),
      );
      expect(
        modeSwitch.style?.foregroundColor?.resolve({}),
        AppTheme.light.colorScheme.primary,
      );
      expect(find.text('Mushaf'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches between Classic and Mushaf modes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
      expect(find.byType(MushafQcfPage), findsNothing);

      await tester.tap(find.text('Mushaf'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(MushafQcfPage), findsOneWidget);
      expect(find.textContaining('بِسْمِ', findRichText: true), findsNothing);

      await tester.tapAt(const Offset(12, 12));
      await tester.pump();

      await tester.tap(find.text('Classic'));
      await tester.pumpAndSettle();

      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
    });

    testWidgets('records local engagement when opening and saving reading', (
      tester,
    ) async {
      final positionRepo = FakeReadingPositionRepository();
      final feedbackPromptService = FakeFeedbackPromptService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingPositionRepositoryProvider.overrideWithValue(positionRepo),
            feedbackPromptServiceProvider.overrideWithValue(
              feedbackPromptService,
            ),
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(positionRepo.savedPosition?.verseId, '1:1');
      expect(feedbackPromptService.recordedSessions, 2);
    });

    testWidgets('opens Focus Mode from a Classic verse long press', (
      tester,
    ) async {
      final positionRepo = FakeReadingPositionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingPositionRepositoryProvider.overrideWithValue(positionRepo),
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1, classicVerse2]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1, classicVerse2]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final verseParagraph = find.textContaining('بِسْمِ', findRichText: true);
      final paragraph = tester.renderObject<RenderParagraph>(verseParagraph);
      final firstVerseBox = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 14),
          )
          .first;
      await tester.longPressAt(
        paragraph.localToGlobal(firstVerseBox.toRect().center),
      );
      await tester.pump();

      expect(find.byType(VerseDetailScreen), findsOneWidget);
      expect(find.text('1:1'), findsOneWidget);
      expect(find.text('In the name of Allah'), findsOneWidget);
      expect(find.text(classicVerse1.arabicText), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(positionRepo.savedPosition?.verseId, '1:1');
    });

    testWidgets('tracks and restores the exact visible Classic verse', (
      tester,
    ) async {
      final positionRepo = FakeReadingPositionRepository();
      const surah2 = Surah(
        surahNumber: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'The Cow',
        numberOfVerses: 3,
      );
      final longVerse2Text = List.filled(48, 'كلمةثانية').join(' ');
      final longVerse5Text = List.filled(64, 'كلمةخامسة').join(' ');
      final verses = [
        classicVerse1,
        Verse(
          verseId: '1:2',
          surahNumber: 1,
          verseNumber: 2,
          arabicText: longVerse2Text,
          page: 1,
        ),
        const Verse(
          verseId: '1:3',
          surahNumber: 1,
          verseNumber: 3,
          arabicText: 'آية قصيرة',
          page: 1,
        ),
        const Verse(
          verseId: '2:1',
          surahNumber: 2,
          verseNumber: 1,
          arabicText: 'الٓمٓ',
          page: 2,
        ),
        Verse(
          verseId: '2:2',
          surahNumber: 2,
          verseNumber: 2,
          arabicText: longVerse5Text,
          page: 2,
        ),
        const Verse(
          verseId: '2:3',
          surahNumber: 2,
          verseNumber: 3,
          arabicText: 'آية ختامية',
          page: 2,
        ),
      ];

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      Future<void> pumpReader({String? initialVerseId}) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              readingPositionRepositoryProvider.overrideWithValue(positionRepo),
              startPageForSurahProvider(1).overrideWith((ref) async => 1),
              if (initialVerseId != null)
                pageForVerseProvider(
                  initialVerseId,
                ).overrideWith((ref) async => 2),
              classicVersesProvider(1).overrideWith((ref) async => verses),
              bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
              bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
              surahListProvider.overrideWith(
                (ref) async => const [classicSurah1, surah2],
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: ReadingScreen(
                surah: classicSurah1,
                initialVerseId: initialVerseId,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> saveWithViewportInside(String verseText) async {
        final paragraphFinder = find.textContaining(
          verseText,
          findRichText: true,
        );
        for (
          var attempt = 0;
          attempt < 20 && paragraphFinder.evaluate().isEmpty;
          attempt++
        ) {
          await tester.drag(find.byType(ListView), const Offset(0, -300));
          await tester.pump();
        }
        expect(paragraphFinder, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(paragraphFinder);
        final plainText = paragraph.text.toPlainText();
        final verseStart = plainText.indexOf(verseText);
        final verseBoxes = paragraph.getBoxesForSelection(
          TextSelection(
            baseOffset: verseStart,
            extentOffset: verseStart + verseText.length,
          ),
        );
        final targetLine = verseBoxes[verseBoxes.length - 2].toRect();
        final listFinder = find.byType(ListView);
        final viewportTop = tester.getTopLeft(listFinder).dy;
        final targetTop = paragraph.localToGlobal(targetLine.topLeft).dy;
        final controller = tester.widget<ListView>(listFinder).controller!;

        controller.jumpTo(
          (controller.offset + targetTop - viewportTop + 2).clamp(
            0,
            controller.position.maxScrollExtent,
          ),
        );
        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }

      await pumpReader();
      await saveWithViewportInside(longVerse2Text);
      expect(positionRepo.savedPosition?.verseId, '1:2');

      positionRepo.savedPosition = null;
      await pumpReader();
      await saveWithViewportInside(longVerse5Text);
      expect(positionRepo.savedPosition?.verseId, '2:2');

      await pumpReader(initialVerseId: positionRepo.savedPosition!.verseId);
      final restoredVerse = find.textContaining(
        longVerse5Text,
        findRichText: true,
      );
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      expect(restoredVerse, findsOneWidget);
      expect(
        tester.getTopLeft(restoredVerse).dy,
        inInclusiveRange(viewport.top, viewport.top + viewport.height * 0.25),
      );
    });

    testWidgets('uses one bundled Quran font for text and Bismillah', (
      tester,
    ) async {
      const qpcBismillahVerse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: classicBismillah,
      );
      const qpcVerse = Verse(
        verseId: '1:2',
        surahNumber: 1,
        verseNumber: 2,
        arabicText: 'ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [qpcBismillahVerse, qpcVerse]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [qpcBismillahVerse, qpcVerse]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bismillah = tester.widget<Text>(
        find.byKey(const ValueKey('classicBismillah')),
      );
      final bismillahSpan = bismillah.textSpan! as TextSpan;
      final verseText = tester.widget<RichText>(
        find.textContaining('ٱلۡحَمۡدُ', findRichText: true),
      );
      final verseSpan = verseText.text as TextSpan;
      expect(bismillahSpan.style?.fontFamily, 'KFGQPCHafsUthmanicScript');
      expect(verseSpan.style?.fontFamily, 'KFGQPCHafsUthmanicScript');
    });

    testWidgets(
      'uses the Al-Fatihah Bismillah treatment when verse data includes it',
      (tester) async {
        const qpcBismillahVerse = Verse(
          verseId: '1:1',
          surahNumber: 1,
          verseNumber: 1,
          arabicText: classicBismillah,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              startPageForSurahProvider(1).overrideWith((ref) async => 1),
              classicVersesProvider(
                1,
              ).overrideWith((ref) async => [qpcBismillahVerse]),
              bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: ReadingScreen(surah: classicSurah1),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bismillah = tester.widget<Text>(
          find.byKey(const ValueKey('classicBismillah')),
        );
        final rootSpan = bismillah.textSpan! as TextSpan;
        expect(rootSpan.style?.fontFamily, 'KFGQPCHafsUthmanicScript');
        expect(rootSpan.style?.fontSize, 28);
        expect(rootSpan.style?.height, 1.7);
      },
    );

    testWidgets('highlights Allah in the separated Classic Bismillah', (
      tester,
    ) async {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: '$classicBismillah ٱلْحَمْدُ لِلَّهِ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(1).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bismillah = tester.widget<Text>(
        find.byKey(const ValueKey('classicBismillah')),
      );
      final rootSpan = bismillah.textSpan! as TextSpan;
      final allahSpan = rootSpan.children![1] as TextSpan;
      expect(rootSpan.style?.fontSize, 28);
      expect(rootSpan.style?.height, 1.7);
      expect(allahSpan.text, 'ٱللَّهِ');
      expect(allahSpan.style?.color, AppTheme.quranRed);

      final verseParagraph = tester.widget<RichText>(
        find.textContaining('ٱلْحَمْدُ', findRichText: true),
      );
      expect(
        verseParagraph.text.toPlainText(),
        isNot(contains(classicBismillah)),
      );

      await tester.longPress(find.byKey(const ValueKey('classicBismillah')));
      await tester.pumpAndSettle();
      expect(find.byType(VerseDetailScreen), findsOneWidget);
      expect(find.text('1:1'), findsOneWidget);
    });

    testWidgets(
      'shows Bismillah before Surahs except Al-Fatihah and At-Tawbah',
      (tester) async {
        const surah2 = Surah(
          surahNumber: 2,
          nameArabic: 'البقرة',
          nameEnglish: 'The Cow',
          numberOfVerses: 286,
        );
        const verse = Verse(
          verseId: '2:1',
          surahNumber: 2,
          verseNumber: 1,
          arabicText: 'الٓمٓ',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              startPageForSurahProvider(2).overrideWith((ref) async => 2),
              classicVersesProvider(2).overrideWith((ref) async => [verse]),
              bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
              surahListProvider.overrideWith((ref) async => [surah2]),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: ReadingScreen(surah: surah2),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bismillah = tester.widget<Text>(find.text(classicBismillah));
        final context = tester.element(find.text(classicBismillah));
        final rootSpan = bismillah.textSpan! as TextSpan;
        expect(
          rootSpan.style?.color,
          Theme.of(context).textTheme.headlineLarge?.color,
        );
        expect(rootSpan.style?.fontSize, 28);
        expect(rootSpan.style?.height, 1.7);
      },
    );

    testWidgets('uses the approved complete Classic Surah title treatment', (
      tester,
    ) async {
      const surah2 = Surah(
        surahNumber: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'The Cow',
        numberOfVerses: 286,
      );
      const verse = Verse(
        verseId: '2:1',
        surahNumber: 2,
        verseNumber: 1,
        arabicText: 'الٓمٓ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(2).overrideWith((ref) async => 2),
            classicVersesProvider(2).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [surah2]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const ReadingScreen(surah: surah2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final title = find.byKey(const ValueKey('classicSurahTitle'));
      expect(title, findsOneWidget);
      final surahTitleFinder = find.descendant(
        of: title,
        matching: find.text('سورة البقرة'),
      );
      expect(surahTitleFinder, findsOneWidget);
      expect(find.bySemanticsLabel('سورة البقرة'), findsOneWidget);
      final surahTitle = tester.widget<Text>(surahTitleFinder);
      expect(surahTitle.style?.fontSize, 25);
      expect(surahTitle.style?.fontWeight, FontWeight.w600);
      final filledDecorations = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: title, matching: find.byType(DecoratedBox)),
          )
          .map((widget) => widget.decoration)
          .whereType<BoxDecoration>()
          .where((decoration) => decoration.color != null);
      expect(filledDecorations, isEmpty);
      expect(
        find.descendant(of: title, matching: find.byType(Divider)),
        findsNothing,
      );
      expect(tester.getSize(title).height, lessThanOrEqualTo(56));
    });

    testWidgets('separates Al-Fatihah Bismillah from its verse paragraph', (
      tester,
    ) async {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: '$classicBismillah ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(1).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [classicSurah1]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('classicBismillah')), findsOneWidget);
      expect(find.bySemanticsLabel(classicBismillah), findsOneWidget);
      final verseParagraph = tester.widget<RichText>(
        find.textContaining('ٱلْحَمْدُ', findRichText: true),
      );
      expect(
        verseParagraph.text.toPlainText(),
        isNot(contains(classicBismillah)),
      );
    });

    testWidgets('shows Classic Juz dividers at mid-Surah boundaries', (
      tester,
    ) async {
      const surah2 = Surah(
        surahNumber: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'The Cow',
        numberOfVerses: 286,
      );
      const verses = [
        Verse(
          verseId: '2:141',
          surahNumber: 2,
          verseNumber: 141,
          arabicText: 'تِلْكَ أُمَّةٌ قَدْ خَلَتْ',
        ),
        Verse(
          verseId: '2:142',
          surahNumber: 2,
          verseNumber: 142,
          arabicText: 'سَيَقُولُ ٱلسُّفَهَآءُ',
        ),
      ];

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 1000);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(2).overrideWith((ref) async => 21),
            classicVersesProvider(2).overrideWith((ref) async => verses),
            bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [surah2]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const ReadingScreen(surah: surah2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(find.text('الجزء الثاني'), findsOneWidget);
      final juzDivider = find.byKey(const ValueKey('classicJuzDivider-2'));
      expect(juzDivider, findsOneWidget);
      expect(
        find.descendant(of: juzDivider, matching: find.byType(Divider)),
        findsNWidgets(2),
      );
    });

    testWidgets('does not show Bismillah for a continuation verse in Classic', (
      tester,
    ) async {
      const surah2 = Surah(
        surahNumber: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'The Cow',
        numberOfVerses: 286,
      );
      const verse = Verse(
        verseId: '2:20',
        surahNumber: 2,
        verseNumber: 20,
        arabicText: 'يَكَادُ ٱلْبَرْقُ يَخْطَفُ أَبْصَـٰرَهُمْ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(2).overrideWith((ref) async => 4),
            classicVersesProvider(2).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [surah2]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: surah2),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(classicBismillah), findsNothing);
    });

    testWidgets('does not show Bismillah before At-Tawbah', (tester) async {
      const surah9 = Surah(
        surahNumber: 9,
        nameArabic: 'التوبة',
        nameEnglish: 'The Repentance',
        numberOfVerses: 129,
      );
      const verse = Verse(
        verseId: '9:1',
        surahNumber: 9,
        verseNumber: 1,
        arabicText: 'بَرَآءَةٌ مِّنَ ٱللَّهِ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(9).overrideWith((ref) async => 187),
            classicVersesProvider(9).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(9).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [surah9]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: surah9),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(classicBismillah), findsNothing);
    });

    testWidgets('shows error state when verse load fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) => Future.error('db error')),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to load verses'), findsOneWidget);
    });

    testWidgets('shows bookmark icon for bookmarked verse', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {'1:1'}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      final context = tester.element(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      expect(
        (richText.text as TextSpan).style?.color,
        Theme.of(context).colorScheme.onPrimaryContainer,
      );
    });

    testWidgets('does not show bookmark icon for unbookmarked verse', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [classicVerse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: classicSurah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      final context = tester.element(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      expect(
        (richText.text as TextSpan).style?.color,
        Theme.of(context).textTheme.headlineLarge?.color,
      );
    });
  });
}
