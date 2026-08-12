import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/localization/app_theme_mode_store.dart';

const defaultThemeMode = ThemeMode.light;
const supportedThemeModes = [ThemeMode.light, ThemeMode.dark];

final appThemeModeStoreProvider = Provider<AppThemeModeStore>((ref) {
  return SharedPreferencesAppThemeModeStore();
});

final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  return defaultThemeMode;
});

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    return ThemeModeController(
      store: ref.watch(appThemeModeStoreProvider),
      initialThemeMode: ref.watch(initialThemeModeProvider),
    );
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  final AppThemeModeStore _store;

  ThemeModeController({
    required AppThemeModeStore store,
    required ThemeMode initialThemeMode,
  }) : _store = store,
       super(_supportedThemeModeOrDefault(initialThemeMode.name));

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final supportedThemeMode = _supportedThemeModeOrDefault(themeMode.name);
    state = supportedThemeMode;
    await _store.writeThemeMode(supportedThemeMode.name);
  }
}

Future<ThemeMode> loadPreferredThemeMode(AppThemeModeStore store) async {
  try {
    return _supportedThemeModeOrDefault(await store.readThemeMode());
  } catch (_) {
    return defaultThemeMode;
  }
}

ThemeMode _supportedThemeModeOrDefault(String? themeModeName) {
  for (final themeMode in supportedThemeModes) {
    if (themeMode.name == themeModeName) return themeMode;
  }
  return defaultThemeMode;
}
