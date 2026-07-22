import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/localization/app_locale_store.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/locale_provider.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';

void main() {
  testWidgets('Arabic is default and English selection persists', (
    tester,
  ) async {
    final localeStore = _MemoryAppLocaleStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleStoreProvider.overrideWithValue(localeStore),
          initialAppLocaleProvider.overrideWithValue(defaultAppLocale),
          surahListProvider.overrideWith((ref) async => const [_surah]),
          lastReadPositionProvider.overrideWith((ref) async => null),
          recentBookmarksProvider.overrideWith((ref) async => const []),
          feedbackPromptShouldShowProvider.overrideWith((ref) async => false),
        ],
        child: const _LocalizedHomeTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('السور'), findsOneWidget);
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.rtl,
    );

    await tester.tap(find.byKey(const ValueKey('homeMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Surahs'), findsOneWidget);
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.ltr,
    );
    expect(localeStore.languageCode, 'en');
  });
}

class _LocalizedHomeTestApp extends ConsumerWidget {
  const _LocalizedHomeTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}

class _MemoryAppLocaleStore implements AppLocaleStore {
  String? languageCode;

  @override
  Future<String?> readLanguageCode() async => languageCode;

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
  }
}

const _surah = Surah(
  surahNumber: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'The Opening',
  numberOfVerses: 7,
);
