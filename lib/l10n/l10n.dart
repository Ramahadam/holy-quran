import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations != null) return localizations;

    final locale = Localizations.maybeLocaleOf(this) ?? const Locale('en');
    return lookupAppLocalizations(
      AppLocalizations.supportedLocales.any(
            (supported) => supported.languageCode == locale.languageCode,
          )
          ? locale
          : const Locale('en'),
    );
  }
}
