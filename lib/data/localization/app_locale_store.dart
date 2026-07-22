import 'package:shared_preferences/shared_preferences.dart';

abstract class AppLocaleStore {
  Future<String?> readLanguageCode();
  Future<void> writeLanguageCode(String languageCode);
}

class SharedPreferencesAppLocaleStore implements AppLocaleStore {
  static const _languageCodeKey = 'app_language_code';

  @override
  Future<String?> readLanguageCode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_languageCodeKey);
  }

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageCodeKey, languageCode);
  }
}
