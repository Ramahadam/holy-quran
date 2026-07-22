import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/feedback/anonymous_feedback_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CloudflareFeedbackTransport', () {
    test('posts anonymous feedback to the Worker', () async {
      late http.Request capturedRequest;
      final transport = CloudflareFeedbackTransport(
        baseUri: Uri.parse('https://api.example.com'),
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'submitted': true}), 201);
        }),
      );
      const payload = {
        'feedback_text': 'Helpful app',
        'platform': 'android',
        'app_version': '1.0.0',
      };

      await transport.submit(payload);

      expect(capturedRequest.url.path, '/v1/feedback');
      expect(capturedRequest.method, 'POST');
      expect(jsonDecode(capturedRequest.body), payload);
    });

    test('wraps a rejected submission', () async {
      final transport = CloudflareFeedbackTransport(
        baseUri: Uri.parse('https://api.example.com'),
        client: MockClient(
          (_) async => http.Response(jsonEncode({'error': 'Invalid'}), 400),
        ),
      );

      await expectLater(
        transport.submit(const {
          'feedback_text': 'Helpful app',
          'platform': 'android',
          'app_version': '1.0.0',
        }),
        throwsA(isA<FeedbackSubmissionException>()),
      );
    });
  });
}
