import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Holy Quran'**
  String get appTitle;

  /// No description provided for @databaseError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the database.\nPlease restart the app.'**
  String get databaseError;

  /// No description provided for @dataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data.\nPlease restart the app.'**
  String get dataLoadError;

  /// No description provided for @preparingApp.
  ///
  /// In en, this message translates to:
  /// **'Preparing your Digital Sanctuary...'**
  String get preparingApp;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get switchLanguage;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @readingReminders.
  ///
  /// In en, this message translates to:
  /// **'Reading reminders'**
  String get readingReminders;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// No description provided for @surahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahs;

  /// No description provided for @juz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get juz;

  /// No description provided for @surahLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load surahs.\nPlease restart the app.'**
  String get surahLoadError;

  /// No description provided for @noSurahs.
  ///
  /// In en, this message translates to:
  /// **'No surahs found.'**
  String get noSurahs;

  /// No description provided for @juzLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Juz.\nPlease restart the app.'**
  String get juzLoadError;

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup exported'**
  String get backupExported;

  /// No description provided for @exportCanceled.
  ///
  /// In en, this message translates to:
  /// **'Export canceled'**
  String get exportCanceled;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @backupImported.
  ///
  /// In en, this message translates to:
  /// **'Backup imported'**
  String get backupImported;

  /// No description provided for @importCanceled.
  ///
  /// In en, this message translates to:
  /// **'Import canceled'**
  String get importCanceled;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Check the file and passphrase.'**
  String get importFailed;

  /// No description provided for @feedbackPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'How is your Quran reading experience?'**
  String get feedbackPromptTitle;

  /// No description provided for @feedbackPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick anonymous note can help shape what comes next.'**
  String get feedbackPromptSubtitle;

  /// No description provided for @feedbackPromptBody.
  ///
  /// In en, this message translates to:
  /// **'If you have a moment, share what would make the app better. Your note is anonymous.'**
  String get feedbackPromptBody;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @giveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Give feedback'**
  String get giveFeedback;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an encrypted copy of your reading progress.'**
  String get exportBackupSubtitle;

  /// No description provided for @importBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore your bookmarks and last reading position.'**
  String get importBackupSubtitle;

  /// No description provided for @passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphrase;

  /// No description provided for @confirmPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Confirm passphrase'**
  String get confirmPassphrase;

  /// No description provided for @backupProtectionExport.
  ///
  /// In en, this message translates to:
  /// **'This passphrase encrypts your bookmarks and last reading position. It cannot be recovered, so keep it safe.'**
  String get backupProtectionExport;

  /// No description provided for @backupProtectionImport.
  ///
  /// In en, this message translates to:
  /// **'Importing replaces your current bookmarks and last reading position. Use the original passphrase.'**
  String get backupProtectionImport;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @replaceAndImport.
  ///
  /// In en, this message translates to:
  /// **'Replace & import'**
  String get replaceAndImport;

  /// No description provided for @passphraseRequired.
  ///
  /// In en, this message translates to:
  /// **'Passphrase is required'**
  String get passphraseRequired;

  /// No description provided for @passphrasesMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passphrases do not match'**
  String get passphrasesMismatch;

  /// No description provided for @loadingReminderSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading your reminder settings.'**
  String get loadingReminderSettings;

  /// No description provided for @loadingReminderSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading reminder settings'**
  String get loadingReminderSettingsLabel;

  /// No description provided for @reminderSettingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your settings are unavailable right now.'**
  String get reminderSettingsUnavailable;

  /// No description provided for @reminderSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Reminder settings could not be loaded.'**
  String get reminderSettingsLoadFailed;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build a gentle reading habit around a prayer time.'**
  String get reminderSubtitle;

  /// No description provided for @enableReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable reminder'**
  String get enableReminder;

  /// No description provided for @reminderEnabledBody.
  ///
  /// In en, this message translates to:
  /// **'A daily reading reminder is on.'**
  String get reminderEnabledBody;

  /// No description provided for @reminderDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Turn this on when you are ready.'**
  String get reminderDisabledBody;

  /// No description provided for @prayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayer;

  /// No description provided for @prayerTime.
  ///
  /// In en, this message translates to:
  /// **'Prayer time'**
  String get prayerTime;

  /// No description provided for @reminderAfter.
  ///
  /// In en, this message translates to:
  /// **'Reminder after'**
  String get reminderAfter;

  /// No description provided for @atPrayerTime.
  ///
  /// In en, this message translates to:
  /// **'At prayer time'**
  String get atPrayerTime;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @reminderScheduleFailed.
  ///
  /// In en, this message translates to:
  /// **'Reminder could not be scheduled. Please try again.'**
  String get reminderScheduleFailed;

  /// No description provided for @reminderScheduled.
  ///
  /// In en, this message translates to:
  /// **'Reading reminder scheduled'**
  String get reminderScheduled;

  /// No description provided for @reminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Reading reminder disabled'**
  String get reminderDisabled;

  /// No description provided for @reminderPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Reminder permission was not granted'**
  String get reminderPermissionDenied;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve the Quran reading experience.'**
  String get feedbackSubtitle;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Share what would make the app better.'**
  String get feedbackHint;

  /// No description provided for @feedbackPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Sent anonymously. Do not include private information.'**
  String get feedbackPrivacy;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sending;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent'**
  String get feedbackSent;

  /// No description provided for @feedbackSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Feedback could not be sent. Please try again later.'**
  String get feedbackSendFailed;

  /// No description provided for @feedbackRequired.
  ///
  /// In en, this message translates to:
  /// **'Feedback cannot be empty.'**
  String get feedbackRequired;

  /// No description provided for @feedbackTooLong.
  ///
  /// In en, this message translates to:
  /// **'Feedback is too long.'**
  String get feedbackTooLong;

  /// No description provided for @verseNumber.
  ///
  /// In en, this message translates to:
  /// **'Verse {number}'**
  String verseNumber(String number);

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @continueReadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Continue reading, {readingLabel}'**
  String continueReadingSemantics(String readingLabel);

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @surahNumber.
  ///
  /// In en, this message translates to:
  /// **'Surah {number}'**
  String surahNumber(String number);

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmark;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get bookmarked;

  /// No description provided for @verseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 verse} other{{count} verses}}'**
  String verseCount(int count);

  /// No description provided for @surahSemantics.
  ///
  /// In en, this message translates to:
  /// **'Surah {number}, {arabicName}, {count, plural, =1{1 verse} other{{count} verses}}'**
  String surahSemantics(int number, String arabicName, int count);

  /// No description provided for @juzNumber.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juzNumber(int number);

  /// No description provided for @juzStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {startLabel} · Page {page}'**
  String juzStartsAt(String startLabel, int page);

  /// No description provided for @juzSemantics.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}, {arabicTitle}, starts at {startLabel}, page {page}'**
  String juzSemantics(
    int number,
    String arabicTitle,
    String startLabel,
    int page,
  );

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageNumber(int page);

  /// No description provided for @mushaf.
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get mushaf;

  /// No description provided for @classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get classic;

  /// No description provided for @noVersesInSurah.
  ///
  /// In en, this message translates to:
  /// **'No verses in this surah.'**
  String get noVersesInSurah;

  /// No description provided for @noVersesOnPage.
  ///
  /// In en, this message translates to:
  /// **'No verses on this page.'**
  String get noVersesOnPage;

  /// No description provided for @verseLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load verses.\nPlease restart the app.'**
  String get verseLoadError;

  /// No description provided for @invalidMushafPage.
  ///
  /// In en, this message translates to:
  /// **'Mushaf page must be between 1 and 604.\nCurrent page: {page}'**
  String invalidMushafPage(int page);

  /// No description provided for @ayahStudy.
  ///
  /// In en, this message translates to:
  /// **'Ayah Study'**
  String get ayahStudy;

  /// No description provided for @bookmarkVerse.
  ///
  /// In en, this message translates to:
  /// **'Bookmark verse'**
  String get bookmarkVerse;

  /// No description provided for @tafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsir;

  /// No description provided for @tafsirProvider.
  ///
  /// In en, this message translates to:
  /// **'Commentary from Quran Foundation'**
  String get tafsirProvider;

  /// No description provided for @noTafsirSources.
  ///
  /// In en, this message translates to:
  /// **'No tafsir sources are available.'**
  String get noTafsirSources;

  /// No description provided for @tafsirSource.
  ///
  /// In en, this message translates to:
  /// **'Tafsir source'**
  String get tafsirSource;

  /// No description provided for @tafsirUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tafsir is unavailable'**
  String get tafsirUnavailable;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get languageBengali;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @languageSwahili.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get languageSwahili;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get languageUrdu;

  /// No description provided for @languageKurdish.
  ///
  /// In en, this message translates to:
  /// **'Kurdish'**
  String get languageKurdish;

  /// No description provided for @sourceName.
  ///
  /// In en, this message translates to:
  /// **'Source: {name}'**
  String sourceName(String name);

  /// No description provided for @sourceNameAuthor.
  ///
  /// In en, this message translates to:
  /// **'Source: {name} — {author}'**
  String sourceNameAuthor(String name, String author);

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
