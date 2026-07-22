// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Holy Quran';

  @override
  String get databaseError =>
      'Could not open the database.\nPlease restart the app.';

  @override
  String get dataLoadError => 'Failed to load data.\nPlease restart the app.';

  @override
  String get preparingApp => 'Preparing your Digital Sanctuary...';

  @override
  String get menu => 'Menu';

  @override
  String get switchLanguage => 'العربية';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get readingReminders => 'Reading reminders';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get importBackup => 'Import backup';

  @override
  String get surahs => 'Surahs';

  @override
  String get juz => 'Juz';

  @override
  String get surahLoadError =>
      'Failed to load surahs.\nPlease restart the app.';

  @override
  String get noSurahs => 'No surahs found.';

  @override
  String get juzLoadError => 'Failed to load Juz.\nPlease restart the app.';

  @override
  String get backupExported => 'Backup exported';

  @override
  String get exportCanceled => 'Export canceled';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get backupImported => 'Backup imported';

  @override
  String get importCanceled => 'Import canceled';

  @override
  String get importFailed => 'Import failed. Check the file and passphrase.';

  @override
  String get feedbackPromptTitle => 'How is your Quran reading experience?';

  @override
  String get feedbackPromptSubtitle =>
      'A quick anonymous note can help shape what comes next.';

  @override
  String get feedbackPromptBody =>
      'If you have a moment, share what would make the app better. Your note is anonymous.';

  @override
  String get notNow => 'Not now';

  @override
  String get giveFeedback => 'Give feedback';

  @override
  String get exportBackupSubtitle =>
      'Create an encrypted copy of your reading progress.';

  @override
  String get importBackupSubtitle =>
      'Restore your bookmarks and last reading position.';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get confirmPassphrase => 'Confirm passphrase';

  @override
  String get backupProtectionExport =>
      'This passphrase encrypts your bookmarks and last reading position. It cannot be recovered, so keep it safe.';

  @override
  String get backupProtectionImport =>
      'Importing replaces your current bookmarks and last reading position. Use the original passphrase.';

  @override
  String get cancel => 'Cancel';

  @override
  String get export => 'Export';

  @override
  String get replaceAndImport => 'Replace & import';

  @override
  String get passphraseRequired => 'Passphrase is required';

  @override
  String get passphrasesMismatch => 'Passphrases do not match';

  @override
  String get loadingReminderSettings => 'Loading your reminder settings.';

  @override
  String get loadingReminderSettingsLabel => 'Loading reminder settings';

  @override
  String get reminderSettingsUnavailable =>
      'Your settings are unavailable right now.';

  @override
  String get reminderSettingsLoadFailed =>
      'Reminder settings could not be loaded.';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get reminderSubtitle =>
      'Build a gentle reading habit around a prayer time.';

  @override
  String get enableReminder => 'Enable reminder';

  @override
  String get reminderEnabledBody => 'A daily reading reminder is on.';

  @override
  String get reminderDisabledBody => 'Turn this on when you are ready.';

  @override
  String get prayer => 'Prayer';

  @override
  String get prayerTime => 'Prayer time';

  @override
  String get reminderAfter => 'Reminder after';

  @override
  String get atPrayerTime => 'At prayer time';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get snooze => 'Snooze';

  @override
  String get saving => 'Saving';

  @override
  String get save => 'Save';

  @override
  String get reminderScheduleFailed =>
      'Reminder could not be scheduled. Please try again.';

  @override
  String get reminderScheduled => 'Reading reminder scheduled';

  @override
  String get reminderDisabled => 'Reading reminder disabled';

  @override
  String get reminderPermissionDenied => 'Reminder permission was not granted';

  @override
  String get feedbackSubtitle =>
      'Help us improve the Quran reading experience.';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackHint => 'Share what would make the app better.';

  @override
  String get feedbackPrivacy =>
      'Sent anonymously. Do not include private information.';

  @override
  String get sending => 'Sending';

  @override
  String get send => 'Send';

  @override
  String get feedbackSent => 'Feedback sent';

  @override
  String get feedbackSendFailed =>
      'Feedback could not be sent. Please try again later.';

  @override
  String get feedbackRequired => 'Feedback cannot be empty.';

  @override
  String get feedbackTooLong => 'Feedback is too long.';

  @override
  String verseNumber(String number) {
    return 'Verse $number';
  }

  @override
  String get continueReading => 'Continue Reading';

  @override
  String continueReadingSemantics(String readingLabel) {
    return 'Continue reading, $readingLabel';
  }

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String surahNumber(String number) {
    return 'Surah $number';
  }

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get bookmarked => 'Bookmarked';

  @override
  String verseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verses',
      one: '1 verse',
    );
    return '$_temp0';
  }

  @override
  String surahSemantics(int number, String arabicName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verses',
      one: '1 verse',
    );
    return 'Surah $number, $arabicName, $_temp0';
  }

  @override
  String juzNumber(int number) {
    return 'Juz $number';
  }

  @override
  String juzStartsAt(String startLabel, int page) {
    return 'Starts at $startLabel · Page $page';
  }

  @override
  String juzSemantics(
    int number,
    String arabicTitle,
    String startLabel,
    int page,
  ) {
    return 'Juz $number, $arabicTitle, starts at $startLabel, page $page';
  }

  @override
  String pageNumber(int page) {
    return 'Page $page';
  }

  @override
  String get mushaf => 'Mushaf';

  @override
  String get classic => 'Classic';

  @override
  String get noVersesInSurah => 'No verses in this surah.';

  @override
  String get noVersesOnPage => 'No verses on this page.';

  @override
  String get verseLoadError =>
      'Failed to load verses.\nPlease restart the app.';

  @override
  String invalidMushafPage(int page) {
    return 'Mushaf page must be between 1 and 604.\nCurrent page: $page';
  }

  @override
  String get ayahStudy => 'Ayah Study';

  @override
  String get bookmarkVerse => 'Bookmark verse';

  @override
  String get tafsir => 'Tafsir';

  @override
  String get tafsirProvider => 'Commentary from Quran Foundation';

  @override
  String get noTafsirSources => 'No tafsir sources are available.';

  @override
  String get tafsirSource => 'Tafsir source';

  @override
  String get tafsirUnavailable => 'Tafsir is unavailable';

  @override
  String sourceName(String name) {
    return 'Source: $name';
  }

  @override
  String sourceNameAuthor(String name, String author) {
    return 'Source: $name — $author';
  }

  @override
  String get fajr => 'Fajr';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';
}
