import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/juz.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';
import 'package:holy_quran_app/presentation/widgets/juz_tile.dart';

const _alFatihah = Surah(
  surahNumber: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'Al-Fatihah',
  numberOfVerses: 7,
);

const _alBaqarah = Surah(
  surahNumber: 2,
  nameArabic: 'البقرة',
  nameEnglish: 'Al-Baqarah',
  numberOfVerses: 286,
);

const _atTawbah = Surah(
  surahNumber: 9,
  nameArabic: 'التوبة',
  nameEnglish: 'At-Tawbah',
  numberOfVerses: 129,
);

const _juz2Start = Verse(
  verseId: '2:142',
  surahNumber: 2,
  verseNumber: 142,
  arabicText: 'سَيَقُولُ ٱلسُّفَهَآءُ',
  translation: 'The foolish among the people will ask',
  page: 22,
);

const _juz11Start = Verse(
  verseId: '9:93',
  surahNumber: 9,
  verseNumber: 93,
  arabicText: 'إِنَّمَا ٱلسَّبِيلُ',
  translation: 'Blame is only on those who seek exemption',
  page: 201,
);

void main() {
  testWidgets('switches from Surahs to Juz and shows its local start page', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Surahs'), findsOneWidget);
    expect(find.text('Juz'), findsOneWidget);
    expect(find.byType(JuzTile), findsNothing);

    await tester.tap(find.text('Juz'));
    await tester.pumpAndSettle();

    expect(find.byType(JuzTile), findsNWidgets(2));
    expect(find.text('Juz 2'), findsOneWidget);
    expect(find.text('Starts at Al-Baqarah 2:142 · Page 22'), findsOneWidget);
    expect(find.text('الجزء ٢'), findsOneWidget);
  });

  testWidgets('opens a selected Juz at its exact first verse', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Juz'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Juz 2'));
    await tester.pumpAndSettle();

    final readingScreen = tester.widget<ReadingScreen>(
      find.byType(ReadingScreen),
    );
    expect(readingScreen.surah, _alBaqarah);
    expect(readingScreen.initialVerseId, '2:142');
  });

  testWidgets('keeps the Juz 11 navigation boundary at 9:93', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Juz'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Juz 11'));
    await tester.pumpAndSettle();

    final readingScreen = tester.widget<ReadingScreen>(
      find.byType(ReadingScreen),
    );
    expect(readingScreen.surah, _atTawbah);
    expect(readingScreen.initialVerseId, '9:93');
  });
}

Widget _buildTestApp() {
  return ProviderScope(
    overrides: [
      surahListProvider.overrideWith(
        (ref) async => const [_alFatihah, _alBaqarah, _atTawbah],
      ),
      juzListProvider.overrideWith(
        (ref) async => [
          (juz: canonicalJuzs[1], page: 22),
          (juz: canonicalJuzs[10], page: 201),
        ],
      ),
      lastReadPositionProvider.overrideWith((ref) async => null),
      recentBookmarksProvider.overrideWith((ref) async => const []),
      feedbackPromptShouldShowProvider.overrideWith((ref) async => false),
      pageForVerseProvider(
        '2:142',
      ).overrideWith((ref) async => _juz2Start.page),
      classicVersesProvider(2).overrideWith((ref) async => const [_juz2Start]),
      versesByPageProvider(22).overrideWith((ref) async => const [_juz2Start]),
      bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
      pageForVerseProvider(
        '9:93',
      ).overrideWith((ref) async => _juz11Start.page),
      classicVersesProvider(9).overrideWith((ref) async => const [_juz11Start]),
      versesByPageProvider(
        201,
      ).overrideWith((ref) async => const [_juz11Start]),
      bookmarksBySurahProvider(9).overrideWith((ref) async => {}),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeScreen(),
    ),
  );
}
