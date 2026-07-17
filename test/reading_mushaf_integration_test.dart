import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:holy_quran_app/data/repositories/bookmark_repository.dart';
import 'package:holy_quran_app/data/repositories/reading_position_repository.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';
import 'package:holy_quran_app/presentation/screens/verse_detail_screen.dart';
import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';

const _alFatihah = Surah(
  surahNumber: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'The Opening',
  numberOfVerses: 7,
);

const _alBaqarah = Surah(
  surahNumber: 2,
  nameArabic: 'البقرة',
  nameEnglish: 'The Cow',
  numberOfVerses: 286,
);

const _verse1 = Verse(
  verseId: '1:1',
  surahNumber: 1,
  verseNumber: 1,
  arabicText: 'بِسْمِ اللَّهِ',
  translation: 'In the name of Allah',
  page: 1,
);

void main() {
  testWidgets('single tap on the Mushaf page toggles immersive controls', (
    tester,
  ) async {
    await _pumpReading(tester);
    await _enterMushaf(tester);

    expect(find.byType(AppBar), findsNothing);
    var pageRect = tester.getRect(
      find.byKey(const ValueKey('canonicalMushafPageSurface')),
    );
    await tester.tapAt(pageRect.center);
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
    pageRect = tester.getRect(
      find.byKey(const ValueKey('canonicalMushafPageSurface')),
    );
    await tester.tapAt(pageRect.center);
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('Mushaf long press opens verse detail and persists bookmark', (
    tester,
  ) async {
    final bookmarks = _MemoryBookmarkRepository();
    await _pumpReading(tester, bookmarkRepository: bookmarks);
    await _enterMushaf(tester);

    var qcfPage = tester.widget<MushafQcfPage>(find.byType(MushafQcfPage));
    expect(qcfPage.onTap, isNull);
    qcfPage.onLongPress!.call(1, 1);
    await tester.pumpAndSettle();

    expect(find.byType(VerseDetailScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Bookmark verse'));
    await tester.pumpAndSettle();
    expect(bookmarks.verseIds, {'1:1'});

    Navigator.of(tester.element(find.byType(VerseDetailScreen))).pop();
    await tester.pumpAndSettle();

    qcfPage = tester.widget<MushafQcfPage>(find.byType(MushafQcfPage));
    expect(qcfPage.bookmarkedVerseIds, contains('1:1'));
  });

  testWidgets('entering Mushaf prefetches both adjacent pages', (tester) async {
    var page2Loads = 0;
    var page4Loads = 0;
    const page3Verse = Verse(
      verseId: '2:6',
      surahNumber: 2,
      verseNumber: 6,
      arabicText: 'إِنَّ ٱلَّذِينَ كَفَرُوا',
      page: 3,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingPositionRepositoryProvider.overrideWithValue(
            _MemoryReadingPositionRepository(),
          ),
          startPageForSurahProvider(2).overrideWith((ref) async => 3),
          classicVersesProvider(2).overrideWith((ref) async => [page3Verse]),
          versesByPageProvider(3).overrideWith((ref) async => [page3Verse]),
          versesByPageProvider(2).overrideWith((ref) async {
            page2Loads += 1;
            return [page3Verse];
          }),
          versesByPageProvider(4).overrideWith((ref) async {
            page4Loads += 1;
            return [page3Verse];
          }),
          bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(home: ReadingScreen(surah: _alBaqarah)),
      ),
    );
    await tester.pumpAndSettle();

    expect(page2Loads, 0);
    expect(page4Loads, 0);
    await _enterMushaf(tester);
    await tester.pump();

    expect(page2Loads, 1);
    expect(page4Loads, 1);

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    controller.jumpToPage(3);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(MushafSamplePage), findsWidgets);
  });

  testWidgets('paging saves the first verse on the new Mushaf page', (
    tester,
  ) async {
    final positions = _MemoryReadingPositionRepository();
    const page2Verse = Verse(
      verseId: '2:1',
      surahNumber: 2,
      verseNumber: 1,
      arabicText: 'الم',
      page: 2,
    );

    await _pumpReading(
      tester,
      positionRepository: positions,
      extraOverrides: [
        versesByPageProvider(2).overrideWith((ref) async => [page2Verse]),
      ],
    );
    await _enterMushaf(tester);

    final pageView = tester.widget<PageView>(find.byType(PageView));
    pageView.controller!.jumpToPage(1);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(positions.savedPosition?.verseId, '2:1');
  });

  testWidgets('returning to a cached page saves that page first verse', (
    tester,
  ) async {
    final positions = _MemoryReadingPositionRepository();
    const page3Verse = Verse(
      verseId: '2:6',
      surahNumber: 2,
      verseNumber: 6,
      arabicText: 'إِنَّ ٱلَّذِينَ كَفَرُوا',
      page: 3,
    );
    const page4Verse = Verse(
      verseId: '2:17',
      surahNumber: 2,
      verseNumber: 17,
      arabicText: 'مَثَلُهُمْ كَمَثَلِ ٱلَّذِى',
      page: 4,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingPositionRepositoryProvider.overrideWithValue(positions),
          startPageForSurahProvider(2).overrideWith((ref) async => 3),
          classicVersesProvider(2).overrideWith((ref) async => [page3Verse]),
          for (final page in const [2, 3, 5])
            versesByPageProvider(
              page,
            ).overrideWith((ref) async => [page3Verse]),
          versesByPageProvider(4).overrideWith((ref) async => [page4Verse]),
          bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(home: ReadingScreen(surah: _alBaqarah)),
      ),
    );
    await tester.pumpAndSettle();
    await _enterMushaf(tester);

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    controller.jumpToPage(3);
    await tester.pumpAndSettle();
    controller.jumpToPage(2);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(positions.savedPosition?.verseId, '2:6');
  });

  test('adjacent-page prefetch stays inside the 604-page Mushaf', () {
    expect(mushafAdjacentPagesFor(1), [2]);
    expect(mushafAdjacentPagesFor(300), [299, 301]);
    expect(mushafAdjacentPagesFor(604), [603]);
  });
}

Future<void> _pumpReading(
  WidgetTester tester, {
  _MemoryBookmarkRepository? bookmarkRepository,
  _MemoryReadingPositionRepository? positionRepository,
  List<Override> extraOverrides = const [],
}) async {
  final bookmarks = bookmarkRepository ?? _MemoryBookmarkRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bookmarkRepositoryProvider.overrideWithValue(bookmarks),
        readingPositionRepositoryProvider.overrideWithValue(
          positionRepository ?? _MemoryReadingPositionRepository(),
        ),
        startPageForSurahProvider(1).overrideWith((ref) async => 1),
        classicVersesProvider(1).overrideWith((ref) async => [_verse1]),
        versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
        bookmarksBySurahProvider(
          1,
        ).overrideWith((ref) => bookmarks.idsForSurah(1)),
        ...extraOverrides,
      ],
      child: const MaterialApp(home: ReadingScreen(surah: _alFatihah)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterMushaf(WidgetTester tester) async {
  await tester.tap(find.text('Mushaf'));
  await tester.pump();
  await tester.pump();
}

class _MemoryBookmarkRepository implements BookmarkRepository {
  final Set<String> verseIds = {};

  Future<Set<String>> idsForSurah(int surahNumber) async =>
      verseIds.where((verseId) => verseId.startsWith('$surahNumber:')).toSet();

  @override
  Future<void> addBookmark(String verseId, DateTime timestamp) async {
    verseIds.add(verseId);
  }

  @override
  Future<void> removeBookmark(String verseId) async {
    verseIds.remove(verseId);
  }

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {
    verseIds.add(bookmark.verseId);
  }

  @override
  Future<List<Bookmark>> getAllBookmarks() async => const [];

  @override
  Future<Set<String>> getBookmarkedVerseIdsBySurah(int surahNumber) =>
      idsForSurah(surahNumber);

  @override
  Future<List<Bookmark>> getRecentBookmarks({int limit = 3}) async => const [];

  @override
  Future<void> replaceAllBookmarks(List<Bookmark> bookmarks) async {
    verseIds
      ..clear()
      ..addAll(bookmarks.map((bookmark) => bookmark.verseId));
  }
}

class _MemoryReadingPositionRepository implements ReadingPositionRepository {
  ReadingPosition? savedPosition;

  @override
  Future<void> clearPosition() async => savedPosition = null;

  @override
  Future<ReadingPosition?> getLastPosition() async => savedPosition;

  @override
  Future<void> savePosition(ReadingPosition position) async {
    savedPosition = position;
  }
}
