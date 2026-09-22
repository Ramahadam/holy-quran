import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/repositories/bookmark_repository.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/bookmarks_screen.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';

void main() {
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

  testWidgets('removing a bookmark refreshes the full list', (tester) async {
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

  const _TestApp({required this.overrides});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BookmarksScreen(),
      ),
    );
  }
}
