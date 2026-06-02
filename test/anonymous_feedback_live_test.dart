import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/feedback/anonymous_feedback_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _projectUrl = String.fromEnvironment('PROJECT_URL');
const String _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);
const String _publishableKey = String.fromEnvironment('PUBLISHABLE_KEY');

String get _configuredUrl => _supabaseUrl.isNotEmpty
    ? _supabaseUrl
    : _projectUrl;

String get _configuredKey => _supabasePublishableKey.isNotEmpty
    ? _supabasePublishableKey
    : _publishableKey;

void main() {
  final hasSupabaseConfig =
      _configuredUrl.isNotEmpty && _configuredKey.isNotEmpty;

  test(
    'submits anonymous feedback through the live Supabase SDK',
    () async {
      final service = AnonymousFeedbackService(
        transport: SupabaseFeedbackTransport(
          client: SupabaseClient(_configuredUrl, _configuredKey),
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
    skip: hasSupabaseConfig
        ? false
        : 'Provide SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY to run live.',
  );
}
