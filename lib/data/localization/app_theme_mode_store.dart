import 'package:shared_preferences/shared_preferences.dart';

abstract class AppThemeModeStore {
  Future<String?> readThemeMode();
  Future<void> writeThemeMode(String themeMode);
}

class SharedPreferencesAppThemeModeStore implements AppThemeModeStore {
  static const _themeModeKey = 'app_theme_mode';

  @override
  Future<String?> readThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_themeModeKey);
  }

  @override
  Future<void> writeThemeMode(String themeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, themeMode);
  }
}
