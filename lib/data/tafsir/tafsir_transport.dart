import 'package:supabase_flutter/supabase_flutter.dart';

abstract class TafsirTransport {
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> body);
}

class SupabaseTafsirTransport implements TafsirTransport {
  final SupabaseClient client;

  const SupabaseTafsirTransport({required this.client});

  @override
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> body) async {
    try {
      final response = await client.functions.invoke(
        'quran-tafsir',
        body: body,
      );
      final data = response.data;
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
