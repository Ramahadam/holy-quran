import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/juz.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';
import 'package:holy_quran_app/presentation/widgets/juz_tile.dart';
import 'package:holy_quran_app/presentation/widgets/quran_index.dart';
import 'package:holy_quran_app/presentation/widgets/surah_tile.dart';

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

void main() {
  testWidgets('owns Surah and Juz selection and opens the selected entry', (
    tester,
  ) async {
    Surah? openedSurah;
    String? openedVerseId;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          juzListProvider.overrideWith(
            (ref) async => [(juz: canonicalJuzs[1], page: 22)],
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: Scaffold(
            body: QuranIndex(
              surahs: const [_alFatihah, _alBaqarah],
              onOpenReading: (surah, {initialVerseId}) async {
                openedSurah = surah;
                openedVerseId = initialVerseId;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SurahTile), findsNWidgets(2));
    expect(find.byType(JuzTile), findsNothing);

    await tester.tap(find.text('Juz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Juz 2'));

    expect(openedSurah, _alBaqarah);
    expect(openedVerseId, '2:142');
  });
}
