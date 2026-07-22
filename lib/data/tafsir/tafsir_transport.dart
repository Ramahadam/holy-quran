import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class TafsirTransport {
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> body);
}

class CloudflareTafsirTransport implements TafsirTransport {
  final http.Client client;
  final Uri endpoint;

  CloudflareTafsirTransport({required Uri baseUri, required this.client})
    : endpoint = baseUri.resolve('/v1/tafsir');

  @override
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> body) async {
    try {
      final response = await client
          .post(
            endpoint,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map && data['error'] is String
            ? data['error'] as String
            : 'Tafsir could not be loaded.';
        throw TafsirException(message);
      }
      if (data is! Map) {
        throw const TafsirException(
          'The tafsir service returned invalid data.',
        );
      }
      return Map<String, dynamic>.from(data);
    } on TafsirException {
      rethrow;
    } catch (error) {
      throw TafsirException('Tafsir could not be loaded.', error);
    }
  }
}

class UnconfiguredTafsirTransport implements TafsirTransport {
  const UnconfiguredTafsirTransport();

  @override
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> body) {
    throw const TafsirException('Tafsir is not configured on this build.');
  }
}

class TafsirException implements Exception {
  final String message;
  final Object? cause;

  const TafsirException(this.message, [this.cause]);

  @override
  String toString() => 'TafsirException: $message';
}
