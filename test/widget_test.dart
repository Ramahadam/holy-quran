import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:holy_quran_app/presentation/app.dart';
import 'package:holy_quran_app/presentation/screens/loading_screen.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';
import 'package:holy_quran_app/presentation/screens/verse_detail_screen.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/data/repositories/bookmark_repository.dart';
import 'package:holy_quran_app/data/repositories/reading_position_repository.dart';
import 'package:holy_quran_app/data/feedback/feedback_prompt_service.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';
import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';
import 'package:holy_quran_app/presentation/widgets/surah_tile.dart';
import 'package:holy_quran_app/presentation/widgets/verse_card.dart';
import 'package:holy_quran_app/data/notifications/prayer_reminder_scheduler.dart';
import 'package:holy_quran_app/data/notifications/prayer_reminder_service.dart';
import 'package:holy_quran_app/data/notifications/prayer_reminder_settings.dart';
import 'package:holy_quran_app/data/notifications/prayer_reminder_settings_store.dart';

const _surah1 = Surah(
  surahNumber: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'The Opening',
  numberOfVerses: 7,
);

const _verse1 = Verse(
  verseId: '1:1',
  surahNumber: 1,
  verseNumber: 1,
  arabicText: 'بِسْمِ اللَّهِ',
  translation: 'In the name of Allah',
);

const _verse2 = Verse(
  verseId: '1:2',
  surahNumber: 1,
  verseNumber: 2,
  arabicText: 'ٱلْحَمْدُ لِلَّهِ',
  translation: 'Praise be to Allah',
);

const _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

List<Verse> _surahVerses(int count) => List.generate(
  count,
  (index) => Verse(
    verseId: '1:${index + 1}',
    surahNumber: 1,
    verseNumber: index + 1,
    arabicText: 'آية ${index + 1}',
    translation: 'Verse ${index + 1}',
  ),
);

class _FakeBookmarkRepository implements BookmarkRepository {
  final addedVerseIds = <String>[];
  final removedVerseIds = <String>[];

  @override
  Future<void> addBookmark(String verseId, DateTime timestamp) async {
    addedVerseIds.add(verseId);
  }

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {}

  @override
  Future<void> removeBookmark(String verseId) async {
    removedVerseIds.add(verseId);
  }

  @override
  Future<List<Bookmark>> getAllBookmarks() async => const [];

  @override
  Future<List<Bookmark>> getRecentBookmarks({int limit = 3}) async => const [];

  @override
  Future<Set<String>> getBookmarkedVerseIdsBySurah(int surahNumber) async => {};

  @override
  Future<void> replaceAllBookmarks(List<Bookmark> bookmarks) async {}
}

class _FakeReadingPositionRepository implements ReadingPositionRepository {
  ReadingPosition? savedPosition;

  @override
  Future<void> clearPosition() async {
    savedPosition = null;
  }

  @override
  Future<ReadingPosition?> getLastPosition() async => savedPosition;

  @override
  Future<void> savePosition(ReadingPosition position) async {
    savedPosition = position;
  }
}

class _FakePrayerReminderSettingsStore
    implements PrayerReminderSettingsRepository {
  PrayerReminderSettings settings;

  _FakePrayerReminderSettingsStore(this.settings);

  @override
  Future<PrayerReminderSettings> load() async => settings;

  @override
  Future<void> save(PrayerReminderSettings settings) async {
    this.settings = settings;
  }
}

class _FakePrayerReminderScheduler implements PrayerReminderScheduler {
  PrayerReminderSettings? scheduledSettings;
  PrayerReminderSettings? snoozedSettings;
  Object? requestPermissionError;
  var canceled = false;
  var permissionGranted = true;

  @override
  Future<void> cancel() async {
    canceled = true;
  }

  @override
  Future<bool> requestPermission() async {
    final error = requestPermissionError;
    if (error != null) throw error;
    return permissionGranted;
  }

  @override
  Future<void> schedule(PrayerReminderSettings settings) async {
    scheduledSettings = settings;
  }

  @override
  Future<void> snooze(PrayerReminderSettings settings) async {
    snoozedSettings = settings;
  }
}

class _FakeFeedbackPromptService implements FeedbackPromptController {
  int recordedSessions = 0;

  @override
  Future<void> dismissPrompt({DateTime? now}) async {}

  @override
  Future<void> markFeedbackSubmitted({DateTime? now}) async {}

  @override
  Future<void> recordReadingSession({DateTime? now}) async {
    recordedSessions++;
  }

  @override
  Future<bool> shouldPrompt({DateTime? now}) async => false;
}

void main() {
  group('HolyQuranApp', () {
    testWidgets('renders MaterialApp', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: HolyQuranApp()));
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('uses the selected app theme mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeProvider.overrideWith((ref) => ThemeMode.dark),
            initializeDataProvider.overrideWith(
              (ref) => Completer<void>().future,
            ),
          ],
          child: const HolyQuranApp(),
        ),
      );
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });
  });

  group('DatabaseErrorApp', () {
    testWidgets('shows database error message', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: DatabaseErrorApp()));
      await tester.pump();
      expect(
        find.textContaining('Could not open the database'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('uses the selected dark theme for the error surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [themeModeProvider.overrideWith((ref) => ThemeMode.dark)],
          child: const DatabaseErrorApp(),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppTheme.darkBackground);
    });
  });

  group('LoadingScreen', () {
    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      final completer = Completer<void>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializeDataProvider.overrideWith((ref) => completer.future),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: LoadingScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.textContaining('Preparing your Digital Sanctuary'),
        findsOneWidget,
      );
      // Resolve to avoid pending-microtask assertion on teardown.
      completer.complete();
    });

    testWidgets('shows error UI when initialization fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializeDataProvider.overrideWith(
              (ref) => Future.error('init failed'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: LoadingScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Failed to load data'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('navigates to HomeScreen when data loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializeDataProvider.overrideWith((ref) async {}),
            surahListProvider.overrideWith((ref) async => []),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: LoadingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('MushafSamplePage', () {
    test('supports the full QCF Mushaf page range', () {
      expect(MushafSampleAssets.containsPage(1), isTrue);
      expect(MushafSampleAssets.containsPage(2), isTrue);
      expect(MushafSampleAssets.containsPage(3), isTrue);
      expect(MushafSampleAssets.containsPage(604), isTrue);
      expect(MushafSampleAssets.containsPage(605), isFalse);
    });

    testWidgets('renders a QCF font Mushaf page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MushafSamplePage(page: 1))),
      );
      await tester.pump();

      expect(find.byType(MushafQcfPage), findsOneWidget);
      expect(find.text('الفاتحة'), findsOneWidget);
      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mushafHeaderBackground')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses dark surrounding chrome in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Scaffold(body: MushafSamplePage(page: 1)),
        ),
      );
      await tester.pump();

      final background = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(MushafSamplePage),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(background.color, AppTheme.darkBackground);
    });

    testWidgets('fits opening Mushaf page on a compact mobile viewport', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(720, 1280);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MushafSamplePage(page: 1))),
      );
      await tester.pumpAndSettle();

      final bodyTextFinder = find.byWidgetPredicate((widget) {
        if (widget is! Text) return false;
        return widget.data == null && widget.textSpan is TextSpan;
      });

      expect(bodyTextFinder, findsOneWidget);
      final bodyText = tester.widget<Text>(bodyTextFinder);
      expect(bodyText.style?.fontSize, lessThan(22));

      final paragraphFinder = find.descendant(
        of: bodyTextFinder,
        matching: find.byType(RichText),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        paragraphFinder.first,
      );

      expect(
        paragraph.getMaxIntrinsicHeight(paragraph.size.width),
        lessThanOrEqualTo(tester.getSize(bodyTextFinder).height),
      );
    });

    testWidgets('explains unsupported page numbers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MushafSamplePage(page: 605))),
      );
      await tester.pump();

      expect(find.textContaining('between 1 and 604'), findsOneWidget);
      expect(find.textContaining('Current page: 605'), findsOneWidget);
    });
  });

  group('HomeScreen', () {
    testWidgets('shows surah list when data is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SurahTile), findsOneWidget);
      expect(find.text('The Opening'), findsOneWidget);
    });

    testWidgets('shows empty state when surah list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => []),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No surahs found.'), findsOneWidget);
    });

    testWidgets('shows error state when load fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) => Future.error('db error')),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to load surahs'), findsOneWidget);
    });

    testWidgets('applies dark mode from the home menu', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ref.watch(themeModeProvider),
              home: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      final darkModeItem = find.ancestor(
        of: find.text('Dark mode'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget.runtimeType.toString().startsWith('CheckedPopupMenuItem'),
        ),
      );
      expect(darkModeItem, findsOneWidget);
      await tester.tap(darkModeItem);
      await tester.pumpAndSettle();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    });

    testWidgets('shows Last Read banner when a reading position exists', (
      tester,
    ) async {
      final position = ReadingPosition(
        verseId: '1:3',
        lastReadAt: DateTime(2026, 5, 24),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => position),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue Reading'), findsOneWidget);
      expect(find.textContaining('The Opening'), findsWidgets);
      expect(find.textContaining('Verse 3'), findsOneWidget);
    });

    testWidgets('does not show Last Read banner when no position saved', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue Reading'), findsNothing);
    });

    testWidgets('tapping Last Read banner navigates to ReadingScreen', (
      tester,
    ) async {
      final position = ReadingPosition(
        verseId: '1:1',
        lastReadAt: DateTime(2026, 5, 24),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => position),
            recentBookmarksProvider.overrideWith((ref) async => const []),
            pageForVerseProvider('1:1').overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue Reading'));
      await tester.pumpAndSettle();
      expect(find.byType(ReadingScreen), findsOneWidget);
    });

    testWidgets('shows bookmarks and removes one from the home screen', (
      tester,
    ) async {
      final repo = _FakeBookmarkRepository();
      final bookmark = Bookmark(
        verseId: '1:1',
        timestamp: DateTime(2026, 5, 24),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkRepositoryProvider.overrideWithValue(repo),
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => [bookmark]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {'1:1'}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bookmarks'), findsOneWidget);
      expect(find.text('The Opening · Verse 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove bookmark'));
      await tester.pump();

      expect(repo.removedVerseIds, ['1:1']);
    });

    testWidgets('opens reading reminders dialog and schedules a reminder', (
      tester,
    ) async {
      final store = _FakePrayerReminderSettingsStore(
        PrayerReminderSettings.defaults,
      );
      final scheduler = _FakePrayerReminderScheduler();
      final service = PrayerReminderService(
        settingsStore: store,
        scheduler: scheduler,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prayerReminderServiceProvider.overrideWithValue(service),
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reading reminders'));
      await tester.pumpAndSettle();

      expect(find.text('Enable reminder'), findsOneWidget);
      await tester.tap(find.text('Enable reminder'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(store.settings.enabled, isTrue);
      expect(scheduler.scheduledSettings?.enabled, isTrue);
      expect(find.text('Reading reminder scheduled'), findsOneWidget);
    });

    testWidgets('stops saving when reminder scheduling fails', (tester) async {
      final store = _FakePrayerReminderSettingsStore(
        PrayerReminderSettings.defaults,
      );
      final scheduler = _FakePrayerReminderScheduler()
        ..requestPermissionError = Exception('notification init failed');
      final service = PrayerReminderService(
        settingsStore: store,
        scheduler: scheduler,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prayerReminderServiceProvider.overrideWithValue(service),
            surahListProvider.overrideWith((ref) async => [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reading reminders'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enable reminder'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enable reminder'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text('Reminder could not be scheduled. Please try again.'),
        findsOneWidget,
      );
      expect(scheduler.scheduledSettings, isNull);
    });
  });

  group('ReadingScreen', () {
    testWidgets('renders with initialVerseId without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pageForVerseProvider('1:1').overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: const MaterialApp(
            home: ReadingScreen(surah: _surah1, initialVerseId: '1:1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
    });

    testWidgets('shows verse list when data is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
    });

    testWidgets(
      'uses comfortable Classic typography and width on compact phones',
      (tester) async {
        const longVerse = Verse(
          verseId: '1:3',
          surahNumber: 1,
          verseNumber: 3,
          arabicText:
              'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ مَـٰلِكِ يَوْمِ ٱلدِّينِ إِيَّاكَ نَعْبُدُ',
        );

        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 640);
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              startPageForSurahProvider(1).overrideWith((ref) async => 1),
              versesBySurahProvider(1).overrideWith((ref) async => [longVerse]),
              bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: ReadingScreen(surah: _surah1),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        final padding = scrollView.padding as EdgeInsets;
        expect(padding.horizontal, 24);

        final contentColumn = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Column),
        );
        expect(tester.getSize(contentColumn).width, 336);

        final richTextFinder = find.textContaining(
          'ٱلرَّحْمَـٰنِ',
          findRichText: true,
        );
        final richText = tester.widget<RichText>(richTextFinder);
        final style = (richText.text as TextSpan).style;
        expect(style?.fontSize, 30);
        expect(style?.height, 2.05);
        expect(tester.getSize(richTextFinder).width, lessThanOrEqualTo(336));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('uses vertical scrolling for Classic and paging for Mushaf', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(
              1,
            ).overrideWith((ref) async => [_verse1, _verse2]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [_verse1, _verse2]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(PageView), findsNothing);

      await tester.tap(find.text('Mushaf'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('switches between Classic and Mushaf modes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
      expect(find.byType(MushafQcfPage), findsNothing);

      await tester.tap(find.text('Mushaf'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(MushafQcfPage), findsOneWidget);
      expect(find.textContaining('بِسْمِ', findRichText: true), findsNothing);

      await tester.tapAt(const Offset(12, 12));
      await tester.pump();

      await tester.tap(find.text('Classic'));
      await tester.pumpAndSettle();

      expect(find.textContaining('بِسْمِ', findRichText: true), findsOneWidget);
    });

    testWidgets('shows Mushaf page number as a temporary overlay', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('mushafPageNumberOverlay')),
        findsNothing,
      );

      await tester.tap(find.text('Mushaf'));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('mushafPageNumberOverlay')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('mushafPageNumberText')))
            .data,
        '١',
      );

      await tester.pump(const Duration(milliseconds: 1501));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('mushafPageNumberOverlay')),
        findsNothing,
      );
    });

    testWidgets('uses dark Mushaf page overlay in dark mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mushaf'));
      await tester.pump();

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(const ValueKey('mushafPageNumberOverlay')),
                  )
                  .decoration
              as BoxDecoration;
      final overlayText = tester.widget<Text>(
        find.byKey(const ValueKey('mushafPageNumberText')),
      );

      expect(decoration.color, AppTheme.darkSurface.withValues(alpha: .92));
      expect(overlayText.style?.color, AppTheme.darkTextPrimary);
    });

    testWidgets('saves tapped Mushaf verse as the last-read VerseID', (
      tester,
    ) async {
      final positionRepo = _FakeReadingPositionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingPositionRepositoryProvider.overrideWithValue(positionRepo),
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(
              1,
            ).overrideWith((ref) async => [_verse1, _verse2]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [_verse1, _verse2]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mushaf'));
      await tester.pump();
      await tester.pump();

      final qcfPage = tester.widget<MushafQcfPage>(find.byType(MushafQcfPage));
      expect(qcfPage.onTap, isNotNull);
      qcfPage.onTap!.call(1, 2);
      await tester.pumpAndSettle();

      expect(find.byType(VerseDetailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(positionRepo.savedPosition?.verseId, '1:2');
    });

    testWidgets('records local engagement when opening and saving reading', (
      tester,
    ) async {
      final positionRepo = _FakeReadingPositionRepository();
      final feedbackPromptService = _FakeFeedbackPromptService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingPositionRepositoryProvider.overrideWithValue(positionRepo),
            feedbackPromptServiceProvider.overrideWithValue(
              feedbackPromptService,
            ),
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(positionRepo.savedPosition?.verseId, '1:1');
      expect(feedbackPromptService.recordedSessions, 2);
    });

    testWidgets('opens Focus Mode from a Classic verse long press', (
      tester,
    ) async {
      final positionRepo = _FakeReadingPositionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingPositionRepositoryProvider.overrideWithValue(positionRepo),
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(
              1,
            ).overrideWith((ref) async => [_verse1, _verse2]),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => [_verse1, _verse2]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.textContaining('بِسْمِ', findRichText: true));
      await tester.pump();

      expect(find.byType(VerseDetailScreen), findsOneWidget);
      expect(find.text('1:1'), findsOneWidget);
      expect(find.text('In the name of Allah'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(positionRepo.savedPosition?.verseId, '1:1');
    });

    testWidgets('saves the visible Classic verse as the last-read VerseID', (
      tester,
    ) async {
      final positionRepo = _FakeReadingPositionRepository();
      final verses = _surahVerses(40);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readingPositionRepositoryProvider.overrideWithValue(positionRepo),
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => verses),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('آية 40', findRichText: true),
        100,
        scrollable: find.byType(Scrollable),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(positionRepo.savedPosition?.verseId, isNot('1:1'));
    });

    testWidgets('uses KFGQPC font for Arabic Quran text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      expect(
        (richText.text as TextSpan).style?.fontFamily,
        'KFGQPCHafsUthmanicScript',
      );
    });

    testWidgets(
      'uses the Al-Fatihah Bismillah treatment when verse data includes it',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              startPageForSurahProvider(1).overrideWith((ref) async => 1),
              versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
              bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: ReadingScreen(surah: _surah1),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final richText = tester.widget<RichText>(
          find.textContaining('بِسْمِ', findRichText: true),
        );
        final children = (richText.text as TextSpan).children!;
        expect(children.first.style?.color, isNull);
        expect(children.first.style?.fontSize, 28);
        expect(children.first.style?.height, 2.0);
      },
    );

    testWidgets('styles only the Bismillah phrase when more text follows', (
      tester,
    ) async {
      const verse = Verse(
        verseId: '1:1',
        surahNumber: 1,
        verseNumber: 1,
        arabicText: '$_bismillah ٱلْحَمْدُ لِلَّهِ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      final children = (richText.text as TextSpan).children!;
      final bismillahSpan = children[0] as TextSpan;
      final remainingTextSpan = children[1] as TextSpan;
      expect(bismillahSpan.text, _bismillah);
      expect(bismillahSpan.style?.color, isNull);
      expect(bismillahSpan.style?.fontSize, 28);
      expect(bismillahSpan.style?.height, 2.0);
      expect(remainingTextSpan.text, ' ٱلْحَمْدُ لِلَّهِ');
      expect(remainingTextSpan.style, isNull);
    });

    testWidgets(
      'shows Bismillah before Surahs except Al-Fatihah and At-Tawbah',
      (tester) async {
        const surah2 = Surah(
          surahNumber: 2,
          nameArabic: 'البقرة',
          nameEnglish: 'The Cow',
          numberOfVerses: 286,
        );
        const verse = Verse(
          verseId: '2:1',
          surahNumber: 2,
          verseNumber: 1,
          arabicText: 'الٓمٓ',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              startPageForSurahProvider(2).overrideWith((ref) async => 2),
              versesBySurahProvider(2).overrideWith((ref) async => [verse]),
              bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
              surahListProvider.overrideWith((ref) async => [surah2]),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: ReadingScreen(surah: surah2),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bismillah = tester.widget<Text>(find.text(_bismillah));
        final context = tester.element(find.text(_bismillah));
        expect(
          bismillah.style?.color,
          Theme.of(context).textTheme.headlineLarge?.color,
        );
        expect(bismillah.style?.fontSize, 28);
        expect(bismillah.style?.height, 2.0);
      },
    );

    testWidgets('does not show Bismillah for a continuation verse in Classic', (
      tester,
    ) async {
      const surah2 = Surah(
        surahNumber: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'The Cow',
        numberOfVerses: 286,
      );
      const verse = Verse(
        verseId: '2:20',
        surahNumber: 2,
        verseNumber: 20,
        arabicText: 'يَكَادُ ٱلْبَرْقُ يَخْطَفُ أَبْصَـٰرَهُمْ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(2).overrideWith((ref) async => 4),
            versesBySurahProvider(2).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(2).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [surah2]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: surah2),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_bismillah), findsNothing);
    });

    testWidgets('does not show Bismillah before At-Tawbah', (tester) async {
      const surah9 = Surah(
        surahNumber: 9,
        nameArabic: 'التوبة',
        nameEnglish: 'The Repentance',
        numberOfVerses: 129,
      );
      const verse = Verse(
        verseId: '9:1',
        surahNumber: 9,
        verseNumber: 1,
        arabicText: 'بَرَآءَةٌ مِّنَ ٱللَّهِ',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(9).overrideWith((ref) async => 187),
            versesBySurahProvider(9).overrideWith((ref) async => [verse]),
            bookmarksBySurahProvider(9).overrideWith((ref) async => {}),
            surahListProvider.overrideWith((ref) async => [surah9]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: surah9),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_bismillah), findsNothing);
    });

    testWidgets('shows error state when verse load fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(
              1,
            ).overrideWith((ref) => Future.error('db error')),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to load verses'), findsOneWidget);
    });

    testWidgets('shows bookmark icon for bookmarked verse', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {'1:1'}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      final context = tester.element(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      expect(
        (richText.text as TextSpan).style?.color,
        Theme.of(context).colorScheme.onPrimaryContainer,
      );
    });

    testWidgets('does not show bookmark icon for unbookmarked verse', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesBySurahProvider(1).overrideWith((ref) async => [_verse1]),
            versesByPageProvider(1).overrideWith((ref) async => [_verse1]),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReadingScreen(surah: _surah1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      final context = tester.element(
        find.textContaining('بِسْمِ', findRichText: true),
      );
      expect(
        (richText.text as TextSpan).style?.color,
        Theme.of(context).textTheme.headlineLarge?.color,
      );
    });
  });

  group('SurahTile', () {
    testWidgets('renders Arabic name, English name and verse count', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurahTile(surah: _surah1, onTap: () => tapped = true),
          ),
        ),
      );
      expect(find.text('الفاتحة'), findsOneWidget);
      expect(find.text('The Opening'), findsOneWidget);
      expect(find.text('7 verses'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byType(SurahTile));
      expect(tapped, isTrue);
    });
  });

  group('VerseCard', () {
    testWidgets('renders Arabic text and translation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VerseCard(verse: _verse1)),
        ),
      );
      expect(find.text('بِسْمِ اللَّهِ'), findsOneWidget);
      expect(find.text('In the name of Allah'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders without translation when null', (tester) async {
      const verse = Verse(
        verseId: '2:1',
        surahNumber: 2,
        verseNumber: 1,
        arabicText: 'الم',
        translation: null,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VerseCard(verse: verse)),
        ),
      );
      expect(find.text('الم'), findsOneWidget);
    });

    testWidgets('shows bookmark icon when isBookmarked is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VerseCard(verse: _verse1, isBookmarked: true)),
        ),
      );
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('hides bookmark icon when isBookmarked is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VerseCard(verse: _verse1, isBookmarked: false)),
        ),
      );
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('calls onBookmarkToggle on long press', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseCard(
              verse: _verse1,
              onBookmarkToggle: () => toggled = true,
            ),
          ),
        ),
      );
      final topLeft = tester.getTopLeft(find.byType(VerseCard));
      await tester.longPressAt(topLeft + const Offset(10, 10));
      expect(toggled, isTrue);
    });
  });

  group('VerseDetailScreen', () {
    testWidgets('renders large Quran text and translation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: VerseDetailScreen(verse: _verse1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final arabicText = tester.widget<Text>(find.text(_verse1.arabicText));
      expect(arabicText.style?.fontSize, 36);
      expect(find.text('In the name of Allah'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('can bookmark the focused verse locally', (tester) async {
      final bookmarkRepo = _FakeBookmarkRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkRepositoryProvider.overrideWithValue(bookmarkRepo),
            bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: VerseDetailScreen(verse: _verse1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();

      expect(bookmarkRepo.addedVerseIds, ['1:1']);
    });
  });
}
