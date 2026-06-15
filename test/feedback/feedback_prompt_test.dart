import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/feedback/feedback_prompt_service.dart';

void main() {
  group('FeedbackPromptService', () {
    test('prompts after seven distinct reading days', () async {
      final store = _MemoryFeedbackPromptStore();
      final service = FeedbackPromptService(store: store);

      for (var day = 1; day <= 6; day++) {
        await service.recordReadingSession(now: DateTime(2026, 6, day, 20));
      }

      expect(
        await service.shouldPrompt(now: DateTime(2026, 6, 6, 21)),
        isFalse,
      );

      await service.recordReadingSession(now: DateTime(2026, 6, 7, 20));

      expect(await service.shouldPrompt(now: DateTime(2026, 6, 7, 21)), isTrue);
    });

    test('counts multiple sessions on the same day only once', () async {
      final store = _MemoryFeedbackPromptStore();
      final service = FeedbackPromptService(store: store);

      await service.recordReadingSession(now: DateTime(2026, 6, 1, 9));
      await service.recordReadingSession(now: DateTime(2026, 6, 1, 21));

      expect((await store.load()).readingDayCount, 1);
    });

    test('dismisses prompts for the cooldown period', () async {
      final store = _MemoryFeedbackPromptStore();
      final service = FeedbackPromptService(store: store);

      for (var day = 1; day <= 7; day++) {
        await service.recordReadingSession(now: DateTime(2026, 6, day, 20));
      }

      await service.dismissPrompt(now: DateTime(2026, 6, 7, 21));

      expect(
        await service.shouldPrompt(now: DateTime(2026, 7, 6, 21)),
        isFalse,
      );
      expect(await service.shouldPrompt(now: DateTime(2026, 7, 8, 21)), isTrue);
    });

    test('does not prompt again after feedback is submitted', () async {
      final store = _MemoryFeedbackPromptStore();
      final service = FeedbackPromptService(store: store);

      for (var day = 1; day <= 7; day++) {
        await service.recordReadingSession(now: DateTime(2026, 6, day, 20));
      }
      await service.markFeedbackSubmitted(now: DateTime(2026, 6, 7, 21));

      expect(
        await service.shouldPrompt(now: DateTime(2026, 12, 1, 21)),
        isFalse,
      );
    });
  });
}

class _MemoryFeedbackPromptStore implements FeedbackPromptStore {
  FeedbackPromptState state = const FeedbackPromptState();

  @override
  Future<FeedbackPromptState> load() async => state;

  @override
  Future<void> save(FeedbackPromptState state) async {
    this.state = state;
  }
}
