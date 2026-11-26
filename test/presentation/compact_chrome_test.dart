import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/l10n/app_localizations.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';
import 'package:holy_quran_app/presentation/widgets/home_backup_passphrase_dialog.dart';
import 'package:holy_quran_app/presentation/widgets/mushaf_reader_chrome.dart';

import '../support/reading_test_fixtures.dart';

void _landscape(WidgetTester tester, {double keyboard = 0}) {
  tester.view
    ..physicalSize = const Size(1600, 720)
    ..devicePixelRatio = 2
    ..viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
}

Widget _home() => ProviderScope(
  overrides: [
    surahListProvider.overrideWith((ref) async => [classicSurah1]),
    lastReadPositionProvider.overrideWith(
      (ref) async =>
          ReadingPosition(verseId: '1:3', lastReadAt: DateTime(2026)),
    ),
    pageForVerseProvider('1:3').overrideWith((ref) async => 1),
    feedbackPromptShouldShowProvider.overrideWith((ref) async => false),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const HomeScreen(),
  ),
);

void main() {
  testWidgets('home header is standard height in portrait', (tester) async {
    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AppBar)).height, lessThanOrEqualTo(64));
  });

  testWidgets('home header is hidden in compact-height landscape', (
    tester,
  ) async {
    _landscape(tester);
    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('continue reading card is compact', (tester) async {
    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('continueReadingCard'))).height,
      lessThanOrEqualTo(120),
    );
  });

  testWidgets('classic reader bar hides on scroll down and returns on up', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startPageForSurahProvider(1).overrideWith((ref) async => 1),
          classicVersesProvider(
            1,
          ).overrideWith((ref) async => classicSurahVerses(60)),
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          readingPositionRepositoryProvider.overrideWithValue(
            FakeReadingPositionRepository(),
          ),
        ],
        child: const MaterialApp(home: ReadingScreen(surah: classicSurah1)),
      ),
    );
    await tester.pumpAndSettle();
    final bar = find.byKey(const ValueKey('readerAppBar'));
    expect(bar.hitTestable(), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(bar.hitTestable(), findsNothing);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(bar.hitTestable(), findsOneWidget);
  });

  testWidgets('mushaf locks portrait and restores rotation on exit', (
    tester,
  ) async {
    final orientations = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          orientations.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MushafReaderChrome(
          pageNumber: 1,
          showControls: false,
          showPageNumber: false,
          appBar: AppBar(),
          reader: const SizedBox(),
          onShowControls: () {},
        ),
      ),
    );
    await tester.pump();
    expect(orientations.last, ['DeviceOrientation.portraitUp']);

    await tester.pumpWidget(const SizedBox());
    expect(orientations.last, isEmpty);
  });

  testWidgets('backup dialog scrolls in landscape with the keyboard open', (
    tester,
  ) async {
    _landscape(tester, keyboard: 400);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const HomeBackupPassphraseDialog(
                  purpose: BackupPassphrasePurpose.save,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(find.byType(TextField).first.hitTestable(), findsOneWidget);
  });

  testWidgets('home title outranks Surah names', (tester) async {
    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('القرآن الكريم'),
      ),
    );
    final surah = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('surahCard-1')),
        matching: find.text(classicSurah1.nameArabic),
      ),
    );
    final surahSize =
        surah.style?.fontSize ??
        Theme.of(
          tester.element(find.byType(HomeScreen)),
        ).textTheme.titleMedium!.fontSize!;
    expect(title.style!.fontSize!, greaterThanOrEqualTo(surahSize + 6));
    expect(title.style!.fontWeight, FontWeight.w700);
  });

  test('app bars separate from content scrolled under them', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.appBarTheme.scrolledUnderElevation, greaterThan(0));
      expect(theme.appBarTheme.shadowColor!.a, greaterThan(0));
    }
  });

  testWidgets('index handle names the Surah at the top while dragging', (
    tester,
  ) async {
    final surahs = [
      for (var n = 1; n <= 114; n++)
        Surah(
          surahNumber: n,
          nameArabic: 'سورة $n',
          nameEnglish: 'Surah $n',
          numberOfVerses: 7,
        ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahListProvider.overrideWith((ref) async => surahs),
          lastReadPositionProvider.overrideWith((ref) async => null),
          feedbackPromptShouldShowProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('homeQuranScroll')),
      const Offset(0, -200),
    );
    await tester.pump();

    final handle = find.byKey(const ValueKey('fastScrollHandle'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveTo(Offset(tester.getCenter(handle).dx, 5000));
    await tester.pump();
    await tester.pump();
    final label = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('fastScrollLabel')),
        matching: find.byType(Text),
      ),
    );
    final number = int.parse(label.data!.split(' · ').first);
    expect(number, greaterThan(100));
    // The labelled row is the first row visible under the top of the list.
    final listTop = tester
        .getTopLeft(find.byKey(const ValueKey('homeQuranScroll')))
        .dy;
    final row = tester.getRect(find.byKey(ValueKey('surahCard-$number')));
    expect(row.bottom, greaterThan(listTop));
    expect(row.top, lessThanOrEqualTo(listTop));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('classic reader handle shows page and verse', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startPageForSurahProvider(1).overrideWith((ref) async => 1),
          classicVersesProvider(
            1,
          ).overrideWith((ref) async => classicSurahVerses(300)),
          bookmarksBySurahProvider(1).overrideWith((ref) async => {}),
          readingPositionRepositoryProvider.overrideWithValue(
            FakeReadingPositionRepository(),
          ),
        ],
        child: const MaterialApp(home: ReadingScreen(surah: classicSurah1)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pump();

    final handle = find.byKey(const ValueKey('fastScrollHandle'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('fastScrollLabel')),
        matching: find.textContaining(RegExp(r'^Page \d+ · Verse \d+$')),
      ),
      findsOneWidget,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
