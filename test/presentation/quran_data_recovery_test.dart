import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';
import 'package:holy_quran_app/presentation/screens/loading_screen.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';

void main() {
  group('LoadingScreen recovery', () {
    testWidgets('retries Quran loading and navigates after success', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializeDataProvider.overrideWith((ref) async {
              attempts += 1;
              if (attempts == 1) throw StateError('bundled data unavailable');
            }),
            surahListProvider.overrideWith((ref) async => []),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const LoadingScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(attempts, 1);
      await tester.tap(find.byKey(const ValueKey('quranDataRetryButton')));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('keeps retry available after repeated Quran load failures', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initializeDataProvider.overrideWith((ref) async {
              attempts += 1;
              throw StateError('asset details should stay diagnostic-only');
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const LoadingScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      for (
        var expectedAttempts = 2;
        expectedAttempts <= 3;
        expectedAttempts++
      ) {
        await tester.tap(find.byKey(const ValueKey('quranDataRetryButton')));
        await tester.pump();
        await tester.pump();

        expect(attempts, expectedAttempts);
        expect(
          find.byKey(const ValueKey('quranDataRetryButton')),
          findsOneWidget,
        );
        expect(find.textContaining('diagnostic-only'), findsNothing);
      }
    });
  });
}
