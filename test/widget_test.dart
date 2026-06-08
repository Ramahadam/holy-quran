import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:holy_quran_app/presentation/app.dart';
import 'package:holy_quran_app/presentation/screens/loading_screen.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';
import 'package:holy_quran_app/presentation/screens/verse_detail_screen.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/data/repositories/bookmark_repository.dart';
import 'package:holy_quran_app/data/repositories/reading_position_repository.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';
import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';
import 'package:holy_quran_app/presentation/widgets/surah_tile.dart';
import 'package:holy_quran_app/presentation/widgets/verse_card.dart';

const _surah1 = Surah(
  surahNumber: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'The Opening',
  numberOfVerses: 7,
);

const _verse1 = Verse(
  verseId: '1:1',
  surahNumber: 1,
  verseNumber: 1,
  arabicText: 'بِسْمِ اللَّهِ',
  translation: 'In the name of Allah',
);

const _verse2 = Verse(
  verseId: '1:2',
  surahNumber: 1,
  verseNumber: 2,
  arabicText: 'ٱلْحَمْدُ لِلَّهِ',
  translation: 'Praise be to Allah',
);

const _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

class _FakeBookmarkRepository implements BookmarkRepository {
  final addedVerseIds = <String>[];
  final removedVerseIds = <String>[];

  @override
  Future<void> addBookmark(String verseId, DateTime timestamp) async {
    addedVerseIds.add(verseId);
  }

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {}

  @override
  Future<void> removeBookmark(String verseId) async {
    removedVerseIds.add(verseId);
  }

  @override
  Future<List<Bookmark>> getAllBookmarks() async => const [];

  @override
  Future<List<Bookmark>> getRecentBookmarks({int limit = 3}) async => const [];

  @override
  Future<Set<String>> getBookmarkedVerseIdsBySurah(int surahNumber) async => {};

  @override
  Future<void> replaceAllBookmarks(List<Bookmark> bookmarks) async {}
}

class _FakeReadingPositionRepository implements ReadingPositionRepository {
  ReadingPosition? savedPosition;

  @override
  Future<void> clearPosition() async {
    savedPosition = null;
  }

  @override
  Future<ReadingPosition?> getLastPosition() async => savedPosition;

  @override
  Future<void> savePosition(ReadingPosition position) async {
    savedPosition = position;
  }
}

void main() {
  group('HolyQuranApp', () {
    testWidgets('renders MaterialApp', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: HolyQuranApp()));
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('DatabaseErrorApp', () {
    testWidgets('shows database error message', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: DatabaseErrorApp()));
      await tester.pump();
      expect(
        find.textContaining('Could not open the database'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('LoadingScreen', () {
    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      final completer = Completer<void>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializeDataProvider.overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(home: LoadingScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.textContaining('Preparing your Digital Sanctuary'),
        findsOneWidget,
      );
      // Resolve to avoid pending-microtask assertion on teardown.
      completer.complete();
    });

    testWidgets('shows error UI when initialization fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializeDataProvider.overrideWith(
              (ref) => Future.error('init failed'),
            ),
          ],
          child: const MaterialApp(home: LoadingScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Failed to load data'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('navigates to HomeScreen when data loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializeDataProvider.overrideWith((ref) async {}),
            surahListProvider.overrideWith((ref) async => []),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: LoadingScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('MushafSamplePage', () {
    test('supports the full QCF Mushaf page range', () {
      expect(MushafSampleAssets.containsPage(1), isTrue);
      expect(MushafSampleAssets.containsPage(2), isTrue);
      expect(MushafSampleAssets.containsPage(3), isTrue);
      expect(MushafSampleAssets.containsPage(604), isTrue);
      expect(MushafSampleAssets.containsPage(605), isFalse);
    });

    testWidgets('renders a QCF font Mushaf page', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MushafSamplePage(page: 1))),
      );
      await tester.pump();

      expect(find.byType(MushafQcfPage), findsOneWidget);
      expect(find.text('surah001'), findsOneWidget);
      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mushafHeaderBackground')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits opening Mushaf page on a compact mobile viewport', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(720, 1280);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MushafSamplePage(page: 1))),
      );
      await tester.pumpAndSettle();

      final bodyTextFinder = find.byWidgetPredicate((widget) {
        if (widget is! Text) return false;
        return widget.data == null && widget.textSpan is TextSpan;
      });

      expect(bodyTextFinder, findsOneWidget);
      final bodyText = tester.widget<Text>(bodyTextFinder);
      expect(bodyText.style?.fontSize, lessThan(22));

      final paragraphFinder = find.descendant(
        of: bodyTextFinder,
        matching: find.byType(RichText),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        paragraphFinder.first,
      );

      expect(
        paragraph.getMaxIntrinsicHeight(paragraph.size.width),
        lessThanOrEqualTo(tester.getSize(bodyTextFinder).height),
      );
    });

    testWidgets('explains unsupported page numbers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MushafSamplePage(page: 605))),
      );
      await tester.pump();

      expect(find.textContaining('between 1 and 604'), findsOneWidget);
      expect(find.textContaining('Current page: 605'), findsOneWidget);
    });
  });

  group('HomeScreen', () {
    testWidgets('shows surah list when data is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SurahTile), findsOneWidget);
      expect(find.text('The Opening'), findsOneWidget);
    });

    testWidgets('shows empty state when surah list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => []),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No surahs found.'), findsOneWidget);
    });

    testWidgets('shows error state when load fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) => Future.error('db error')),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to load surahs'), findsOneWidget);
    });

    testWidgets('shows Last Read banner when a reading position exists', (
      tester,
    ) async {
      final position = ReadingPosition(
        verseId: '1:3',
        lastReadAt: DateTime(2026, 5, 24),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => position),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue Reading'), findsOneWidget);
      expect(find.textContaining('The Opening'), findsWidgets);
      expect(find.textContaining('Verse 3'), findsOneWidget);
    });

    testWidgets('does not show Last Read banner when no position saved', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue Reading'), findsNothing);
    });

    testWidgets('tapping Last Read banner navigates to ReadingScreen', (
      tester,
    ) async {
      final position = ReadingPosition(
        verseId: '1:1',
        lastReadAt: DateTime(2026, 5, 24),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => position),
            recentBookmarksProvider.overrideWith((ref) async => const []),
            pageForVerseProvider('1:1').overrideWith((ref) async => 1),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue Reading'));
      await tester.pumpAndSettle();
      expect(find.byType(ReadingScreen), findsOneWidget);
    });

    testWidgets('shows bookmarks and removes one from the home screen', (
      tester,
    ) async {
      final repo = _FakeBookmarkRepository();
      final bookmark = Bookmark(
        verseId: '1:1',
        timestamp: DateTime(2026, 5, 24),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkRepositoryProvider.overrideWithValue(repo),
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => [bookmark]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {'1:1'}),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bookmarks'), findsOneWidget);
      expect(find.text('The Opening · Verse 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove bookmark'));
      await tester.pump();

      expect(repo.removedVerseIds, ['1:1']);
    });
  });

  group('ReadingScreen', () {
    testWidgets('renders with initialVerseId without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pageForVerseProvider('1:1').overrideWith((ref) async => 1),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(
            home: ReadingScreen(surah: _surah1, initialVerseId: '1:1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
    });

    testWidgets('shows verse list when data is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
    });

    testWidgets('switches between Classic and Mushaf modes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
      expect(find.byType(MushafQcfPage), findsNothing);

      await tester.tap(find.text('Mushaf'));
      await tester.pumpAndSettle();

      expect(find.byType(MushafQcfPage), findsOneWidget);
      expect(find.textContaining('بِسْمِ', findRichText: true), findsNothing);

      await tester.tapAt(const Offset(12, 12));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Classic'));
      await tester.pumpAndSettle();

      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
    });

    testWidgets('saves tapped Mushaf verse as the last-read VerseID', (
      tester,
    ) async {
      final positionRepo = _FakeReadingPositionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingPositionRepositoryProvider.overrideWithValue(positionRepo),
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [_verse1, _verse2]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mushaf'));
      await tester.pumpAndSettle();

      final qcfPage = tester.widget<MushafQcfPage>(find.byType(MushafQcfPage));
      qcfPage.onTap?.call(1, 2);
      await tester.pumpAndSettle();

      expect(find.byType(VerseDetailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(positionRepo.savedPosition?.verseId, '1:2');
    });

    testWidgets('opens Focus Mode from a Classic verse long press', (
      tester,
    ) async {
      final positionRepo = _FakeReadingPositionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingPositionRepositoryProvider.overrideWithValue(positionRepo),
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [_verse1, _verse2]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.textContaining('بِسْمِ', findRichText: true));
      await tester.pumpAndSettle();

      expect(find.byType(VerseDetailScreen), findsOneWidget);
      expect(find.text('1:1'), findsOneWidget);
      expect(find.text('In the name of Allah'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(positionRepo.savedPosition?.verseId, '1:1');
    });

    testWidgets('uses KFGQPC font for Arabic Quran text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      expect(
        (richText.text as TextSpan).style?.fontFamily,
        'KFGQPCHafsUthmanicScript',
      );
    });

    testWidgets(
      'uses the Al-Fatihah Bismillah treatment when verse data includes it',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              startPageForSurahProvider(1).overrideWith((ref) async => 1),
              versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
              bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
            ],
            child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
          ),
        );
        await tester.pumpAndSettle();
        final richText = tester.widget<RichText>(
          find.textContaining('بِسْمِ', findRichText: true),
        );
        final children = (richText.text as TextSpan).children!;
        expect(children.first.style?.color, isNull);
        expect(children.first.style?.fontSize, 28);
        expect(children.first.style?.height, 2.0);
      },
    );

    testWidgets('styles only the Bismillah phrase when more text follows', (
      tester,
    ) async {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: '$_bismillah ٱلْحَمْدُ لِلَّهِ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesByPageProvider(1).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      final children = (richText.text as TextSpan).children!;
      final bismillahSpan = children[0] as TextSpan;
      final remainingTextSpan = children[1] as TextSpan;
      expect(bismillahSpan.text, _bismillah);
      expect(bismillahSpan.style?.color, isNull);
      expect(bismillahSpan.style?.fontSize, 28);
      expect(bismillahSpan.style?.height, 2.0);
      expect(remainingTextSpan.text, ' ٱلْحَمْدُ لِلَّهِ');
      expect(remainingTextSpan.style, isNull);
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
              versesByPageProvider(2).overrideWith((ref) async => [verse]),
              bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
              surahListProvider.overrideWith((ref) async => [surah2]),
            ],
            child: const MaterialApp(home: ReadingScreen(surah: surah2)),
          ),
        );
        await tester.pumpAndSettle();
        final bismillah = tester.widget<Text>(find.text(_bismillah));
        expect(bismillah.style?.color, AppTheme.textPrimary);
        expect(bismillah.style?.fontSize, 28);
        expect(bismillah.style?.height, 2.0);
      },
    );

    testWidgets('does not repeat Bismillah on continuation pages', (
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
            versesByPageProvider(4).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [surah2]),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: surah2)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_bismillah), findsNothing);
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
        arabicText: 'بَرَآءَةٌ مِّنَ ٱللَّهِ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(9).overrideWith((ref) async => 187),
            versesByPageProvider(187).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(9).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [surah9]),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: surah9)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_bismillah), findsNothing);
    });

    testWidgets('shows error state when verse load fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesByPageProvider(
              1,
            ).overrideWith((ref) => Future.error('db error')),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
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
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {'1:1'}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      expect((richText.text as TextSpan).style?.color, AppTheme.islamicGreen);
    });

    testWidgets('does not show bookmark icon for unbookmarked verse', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: ReadingScreen(surah: _surah1)),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      expect((richText.text as TextSpan).style?.color, AppTheme.textPrimary);
    });
  });

  group('SurahTile', () {
    testWidgets('renders Arabic name, English name and verse count', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurahTile(surah: _surah1, onTap: () => tapped = true),
          ),
        ),
      );
      expect(find.text('الفاتحة'), findsOneWidget);
      expect(find.text('The Opening'), findsOneWidget);
      expect(find.text('7 verses'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byType(SurahTile));
      expect(tapped, isTrue);
    });
  });

  group('VerseCard', () {
    testWidgets('renders Arabic text and translation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VerseCard(verse: _verse1)),
        ),
      );
      expect(find.text('بِسْمِ اللَّهِ'), findsOneWidget);
      expect(find.text('In the name of Allah'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders without translation when null', (tester) async {
      const verse = Verse(
        verseId: '2:1',
        surahNumber: 2,
        verseNumber: 1,
        arabicText: 'الم',
        translation: null,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VerseCard(verse: verse)),
        ),
      );
      expect(find.text('الم'), findsOneWidget);
    });

    testWidgets('shows bookmark icon when isBookmarked is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VerseCard(verse: _verse1, isBookmarked: true)),
        ),
      );
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('hides bookmark icon when isBookmarked is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VerseCard(verse: _verse1, isBookmarked: false)),
        ),
      );
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('calls onBookmarkToggle on long press', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseCard(
              verse: _verse1,
              onBookmarkToggle: () => toggled = true,
            ),
          ),
        ),
      );
      final topLeft = tester.getTopLeft(find.byType(VerseCard));
      await tester.longPressAt(topLeft + const Offset(10, 10));
      expect(toggled, isTrue);
    });
  });

  group('VerseDetailScreen', () {
    testWidgets('renders large Quran text and translation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: VerseDetailScreen(verse: _verse1)),
        ),
      );
      await tester.pumpAndSettle();

      final arabicText = tester.widget<Text>(find.text(_verse1.arabicText));
      expect(arabicText.style?.fontSize, 36);
      expect(find.text('In the name of Allah'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('can bookmark the focused verse locally', (tester) async {
      final bookmarkRepo = _FakeBookmarkRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkRepositoryProvider.overrideWithValue(bookmarkRepo),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(home: VerseDetailScreen(verse: _verse1)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();

      expect(bookmarkRepo.addedVerseIds, ['1:1']);
    });
  });
}
