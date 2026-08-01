import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/localization/app_locale_store.dart';
import 'package:holy_quran_app/data/repositories/quran_repository.dart';
import 'package:holy_quran_app/data/tafsir/tafsir_repository.dart';
import 'package:holy_quran_app/data/tafsir/tafsir_transport.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/tafsir.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/locale_provider.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/providers/tafsir_providers.dart';
import 'package:holy_quran_app/presentation/screens/verse_detail_screen.dart';

const _verse = Verse(
  verseId: '1:1',
  surahNumber: 1,
  verseNumber: 1,
  arabicText: 'بِسْمِ اللَّهِ',
  translation: 'In the name of Allah',
  page: 1,
);

const _nextVerse = Verse(
  verseId: '1:2',
  surahNumber: 1,
  verseNumber: 2,
  arabicText: 'الْحَمْدُ لِلَّهِ',
  translation: 'Praise be to Allah',
  page: 1,
);

const _lastVerseInFirstSurah = Verse(
  verseId: '1:7',
  surahNumber: 1,
  verseNumber: 7,
  arabicText: 'صِرَاطَ الَّذِينَ',
  translation: 'The path of those',
  page: 1,
);

const _firstVerseInSecondSurah = Verse(
  verseId: '2:1',
  surahNumber: 2,
  verseNumber: 1,
  arabicText: 'الم',
  translation: 'Alif, Lam, Meem',
  page: 2,
);

const _english = TafsirSource(
  id: 169,
  name: 'Tafsir Ibn Kathir',
  authorName: 'Hafiz Ibn Kathir',
  languageName: 'english',
  slug: 'en-tafsir-ibn-kathir',
);

const _arabic = TafsirSource(
  id: 16,
  name: 'Tafsir Muyassar',
  authorName: 'الميسر',
  languageName: 'arabic',
  slug: 'ar-tafsir-muyassar',
);

const _arabicTabari = TafsirSource(
  id: 15,
  name: 'Tafsir al-Tabari',
  authorName: 'Imam at-Tabari',
  languageName: 'arabic',
  slug: 'ar-tafsir-al-tabari',
);

const _englishAlternative = TafsirSource(
  id: 168,
  name: "Ma'arif al-Qur'an",
  authorName: 'Mufti Muhammad Shafi',
  languageName: 'english',
  slug: 'en-tafsir-maarif-ul-quran',
);

void main() {
  testWidgets('shows attributed tafsir and switches source', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          tafsirRepositoryProvider.overrideWithValue(_FakeTafsirRepository()),
        ],
        child: const MaterialApp(home: VerseDetailScreen(verse: _verse)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ayah Study'), findsOneWidget);
    expect(find.text('Tafsir'), findsOneWidget);
    expect(find.text(_verse.arabicText), findsNothing);
    expect(find.text(_verse.translation!), findsOneWidget);
    expect(find.text('English explanation'), findsOneWidget);
    final ayahText = tester.widget<Text>(find.text(_verse.translation!));
    final tafsirText = tester.widget<Text>(find.text('English explanation'));
    expect(ayahText.style?.fontSize, lessThanOrEqualTo(30));
    expect(tafsirText.style?.fontSize, greaterThanOrEqualTo(18));
    expect(
      find.text('Source: Tafsir Ibn Kathir — Hafiz Ibn Kathir'),
      findsOneWidget,
    );

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tafsir Muyassar'), findsNothing);
    await tester.tap(find.text("Ma'arif al-Qur'an").last);
    await tester.pumpAndSettle();

    expect(find.text('Alternative English explanation'), findsOneWidget);
    expect(
      find.text("Source: Ma'arif al-Qur'an — Mufti Muhammad Shafi"),
      findsOneWidget,
    );
  });

  testWidgets('uses structured surfaces and direction-aware alignment', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          tafsirRepositoryProvider.overrideWithValue(_FakeTafsirRepository()),
        ],
        child: const MaterialApp(home: VerseDetailScreen(verse: _verse)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('verseDetailAyahCard')), findsOneWidget);
    expect(find.byKey(const ValueKey('tafsirCard')), findsOneWidget);

    final sourcePicker = tester.widget<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    );
    expect(sourcePicker.decoration.filled, isTrue);
    expect(sourcePicker.decoration.labelText, isNull);
    final dropdownButton = tester.widget<DropdownButton<int>>(
      find.descendant(
        of: find.byType(DropdownButtonFormField<int>),
        matching: find.byType(DropdownButton<int>),
      ),
    );
    expect(dropdownButton.borderRadius, BorderRadius.circular(16));
    expect(dropdownButton.menuMaxHeight, 320);
    expect(
      dropdownButton.dropdownColor,
      Theme.of(
        tester.element(find.byType(DropdownButtonFormField<int>)),
      ).colorScheme.surfaceContainer,
    );
    expect(
      (dropdownButton.icon! as Icon).icon,
      Icons.keyboard_arrow_down_rounded,
    );

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tafsirSourceOption-169')),
      findsOneWidget,
    );
    await tester.tap(find.text('Tafsir Ibn Kathir').last);
    await tester.pumpAndSettle();

    final passage = tester.widget<Text>(
      find.byKey(const ValueKey('tafsirPassageText')),
    );
    expect(passage.textAlign, TextAlign.start);
    expect(passage.textDirection, TextDirection.ltr);

    final attribution = tester.widget<Text>(
      find.byKey(const ValueKey('tafsirAttributionText')),
    );
    expect(attribution.textAlign, TextAlign.start);
    expect(attribution.textDirection, TextDirection.ltr);
  });

  testWidgets('uses the app language for the default tafsir source', (
    tester,
  ) async {
    final localeStore = _MemoryAppLocaleStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleStoreProvider.overrideWithValue(localeStore),
          initialAppLocaleProvider.overrideWithValue(const Locale('ar')),
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          tafsirRepositoryProvider.overrideWithValue(_FakeTafsirRepository()),
        ],
        child: const _LocalizedVerseDetailTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_verse.arabicText), findsOneWidget);
    expect(find.text(_verse.translation!), findsNothing);
    expect(find.text('شرح عربي'), findsOneWidget);
    expect(find.text('التفسير الميسر'), findsOneWidget);
    expect(find.textContaining('Tafsir al-Tabari'), findsNothing);
    final arabicPassage = tester.widget<Text>(
      find.byKey(const ValueKey('tafsirPassageText')),
    );
    final arabicAttribution = tester.widget<Text>(
      find.byKey(const ValueKey('tafsirAttributionText')),
    );
    expect(arabicPassage.textAlign, TextAlign.start);
    expect(arabicPassage.textDirection, TextDirection.rtl);
    expect(arabicAttribution.textAlign, TextAlign.start);
    expect(arabicAttribution.textDirection, TextDirection.rtl);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tafsir Ibn Kathir'), findsNothing);
    await tester.tap(find.text('تفسير الطبري').last);
    await tester.pumpAndSettle();

    expect(find.text('شرح الطبري'), findsOneWidget);
    expect(find.text('المصدر: تفسير الطبري — الإمام الطبري'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VerseDetailScreen)),
    );
    await container
        .read(appLocaleProvider.notifier)
        .setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text(_verse.arabicText), findsNothing);
    expect(find.text(_verse.translation!), findsOneWidget);
    expect(find.text('English explanation'), findsOneWidget);
    expect(find.text('Tafsir Ibn Kathir'), findsOneWidget);
  });

  testWidgets('keeps local ayah content visible when tafsir fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          tafsirRepositoryProvider.overrideWithValue(
            const _FailingTafsirRepository(),
          ),
        ],
        child: const MaterialApp(home: VerseDetailScreen(verse: _verse)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_verse.arabicText), findsNothing);
    expect(find.text(_verse.translation!), findsOneWidget);
    expect(find.text('Tafsir is unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('handles a narrow Arabic layout with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleStoreProvider.overrideWithValue(_MemoryAppLocaleStore()),
          initialAppLocaleProvider.overrideWithValue(const Locale('ar')),
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          tafsirRepositoryProvider.overrideWithValue(_FakeTafsirRepository()),
        ],
        child: const _LocalizedVerseDetailTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('verseDetailAyahCard')), findsOneWidget);
    expect(find.byKey(const ValueKey('tafsirCard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a numbered marker and removes embedded marker glyphs', (
    tester,
  ) async {
    const verseWithMarker = Verse(
      verseId: '1:3',
      surahNumber: 1,
      verseNumber: 3,
      arabicText: 'نَصُّ الآية ۝٣',
      translation: 'The verse text',
      page: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleStoreProvider.overrideWithValue(_MemoryAppLocaleStore()),
          initialAppLocaleProvider.overrideWithValue(const Locale('ar')),
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          tafsirRepositoryProvider.overrideWithValue(_FakeTafsirRepository()),
        ],
        child: const _LocalizedVerseDetailTestApp(verse: verseWithMarker),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(verseWithMarker.arabicText), findsNothing);
    expect(find.text('نَصُّ الآية'), findsOneWidget);
    final marker = tester.widget<Text>(
      find.byKey(const ValueKey('ayahNumberMarker')),
    );
    expect(marker.data, contains('3'));
  });

  testWidgets('moves to the next and previous ayah without leaving study', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          quranRepositoryProvider.overrideWithValue(
            const _FakeQuranRepository([_verse, _nextVerse]),
          ),
          tafsirRepositoryProvider.overrideWithValue(_FakeTafsirRepository()),
        ],
        child: const MaterialApp(home: VerseDetailScreen(verse: _verse)),
      ),
    );
    await tester.pumpAndSettle();

    final previousButton = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('previousAyahButton')),
    );
    final nextButton = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('nextAyahButton')),
    );
    expect(previousButton.onPressed, isNull);
    expect(nextButton.onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const ValueKey('nextAyahButton')));
    await tester.tap(find.byKey(const ValueKey('nextAyahButton')));
    await tester.pumpAndSettle();

    expect(find.text('1:2'), findsOneWidget);
    expect(find.text(_nextVerse.translation!), findsOneWidget);
    expect(find.text('Next ayah explanation'), findsOneWidget);
    expect(find.byType(VerseDetailScreen), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('previousAyahButton')),
    );
    await tester.tap(find.byKey(const ValueKey('previousAyahButton')));
    await tester.pumpAndSettle();

    expect(find.text('1:1'), findsOneWidget);
    expect(find.text(_verse.translation!), findsOneWidget);
    expect(find.text('English explanation'), findsOneWidget);
  });

  testWidgets('moves between adjacent surahs without leaving study', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
          quranRepositoryProvider.overrideWithValue(
            const _FakeQuranRepository([
              _lastVerseInFirstSurah,
              _firstVerseInSecondSurah,
            ]),
          ),
          tafsirRepositoryProvider.overrideWithValue(_FakeTafsirRepository()),
        ],
        child: const MaterialApp(
          home: VerseDetailScreen(verse: _lastVerseInFirstSurah),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('nextAyahButton')));
    await tester.tap(find.byKey(const ValueKey('nextAyahButton')));
    await tester.pumpAndSettle();

    expect(find.text('2:1'), findsOneWidget);
    expect(find.text(_firstVerseInSecondSurah.translation!), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('previousAyahButton')),
    );
    await tester.tap(find.byKey(const ValueKey('previousAyahButton')));
    await tester.pumpAndSettle();

    expect(find.text('1:7'), findsOneWidget);
    expect(find.text(_lastVerseInFirstSurah.translation!), findsOneWidget);
  });
}

class _LocalizedVerseDetailTestApp extends ConsumerWidget {
  final Verse verse;

  const _LocalizedVerseDetailTestApp({this.verse = _verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VerseDetailScreen(verse: verse),
    );
  }
}

class _MemoryAppLocaleStore implements AppLocaleStore {
  @override
  Future<String?> readLanguageCode() async => null;

  @override
  Future<void> writeLanguageCode(String languageCode) async {}
}

class _FakeTafsirRepository implements TafsirRepository {
  @override
  Future<List<TafsirSource>> getSources() async => [
    _arabic,
    _english,
    _arabicTabari,
    _englishAlternative,
  ];

  @override
  Future<TafsirPassage> getTafsir({
    required String verseKey,
    required TafsirSource source,
  }) async {
    final text = switch (source.id) {
      15 => 'شرح الطبري',
      16 => 'شرح عربي',
      168 => 'Alternative English explanation',
      _ when verseKey == _nextVerse.verseId => 'Next ayah explanation',
      _ => 'English explanation',
    };
    return TafsirPassage(source: source, text: text);
  }
}

class _FakeQuranRepository implements QuranRepository {
  final List<Verse> verses;

  const _FakeQuranRepository(this.verses);

  @override
  Future<List<Surah>> getAllSurahs() async => const [];

  @override
  Future<int> getPageForVerse(String verseId) async => 1;

  @override
  Future<int> getStartPageForSurah(int surahNumber) async => 1;

  @override
  Future<Surah?> getSurahByNumber(int surahNumber) async => null;

  @override
  Future<Verse?> getVerseById(String verseId) async {
    for (final verse in verses) {
      if (verse.verseId == verseId) return verse;
    }
    return null;
  }

  @override
  Future<List<Verse>> getVersesByPage(int page) async =>
      verses.where((verse) => verse.page == page).toList();

  @override
  Future<List<Verse>> getVersesBySurah(int surahNumber) async =>
      verses.where((verse) => verse.surahNumber == surahNumber).toList();

  @override
  Future<bool> isDataLoaded() async => true;

  @override
  Future<void> loadQuranData() async {}
}

class _FailingTafsirRepository implements TafsirRepository {
  const _FailingTafsirRepository();

  @override
  Future<List<TafsirSource>> getSources() {
    throw const TafsirException('Offline');
  }

  @override
  Future<TafsirPassage> getTafsir({
    required String verseKey,
    required TafsirSource source,
  }) {
    throw const TafsirException('Offline');
  }
}
