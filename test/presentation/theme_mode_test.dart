import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/localization/app_theme_mode_store.dart';
import 'package:holy_quran_app/presentation/providers/theme_mode_provider.dart';

void main() {
  test('light mode is used when no supported preference exists', () async {
    final emptyStore = _MemoryThemeModeStore();
    final unsupportedStore = _MemoryThemeModeStore('system');

    expect(await loadPreferredThemeMode(emptyStore), defaultThemeMode);
    expect(await loadPreferredThemeMode(unsupportedStore), defaultThemeMode);
  });

  test('dark mode persists across an app restart', () async {
    final store = _MemoryThemeModeStore();
    final controller = ThemeModeController(
      store: store,
      initialThemeMode: defaultThemeMode,
    );

    await controller.setThemeMode(ThemeMode.dark);
    final restoredThemeMode = await loadPreferredThemeMode(store);

    expect(controller.state, ThemeMode.dark);
    expect(restoredThemeMode, ThemeMode.dark);
  });
}

class _MemoryThemeModeStore implements AppThemeModeStore {
  String? themeMode;

  _MemoryThemeModeStore([this.themeMode]);

  @override
  Future<String?> readThemeMode() async => themeMode;

  @override
  Future<void> writeThemeMode(String themeMode) async {
    this.themeMode = themeMode;
  }
}
