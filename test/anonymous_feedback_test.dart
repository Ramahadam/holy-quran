import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_quran_app/data/feedback/anonymous_feedback_service.dart';
import 'package:holy_quran_app/data/feedback/feedback_prompt_service.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/domain/models/verse.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';
import 'package:holy_quran_app/presentation/screens/reading_screen.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';

const _surah1 = Surah(
  surahNumber: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'Al-Fatihah',
  numberOfVerses: 7,
);

const _verse1 = Verse(
  verseId: '1:1',
  surahNumber: 1,
  verseNumber: 1,
  arabicText: 'بِسْمِ اللَّهِ',
  translation: 'In the name of Allah',
);

void main() {
  group('AnonymousFeedbackService', () {
    test('submits trimmed feedback with privacy-safe metadata only', () async {
      final transport = _FakeFeedbackTransport();
      final service = AnonymousFeedbackService(transport: transport);

      await service.submitFeedback(
        '  Please add larger font controls.  ',
        metadata: const FeedbackMetadata(
          platform: 'android',
          appVersion: '1.0.0+1',
        ),
      );

      expect(transport.payloads, hasLength(1));
      expect(transport.payloads.single, {
        'feedback_text': 'Please add larger font controls.',
        'platform': 'android',
        'app_version': '1.0.0+1',
      });
      expect(
        transport.payloads.single.keys,
        isNot(
          containsAll([
            'email',
            'name',
            'bookmarks',
            'reading_history',
            'last_read_position',
          ]),
        ),
      );
    });

    test('rejects empty feedback', () async {
      final service = AnonymousFeedbackService(
        transport: _FakeFeedbackTransport(),
      );

      expect(
        () => service.submitFeedback('   '),
        throwsA(isA<FeedbackValidationException>()),
      );
    });

    test('rejects overly long feedback', () async {
      final service = AnonymousFeedbackService(
        transport: _FakeFeedbackTransport(),
      );

      expect(
        () => service.submitFeedback(
          List.filled(AnonymousFeedbackService.maxLength + 1, 'a').join(),
        ),
        throwsA(isA<FeedbackValidationException>()),
      );
    });

    test(
      'reports submit failures without exposing transport details',
      () async {
        final service = AnonymousFeedbackService(
          transport: _FakeFeedbackTransport(
            error: Exception('postgres timeout'),
          ),
        );

        expect(
          () => service.submitFeedback('The app is calming.'),
          throwsA(isA<FeedbackSubmissionException>()),
        );
      },
    );
  });

  group('HomeScreen feedback', () {
    testWidgets('opens feedback dialog and submits through provider', (
      tester,
    ) async {
      final feedbackService = _RecordingFeedbackService();
      final promptService = _RecordingFeedbackPromptService(
        shouldPrompt: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => const [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith(
              (ref) async => const <Bookmark>[],
            ),
            anonymousFeedbackServiceProvider.overrideWithValue(feedbackService),
            feedbackPromptServiceProvider.overrideWithValue(promptService),
            feedbackPromptShouldShowProvider.overrideWith(
              (ref) async => promptService.shouldPrompt(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send feedback'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Thank you for the app.');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(feedbackService.submittedText, 'Thank you for the app.');
      expect(find.text('Feedback sent'), findsOneWidget);
    });

    testWidgets('uses the modern home dialog treatment for feedback', (
      tester,
    ) async {
      final feedbackService = _RecordingFeedbackService();
      final promptService = _RecordingFeedbackPromptService(
        shouldPrompt: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => const [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith(
              (ref) async => const <Bookmark>[],
            ),
            anonymousFeedbackServiceProvider.overrideWithValue(feedbackService),
            feedbackPromptServiceProvider.overrideWithValue(promptService),
            feedbackPromptShouldShowProvider.overrideWith(
              (ref) async => promptService.shouldPrompt(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send feedback'));
      await tester.pumpAndSettle();

      final colors = AppTheme.light.colorScheme;
      final dialogFinder = find.byKey(const ValueKey('homeDialog-feedback'));
      expect(dialogFinder, findsOneWidget);
      final dialog = tester.widget<AlertDialog>(dialogFinder);
      expect(dialog.backgroundColor, colors.surfaceContainerHigh);
      expect(dialog.surfaceTintColor, Colors.transparent);
      expect(dialog.shape, isA<RoundedRectangleBorder>());
      final shape = dialog.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(24));
      expect(shape.side.color, colors.outlineVariant.withValues(alpha: 0.7));
      expect(
        find.byKey(const ValueKey('homeDialogHeader-feedback')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('feedbackPrivacyNotice')),
        findsOneWidget,
      );
    });

    testWidgets('shows heartbeat prompt and opens anonymous feedback', (
      tester,
    ) async {
      final feedbackService = _RecordingFeedbackService();
      final promptService = _RecordingFeedbackPromptService(shouldPrompt: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => const [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith(
              (ref) async => const <Bookmark>[],
            ),
            anonymousFeedbackServiceProvider.overrideWithValue(feedbackService),
            feedbackPromptServiceProvider.overrideWithValue(promptService),
            feedbackPromptShouldShowProvider.overrideWith(
              (ref) async => promptService.shouldPrompt(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('How is your Quran reading experience?'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('homeDialog-feedbackPrompt')),
        findsOneWidget,
      );

      await tester.tap(find.text('Give feedback'));
      await tester.pumpAndSettle();

      expect(promptService.dismissed, isFalse);
      expect(find.text('Send feedback'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Mushaf mode is calm.');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(feedbackService.submittedText, 'Mushaf mode is calm.');
      expect(promptService.submitted, isTrue);
      expect(find.text('Feedback sent'), findsOneWidget);
    });

    testWidgets(
      'keeps heartbeat prompt eligible when feedback submit fails and is canceled',
      (tester) async {
        final feedbackService = _RecordingFeedbackService(shouldFail: true);
        final promptService = _RecordingFeedbackPromptService(
          shouldPrompt: true,
        );

        List<Override> overrides() => [
          surahListProvider.overrideWith((ref) async => const [_surah1]),
          lastReadPositionProvider.overrideWith((ref) async => null),
          recentBookmarksProvider.overrideWith(
            (ref) async => const <Bookmark>[],
          ),
          anonymousFeedbackServiceProvider.overrideWithValue(feedbackService),
          feedbackPromptServiceProvider.overrideWithValue(promptService),
          feedbackPromptShouldShowProvider.overrideWith(
            (ref) async => promptService.shouldPrompt(),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides(),
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Give feedback'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Please add retry.');
        await tester.tap(find.text('Send'));
        await tester.pumpAndSettle();

        expect(
          find.text('Feedback could not be sent. Please try again later.'),
          findsOneWidget,
        );
        expect(promptService.dismissed, isFalse);
        expect(promptService.submitted, isFalse);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(promptService.dismissed, isFalse);
        expect(promptService.submitted, isFalse);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides(),
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('How is your Quran reading experience?'),
          findsOneWidget,
        );
      },
    );

    testWidgets('dismisses heartbeat prompt without opening feedback', (
      tester,
    ) async {
      final promptService = _RecordingFeedbackPromptService(shouldPrompt: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => const [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith(
              (ref) async => const <Bookmark>[],
            ),
            feedbackPromptServiceProvider.overrideWithValue(promptService),
            feedbackPromptShouldShowProvider.overrideWith(
              (ref) async => promptService.shouldPrompt(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(promptService.dismissed, isTrue);
      expect(find.text('How is your Quran reading experience?'), findsNothing);
      expect(find.text('Send feedback'), findsNothing);
    });

    testWidgets('rechecks heartbeat prompt after returning from reading', (
      tester,
    ) async {
      final promptService = _RecordingFeedbackPromptService(
        shouldPrompt: false,
        promptResponses: [false, true],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith((ref) async => const [_surah1]),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith(
              (ref) async => const <Bookmark>[],
            ),
            startPageForSurahProvider(1).overrideWith((ref) async => 1),
            versesByPageProvider(
              1,
            ).overrideWith((ref) async => const [_verse1]),
            classicVersesProvider(
              1,
            ).overrideWith((ref) async => const [_verse1]),
            bookmarksBySurahProvider(
              1,
            ).overrideWith((ref) async => const <String>{}),
            feedbackPromptServiceProvider.overrideWithValue(promptService),
            feedbackPromptShouldShowProvider.overrideWith(
              (ref) async => promptService.shouldPrompt(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('How is your Quran reading experience?'), findsNothing);

      await tester.tap(find.text('الفاتحة'));
      await tester.pumpAndSettle();

      expect(find.byType(ReadingScreen), findsOneWidget);

      Navigator.of(tester.element(find.byType(ReadingScreen))).pop();
      await tester.pumpAndSettle();

      expect(
        find.text('How is your Quran reading experience?'),
        findsOneWidget,
      );
    });
  });
}

class _FakeFeedbackTransport implements FeedbackTransport {
  final Exception? error;
  final payloads = <Map<String, dynamic>>[];

  _FakeFeedbackTransport({this.error});

  @override
  Future<void> submit(Map<String, dynamic> payload) async {
    if (error != null) throw error!;
    payloads.add(payload);
  }
}

class _RecordingFeedbackService extends AnonymousFeedbackService {
  String? submittedText;
  final bool shouldFail;

  _RecordingFeedbackService({this.shouldFail = false})
    : super(transport: _FakeFeedbackTransport());

  @override
  Future<void> submitFeedback(String text, {FeedbackMetadata? metadata}) async {
    if (shouldFail) {
      throw FeedbackSubmissionException();
    }
    submittedText = text;
  }
}

class _RecordingFeedbackPromptService implements FeedbackPromptController {
  bool shouldShowPrompt;
  bool dismissed = false;
  bool submitted = false;
  int recordedSessions = 0;
  final List<bool> _promptResponses;

  _RecordingFeedbackPromptService({
    required bool shouldPrompt,
    List<bool> promptResponses = const [],
  }) : shouldShowPrompt = shouldPrompt,
       _promptResponses = List.of(promptResponses);

  @override
  Future<void> dismissPrompt({DateTime? now}) async {
    dismissed = true;
    shouldShowPrompt = false;
  }

  @override
  Future<void> markFeedbackSubmitted({DateTime? now}) async {
    submitted = true;
    shouldShowPrompt = false;
  }

  @override
  Future<void> recordReadingSession({DateTime? now}) async {
    recordedSessions++;
  }

  @override
  Future<bool> shouldPrompt({DateTime? now}) async {
    if (_promptResponses.isNotEmpty) {
      shouldShowPrompt = _promptResponses.removeAt(0);
    }
    return shouldShowPrompt;
  }
}
