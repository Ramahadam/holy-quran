import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/localization/app_locale_store.dart';

const defaultAppLocale = Locale('ar');
const supportedAppLocales = [defaultAppLocale, Locale('en')];

final appLocaleStoreProvider = Provider<AppLocaleStore>((ref) {
  return SharedPreferencesAppLocaleStore();
});

final initialAppLocaleProvider = Provider<Locale>((ref) => defaultAppLocale);

final appLocaleProvider = StateNotifierProvider<AppLocaleController, Locale>((
  ref,
) {
  return AppLocaleController(
    store: ref.watch(appLocaleStoreProvider),
    initialLocale: ref.watch(initialAppLocaleProvider),
  );
});

class AppLocaleController extends StateNotifier<Locale> {
  final AppLocaleStore _store;

  AppLocaleController({
    required AppLocaleStore store,
    required Locale initialLocale,
  }) : _store = store,
       super(_supportedLocaleOrDefault(initialLocale.languageCode));

  Future<void> setLocale(Locale locale) async {
    final supportedLocale = _supportedLocaleOrDefault(locale.languageCode);
    state = supportedLocale;
    await _store.writeLanguageCode(supportedLocale.languageCode);
  }
}

Future<Locale> loadPreferredAppLocale(AppLocaleStore store) async {
  try {
    return _supportedLocaleOrDefault(await store.readLanguageCode());
  } catch (_) {
    return defaultAppLocale;
  }
}

Locale _supportedLocaleOrDefault(String? languageCode) {
  for (final locale in supportedAppLocales) {
    if (locale.languageCode == languageCode) return locale;
  }
  return defaultAppLocale;
}
