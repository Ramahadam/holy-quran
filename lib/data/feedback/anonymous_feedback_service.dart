import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackMetadata {
  final String platform;
  final String appVersion;

  const FeedbackMetadata({required this.platform, required this.appVersion});

  factory FeedbackMetadata.current() {
    return FeedbackMetadata(
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      appVersion: const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: 'unknown',
      ),
    );
  }
}

abstract class FeedbackTransport {
  Future<void> submit(Map<String, dynamic> payload);
}

class SupabaseFeedbackTransport implements FeedbackTransport {
  final SupabaseClient client;
  final String tableName;

  const SupabaseFeedbackTransport({
    required this.client,
    this.tableName = 'anonymous_feedback',
  });

  @override
  Future<void> submit(Map<String, dynamic> payload) {
    return client.from(tableName).insert(payload);
  }
}

class UnconfiguredFeedbackTransport implements FeedbackTransport {
  const UnconfiguredFeedbackTransport();

  @override
  Future<void> submit(Map<String, dynamic> payload) {
    throw const FeedbackSubmissionException();
  }
}

class AnonymousFeedbackService {
  static const int maxLength = 2000;

  final FeedbackTransport transport;

  const AnonymousFeedbackService({required this.transport});

  Future<void> submitFeedback(String text, {FeedbackMetadata? metadata}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const FeedbackValidationException('Feedback cannot be empty.');
    }
    if (trimmed.length > maxLength) {
      throw const FeedbackValidationException('Feedback is too long.');
    }

    final safeMetadata = metadata ?? FeedbackMetadata.current();
    final payload = <String, dynamic>{
      'feedback_text': trimmed,
      'platform': safeMetadata.platform,
      'app_version': safeMetadata.appVersion,
    };

    try {
      await transport.submit(payload);
    } on FeedbackSubmissionException {
      rethrow;
    } catch (_) {
      throw const FeedbackSubmissionException();
    }
  }
}

class FeedbackValidationException implements Exception {
  final String message;

  const FeedbackValidationException(this.message);
}

class FeedbackSubmissionException implements Exception {
  const FeedbackSubmissionException();
}
