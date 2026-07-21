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

  CloudflareFeedbackTransport({required Uri baseUri, required this.client})
    : endpoint = baseUri.resolve('/v1/feedback');

  @override
  Future<void> submit(Map<String, dynamic> payload) async {
    try {
      final response = await client
          .post(
            endpoint,
            headers: const {'content-type': 'application/json'},
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
    } catch (e) {
      throw FeedbackSubmissionException('Feedback transport failed.', e);
    }
  }
}

class FeedbackValidationException implements Exception {
  final String message;

  const FeedbackValidationException(this.message);
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
