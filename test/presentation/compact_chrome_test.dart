import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';
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
}
