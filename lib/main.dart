import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/isar_service.dart';
import 'data/localization/app_locale_store.dart';
import 'data/localization/app_theme_mode_store.dart';
import 'presentation/app.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/theme_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localeStore = SharedPreferencesAppLocaleStore();
  final initialLocale = await loadPreferredAppLocale(localeStore);
  final themeModeStore = SharedPreferencesAppThemeModeStore();
  final initialThemeMode = await loadPreferredThemeMode(themeModeStore);

  bool dbFailed = false;
  try {
    await IsarService.getInstance();
  } catch (e, stackTrace) {
    debugPrint('Database initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    dbFailed = true;
  }

  runApp(
    ProviderScope(
      overrides: [
        appLocaleStoreProvider.overrideWithValue(localeStore),
        initialAppLocaleProvider.overrideWithValue(initialLocale),
        appThemeModeStoreProvider.overrideWithValue(themeModeStore),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
      ],
      child: dbFailed ? const DatabaseErrorApp() : const HolyQuranApp(),
    ),
  );
}
