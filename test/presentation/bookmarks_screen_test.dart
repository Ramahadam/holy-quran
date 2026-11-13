import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/repositories/bookmark_repository.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/bookmarks_screen.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';

void main() {
  for (final locale in ['en', 'ar']) {
    testWidgets('bookmark actions fit narrow $locale with large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _TestApp(
          locale: Locale(locale),
          textScale: 2,
          overrides: [
            allBookmarksProvider.overrideWith(
              (ref) async => [_bookmark('1:1')],
            ),
            surahListProvider.overrideWith((ref) async => const [_surah]),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('removeBookmark-1:1')), findsOneWidget);
    });
  }

  testWidgets('shows repository excerpts with isolated retry on failure', (
    tester,
  ) async {
    var fail = true;
    await tester.pumpWidget(
      _TestApp(
        overrides: [
          allBookmarksProvider.overrideWith((ref) async => [_bookmark('1:1')]),
          surahListProvider.overrideWith((ref) async => const [_surah]),
          bookmarkVerseProvider.overrideWith((ref, id) async {
            if (fail) throw StateError('excerpt unavailable');
            return const Verse(
              verseId: '1:1',
              surahNumber: 1,
              verseNumber: 1,
              arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            );
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('bookmarkExcerptError-1:1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bookmarkRow-1:1')), findsOneWidget);
    fail = false;
    await tester.tap(find.byKey(const ValueKey('bookmarkExcerptRetry-1:1')));
    await tester.pumpAndSettle();
    expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
  });

  testWidgets('Undo feedback expires automatically', (tester) async {
    final repository = _MemoryBookmarkRepository([_bookmark('1:1')]);
    await tester.pumpWidget(
      _TestApp(
        overrides: [
          bookmarkRepositoryProvider.overrideWithValue(repository),
          surahListProvider.overrideWith((ref) async => const [_surah]),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('removeBookmark-1:1')));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
  });
  testWidgets(
    'lists every bookmark in one scrollable list and opens its VerseID',
    (tester) async {
      final bookmarks = [
        _bookmark('1:1'),
        _bookmark('1:2'),
        _bookmark('1:3'),
        _bookmark('1:4'),
      ];

      await tester.pumpWidget(
        _TestApp(
          overrides: [
            allBookmarksProvider.overrideWith((ref) async => bookmarks),
            surahListProvider.overrideWith((ref) async => const [_surah]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('bookmarksList')), findsOneWidget);
      expect(find.byKey(const ValueKey('bookmarkRow-1:4')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bookmarkRow-1:4')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final readingScreen = tester.widget<ReadingScreen>(
        find.byType(ReadingScreen),
      );
      expect(readingScreen.initialVerseId, '1:4');
    },
  );

  testWidgets('shows empty, loading, and error states', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        overrides: [
          allBookmarksProvider.overrideWith((ref) async => const []),
          surahListProvider.overrideWith((ref) async => const [_surah]),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bookmarksEmptyState')), findsOneWidget);

    final pending = Completer<List<Bookmark>>();
    await tester.pumpWidget(
      _TestApp(
        overrides: [
          allBookmarksProvider.overrideWith((ref) => pending.future),
          surahListProvider.overrideWith((ref) async => const [_surah]),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('bookmarksLoadingState')), findsOneWidget);

    await tester.pumpWidget(
      _TestApp(
        overrides: [
          allBookmarksProvider.overrideWith(
            (ref) async => throw StateError('load failed'),
          ),
          surahListProvider.overrideWith((ref) async => const [_surah]),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bookmarksErrorState')), findsOneWidget);
  });

  testWidgets('removing and undoing a bookmark survive list refresh', (
    tester,
  ) async {
    final repository = _MemoryBookmarkRepository([
      _bookmark('1:1'),
      _bookmark('1:2'),
    ]);

    await tester.pumpWidget(
      _TestApp(
        overrides: [
          bookmarkRepositoryProvider.overrideWithValue(repository),
          surahListProvider.overrideWith((ref) async => const [_surah]),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('removeBookmark-1:1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bookmarkRow-1:1')), findsNothing);
    expect(find.byKey(const ValueKey('bookmarkRow-1:2')), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bookmarkRow-1:1')), findsOneWidget);
    expect(repository.bookmarks, contains(_bookmark('1:1')));
  });
}

class _MemoryBookmarkRepository implements BookmarkRepository {
  List<Bookmark> bookmarks;

  _MemoryBookmarkRepository(this.bookmarks);

  @override
  Future<void> addBookmark(String verseId, DateTime timestamp) async {
    await saveBookmark(Bookmark(verseId: verseId, timestamp: timestamp));
  }

  @override
  Future<List<Bookmark>> getAllBookmarks() async => List.of(bookmarks);

  @override
  Future<Set<String>> getBookmarkedVerseIdsBySurah(int surahNumber) async =>
      bookmarks
          .where((bookmark) => bookmark.verseId.startsWith('$surahNumber:'))
          .map((bookmark) => bookmark.verseId)
          .toSet();

  @override
  Future<List<Bookmark>> getRecentBookmarks({int limit = 3}) async =>
      bookmarks.take(limit).toList();

  @override
  Future<void> removeBookmark(String verseId) async {
    bookmarks = bookmarks.where((item) => item.verseId != verseId).toList();
  }

  @override
  Future<void> replaceAllBookmarks(List<Bookmark> bookmarks) async {
    this.bookmarks = List.of(bookmarks);
  }

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {
    bookmarks = [
      ...bookmarks.where((item) => item.verseId != bookmark.verseId),
      bookmark,
    ];
  }
}

Bookmark _bookmark(String verseId) =>
    Bookmark(verseId: verseId, timestamp: DateTime.utc(2026, 1, 1));

const _surah = Surah(
  surahNumber: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'The Opening',
  numberOfVerses: 7,
);

class _TestApp extends StatelessWidget {
  final List<Override> overrides;
  final Locale locale;
  final double textScale;

  const _TestApp({
    required this.overrides,
    this.locale = const Locale('en'),
    this.textScale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        bookmarkVerseProvider.overrideWith((ref, id) async => null),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const BookmarksScreen(),
      ),
    );
  }
}
