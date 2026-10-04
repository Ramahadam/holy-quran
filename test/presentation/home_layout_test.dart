import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/bookmarks_screen.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';
import '../support/reading_test_fixtures.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';

const _surah = Surah(
  surahNumber: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'Al-Fatihah',
  numberOfVerses: 7,
);

Widget _app({
  ReadingPosition? position,
  bool dark = false,
  bool arabic = false,
  double textScale = 1,
}) => ProviderScope(
  overrides: [
    readingPositionRepositoryProvider.overrideWithValue(
      FakeReadingPositionRepository(),
    ),
    feedbackPromptServiceProvider.overrideWithValue(
      FakeFeedbackPromptService(),
    ),
    classicVersesProvider(1).overrideWith((ref) async => classicSurahVerses(7)),
    versesByPageProvider(1).overrideWith((ref) async => classicSurahVerses(7)),
    bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
    surahListProvider.overrideWith((ref) async => const [_surah]),
    lastReadPositionProvider.overrideWith((ref) async => position),
    recentBookmarksProvider.overrideWith((ref) async => const []),
    allBookmarksProvider.overrideWith((ref) async => const []),
    feedbackPromptShouldShowProvider.overrideWith((ref) async => false),
    pageForVerseProvider.overrideWith((ref, id) async => 1),
  ],
  child: MaterialApp(
    locale: Locale(arabic ? 'ar' : 'en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const HomeScreen(),
  ),
);

void main() {
  testWidgets('bottom navigation opens bookmarks even without saved ayahs', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('continueReadingCard')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('homeBookmarksDestination')));
    await tester.pumpAndSettle();
    expect(find.byType(BookmarksScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('bookmarksEmptyState')), findsOneWidget);
  });

  testWidgets('bottom settings keeps existing actions accessible', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('homeSettingsDestination')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('homeMenu-reminders')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('homeMenu-restoreBackup')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('homeMenu-language')), findsOneWidget);
  });

  testWidgets('resume opens the exact saved verse and displays its page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        position: ReadingPosition(verseId: '1:3', lastReadAt: DateTime(2026)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verse 3 · Page 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('continueReadingButton')));
    await tester.pumpAndSettle();
    final reader = tester.widget<ReadingScreen>(find.byType(ReadingScreen));
    expect(reader.surah, _surah);
    expect(reader.initialVerseId, '1:3');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final arabic in [false, true]) {
    testWidgets(
      'resume and index scroll together at large text (${arabic ? 'RTL' : 'LTR'})',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            position: ReadingPosition(
              verseId: '1:3',
              lastReadAt: DateTime(2026),
            ),
            dark: arabic,
            arabic: arabic,
            textScale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('continueReadingCard')),
          findsOneWidget,
        );
        await tester.drag(
          find.byKey(const ValueKey('homeQuranScroll')),
          const Offset(0, -700),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('surahCard-1')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
