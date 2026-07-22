import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/localization/app_locale_store.dart';
import 'package:holy_quran_app/data/tafsir/tafsir_repository.dart';
import 'package:holy_quran_app/data/tafsir/tafsir_transport.dart';
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
    expect(find.text('English explanation'), findsOneWidget);
    expect(
      find.text('Source: Tafsir Ibn Kathir — Hafiz Ibn Kathir'),
      findsOneWidget,
    );

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tafsir Muyassar · Arabic').last);
    await tester.pumpAndSettle();

    expect(find.text('شرح عربي'), findsOneWidget);
    expect(find.text('Source: Tafsir Muyassar — الميسر'), findsOneWidget);
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

    expect(find.text('شرح عربي'), findsOneWidget);
    expect(find.text('Tafsir Muyassar · العربية'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VerseDetailScreen)),
    );
    await container
        .read(appLocaleProvider.notifier)
        .setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('English explanation'), findsOneWidget);
    expect(find.text('Tafsir Ibn Kathir · English'), findsOneWidget);
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

    expect(find.text(_verse.arabicText), findsOneWidget);
    expect(find.text(_verse.translation!), findsOneWidget);
    expect(find.text('Tafsir is unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _LocalizedVerseDetailTestApp extends ConsumerWidget {
  const _LocalizedVerseDetailTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const VerseDetailScreen(verse: _verse),
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
  Future<List<TafsirSource>> getSources() async => [_arabic, _english];

  @override
  Future<TafsirPassage> getTafsir({
    required String verseKey,
    required TafsirSource source,
  }) async {
    return TafsirPassage(
      source: source,
      text: source.isArabic ? 'شرح عربي' : 'English explanation',
    );
  }
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
