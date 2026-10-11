import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

class CloudflareFeedbackTransport implements FeedbackTransport {
  final http.Client client;
  final Uri endpoint;
  final Future<String> Function() clientId;

  CloudflareFeedbackTransport({
    required Uri baseUri,
    required this.client,
    required this.clientId,
  }) : endpoint = baseUri.resolve('/v1/feedback');

  @override
  Future<void> submit(Map<String, dynamic> payload) async {
    try {
      final resolvedClientId = await clientId();
      final response = await client
          .post(
            endpoint,
            headers: {
              'content-type': 'application/json',
              'x-client-id': resolvedClientId,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const FeedbackSubmissionException();
      }
    } on FeedbackSubmissionException {
      rethrow;
    } catch (error) {
      throw FeedbackSubmissionException('Feedback transport failed.', error);
    }
  }
}

class UnconfiguredFeedbackTransport implements FeedbackTransport {
  const UnconfiguredFeedbackTransport();

  @override
  Future<void> submit(Map<String, dynamic> payload) {
    throw const FeedbackSubmissionException(
      'Feedback is not configured on this build.',
    );
  }
}

enum FeedbackChoice {
  readingDisplay('reading_display'),
  translationTafsir('translation_tafsir'),
  reminders('reminders'),
  appProblem('app_problem'),
  suggestion('suggestion');

  final String code;
  const FeedbackChoice(this.code);
}

class AnonymousFeedbackService {
  final FeedbackTransport transport;

  const AnonymousFeedbackService({required this.transport});

  Future<void> submitFeedback(
    FeedbackChoice choice, {
    FeedbackMetadata? metadata,
  }) async {
    final safeMetadata = metadata ?? FeedbackMetadata.current();
    final payload = <String, dynamic>{
      'feedback_choice': choice.code,
      'platform': safeMetadata.platform,
      'app_version': safeMetadata.appVersion,
    };

    try {
      await transport.submit(payload);
    } on FeedbackSubmissionException {
      rethrow;
    } catch (e) {
      throw FeedbackSubmissionException('Feedback transport failed.', e);
    }
  }
}

class FeedbackSubmissionException implements Exception {
  final String message;
  final Object? cause;

  const FeedbackSubmissionException([
    this.message = 'Feedback could not be submitted.',
    this.cause,
  ]);

  @override
  String toString() => cause == null
      ? 'FeedbackSubmissionException: $message'
      : 'FeedbackSubmissionException: $message Cause: $cause';
}
