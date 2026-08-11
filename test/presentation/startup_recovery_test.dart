import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/presentation/app.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';

void main() {
  group('DatabaseErrorApp recovery', () {
    testWidgets('shows progress and enters the app when retry succeeds', (
      tester,
    ) async {
      final retry = Completer<void>();
      var attempts = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prayerReminderTimezoneSynchronizerProvider.overrideWithValue(
              () async {},
            ),
            initializeDataProvider.overrideWith((ref) async {}),
            surahListProvider.overrideWith((ref) async => []),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: DatabaseErrorApp(
            retryDatabase: () {
              attempts += 1;
              return retry.future;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('databaseRetryButton')));
      await tester.pump();

      expect(attempts, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      retry.complete();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('keeps recovery available after repeated database failures', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: DatabaseErrorApp(
            retryDatabase: () async {
              attempts += 1;
              throw StateError('/private/path/should-not-appear');
            },
          ),
        ),
      );
      await tester.pump();

      for (
        var expectedAttempts = 1;
        expectedAttempts <= 2;
        expectedAttempts++
      ) {
        await tester.tap(find.byKey(const ValueKey('databaseRetryButton')));
        await tester.pump();
        await tester.pump();

        expect(attempts, expectedAttempts);
        expect(
          find.byKey(const ValueKey('databaseRetryButton')),
          findsOneWidget,
        );
        expect(find.textContaining('/private/path'), findsNothing);
      }
    });
  });
}
