import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_quran_app/data/feedback/anonymous_feedback_service.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:holy_quran_app/presentation/providers/quran_providers.dart';
import 'package:holy_quran_app/presentation/screens/home_screen.dart';

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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahListProvider.overrideWith(
              (ref) async => const [
                Surah(
                  surahNumber: 1,
                  nameArabic: 'الفاتحة',
                  nameEnglish: 'Al-Fatihah',
                  numberOfVerses: 7,
                ),
              ],
            ),
            lastReadPositionProvider.overrideWith((ref) async => null),
            recentBookmarksProvider.overrideWith(
              (ref) async => const <Bookmark>[],
            ),
            anonymousFeedbackServiceProvider.overrideWithValue(feedbackService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send feedback'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Thank you for the app.');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(feedbackService.submittedText, 'Thank you for the app.');
      expect(find.text('Feedback sent'), findsOneWidget);
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

  _RecordingFeedbackService() : super(transport: _FakeFeedbackTransport());

  @override
  Future<void> submitFeedback(String text, {FeedbackMetadata? metadata}) async {
    submittedText = text;
  }
}
