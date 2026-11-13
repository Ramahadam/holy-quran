import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/localization/app_locale_store.dart';
import 'package:holy_quran_app/data/localization/app_theme_mode_store.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/locale_provider.dart';
import 'package:holy_quran_app/presentation/providers/theme_mode_provider.dart';
import 'package:holy_quran_app/presentation/screens/settings_screen.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';

class _PolicyBundle extends CachingAssetBundle {
  final String policy;
  _PolicyBundle(this.policy);

  @override
  Future<ByteData> load(String key) {
    expect(key, 'assets/privacy/privacy_policy.json');
    return Future.value(
      ByteData.sublistView(Uint8List.fromList(utf8.encode(policy))),
    );
  }
}

class _LocaleStore implements AppLocaleStore {
  String? value;
  @override
  Future<String?> readLanguageCode() async => value;
  @override
  Future<void> writeLanguageCode(String code) async {
    value = code;
  }
}

class _ThemeStore implements AppThemeModeStore {
  String? value;
  @override
  Future<String?> readThemeMode() async => value;
  @override
  Future<void> writeThemeMode(String mode) async {
    value = mode;
  }
}

class _App extends ConsumerWidget {
  final Widget screen;
  final double scale;
  const _App({required this.screen, this.scale = 1});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    locale: ref.watch(appLocaleProvider),
    themeMode: ref.watch(themeModeProvider),
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: screen,
  );
}

Widget _screen(List<String> actions) => SettingsScreen(
  onOpenReminders: () => actions.add('reminders'),
  onSaveBackup: () => actions.add('save'),
  onShareBackup: () => actions.add('share'),
  onRestoreBackup: () => actions.add('restore'),
  onSendFeedback: () => actions.add('feedback'),
);

void main() {
  late String policy;
  setUpAll(() async {
    policy = await rootBundle.loadString('assets/privacy/privacy_policy.json');
  });
  testWidgets('language and theme update repeatedly and persist', (
    tester,
  ) async {
    final localeStore = _LocaleStore();
    final themeStore = _ThemeStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleStoreProvider.overrideWithValue(localeStore),
          appThemeModeStoreProvider.overrideWithValue(themeStore),
          initialAppLocaleProvider.overrideWithValue(const Locale('en')),
          initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        ],
        child: _App(screen: _screen([])),
      ),
    );
    await tester.pumpAndSettle();
    for (final enabled in [true, false, true]) {
      await tester.tap(find.byKey(const ValueKey('settingsDarkMode')));
      await tester.pumpAndSettle();
      expect(
        themeStore.value,
        enabled ? ThemeMode.dark.name : ThemeMode.light.name,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('settingsDarkMode')),
            )
            .value,
        enabled,
      );
    }
    await tester.tap(find.byKey(const ValueKey('settingsLanguage')));
    await tester.pumpAndSettle();
    expect(localeStore.value, 'ar');
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(SettingsScreen))),
      TextDirection.rtl,
    );
    await tester.tap(find.byKey(const ValueKey('settingsLanguage')));
    await tester.pumpAndSettle();
    expect(localeStore.value, 'en');
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('all existing action flows remain reachable', (tester) async {
    final actions = <String>[];
    await tester.pumpWidget(
      ProviderScope(child: _App(screen: _screen(actions))),
    );
    await tester.pumpAndSettle();
    for (final action in [
      'reminders',
      'save',
      'share',
      'restore',
      'feedback',
    ]) {
      final button = find.byKey(ValueKey('settings-$action'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }
    expect(actions, ['reminders', 'save', 'share', 'restore', 'feedback']);
  });

  for (final locale in ['en', 'ar']) {
    testWidgets('privacy policy is reachable offline in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialAppLocaleProvider.overrideWithValue(Locale(locale)),
          ],
          child: DefaultAssetBundle(
            bundle: _PolicyBundle(policy),
            child: _App(screen: _screen([]), scale: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final privacy = find.byKey(const ValueKey('settings-privacy'));
      await tester.scrollUntilVisible(privacy, 250);
      await tester.ensureVisible(privacy);
      await tester.pumpAndSettle();
      await tester.tap(privacy);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('privacyPolicyBody')), findsOneWidget);
      expect(
        find.text(
          locale == 'ar' ? 'الملاحظات الاختيارية' : 'Optional feedback',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('settings scroll at 320px and 2x text in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final actions = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialAppLocaleProvider.overrideWithValue(Locale(locale)),
            initialThemeModeProvider.overrideWithValue(
              locale == 'ar' ? ThemeMode.dark : ThemeMode.light,
            ),
          ],
          child: _App(screen: _screen(actions), scale: 2),
        ),
      );
      await tester.pumpAndSettle();
      final feedback = find.byKey(const ValueKey('settings-feedback'));
      await tester.scrollUntilVisible(feedback, 250);
      await tester.ensureVisible(feedback);
      await tester.pumpAndSettle();
      await tester.tap(feedback);
      await tester.pumpAndSettle();
      expect(actions, ['feedback']);
      expect(tester.takeException(), isNull);
    });
  }
}
