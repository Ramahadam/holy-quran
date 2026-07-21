import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/feedback/anonymous_feedback_service.dart';
import 'package:http/http.dart' as http;

const String _cloudflareApiBaseUrl = String.fromEnvironment(
  'CLOUDFLARE_API_BASE_URL',
  defaultValue: 'https://holy-quran-api.mohamedadam-tech.workers.dev',
);
const bool _runLiveTests = bool.fromEnvironment('RUN_CLOUDFLARE_LIVE_TESTS');

void main() {
  test(
    'submits anonymous feedback through the live Cloudflare Worker',
    () async {
      final client = http.Client();
      addTearDown(client.close);
      final service = AnonymousFeedbackService(
        transport: CloudflareFeedbackTransport(
          baseUri: Uri.parse(_cloudflareApiBaseUrl),
          client: client,
        ),
      );

      await service.submitFeedback(
        'Codex live SDK connectivity test',
        metadata: const FeedbackMetadata(
          platform: 'flutter_test',
          appVersion: 'live',
        ),
      );
    },
    skip: _runLiveTests
        ? false
        : 'Set RUN_CLOUDFLARE_LIVE_TESTS=true to run live.',
  );
}
