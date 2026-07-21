import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/tafsir/tafsir_transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CloudflareTafsirTransport', () {
    test('posts the operation to the Worker', () async {
      late http.Request capturedRequest;
      final transport = CloudflareTafsirTransport(
        baseUri: Uri.parse('https://api.example.com'),
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'sources': [
                {
                  'id': 169,
                  'name': 'Tafsir Ibn Kathir',
                  'authorName': 'Hafiz Ibn Kathir',
                  'languageName': 'english',
                  'slug': 'en-tafsir-ibn-kathir',
                },
              ],
            }),
            200,
          );
        }),
      );

      final response = await transport.invoke(const {'operation': 'sources'});

      expect(capturedRequest.url.path, '/v1/tafsir');
      expect(capturedRequest.method, 'POST');
      expect(jsonDecode(capturedRequest.body), {'operation': 'sources'});
      expect(response['sources'], hasLength(1));
    });

    test('surfaces a safe Worker error', () async {
      final transport = CloudflareTafsirTransport(
        baseUri: Uri.parse('https://api.example.com'),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'error': 'The tafsir provider is unavailable.'}),
            502,
          ),
        ),
      );

      await expectLater(
        transport.invoke(const {'operation': 'sources'}),
        throwsA(
          isA<TafsirException>().having(
            (error) => error.message,
            'message',
            'The tafsir provider is unavailable.',
          ),
        ),
      );
    });
  });
}
