import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/localization/app_locale_store.dart';
import 'package:holy_quran_app/presentation/providers/locale_provider.dart';

void main() {
  test('Arabic is used when no supported preference exists', () async {
    final emptyStore = _MemoryAppLocaleStore();
    final unsupportedStore = _MemoryAppLocaleStore('fr');

    expect(await loadPreferredAppLocale(emptyStore), defaultAppLocale);
    expect(await loadPreferredAppLocale(unsupportedStore), defaultAppLocale);
  });

  test('English preference is restored', () async {
    final store = _MemoryAppLocaleStore('en');

    expect(await loadPreferredAppLocale(store), const Locale('en'));
  });

  test(
    'locale controller updates and persists the selected language',
    () async {
      final store = _MemoryAppLocaleStore();
      final controller = AppLocaleController(
        store: store,
        initialLocale: defaultAppLocale,
      );

      await controller.setLocale(const Locale('en'));

      expect(controller.state, const Locale('en'));
      expect(store.languageCode, 'en');
    },
  );
}

class _MemoryAppLocaleStore implements AppLocaleStore {
  String? languageCode;

  _MemoryAppLocaleStore([this.languageCode]);

  @override
  Future<String?> readLanguageCode() async => languageCode;

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
  }
}
