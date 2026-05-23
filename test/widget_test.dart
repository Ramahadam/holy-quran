import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:holy_quran_app/presentation/app.dart';
import 'package:holy_quran_app/presentation/screens/loading_screen.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
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
      expect(find.textContaining('Could not open the database'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('LoadingScreen', () {
    testWidgets('shows loading indicator while data is loading', (tester) async {
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
      expect(find.textContaining('Preparing your Digital Sanctuary'), findsOneWidget);
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
          ],
          child: const MaterialApp(home: LoadingScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('HomeScreen', () {
    testWidgets('shows surah list when data is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
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
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to load surahs'), findsOneWidget);
    });
  });

  group('ReadingScreen', () {
    testWidgets('shows verse list when data is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
          ],
          child: const MaterialApp(
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VerseCard), findsOneWidget);
      expect(find.text('بِسْمِ اللَّهِ'), findsOneWidget);
    });

    testWidgets('shows error state when verse load fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            versesBySurahProvider(1)
                .overrideWith((ref) => Future.error('db error')),
          ],
          child: const MaterialApp(
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to load verses'), findsOneWidget);
    });
  });

  group('SurahTile', () {
    testWidgets('renders Arabic name, English name and verse count',
        (tester) async {
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
  });
}
