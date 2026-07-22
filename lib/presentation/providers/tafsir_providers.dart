import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/backend/cloudflare_config.dart';
import '../../data/tafsir/quran_foundation_tafsir_repository.dart';
import '../../data/tafsir/tafsir_repository.dart';
import '../../data/tafsir/tafsir_transport.dart';
import '../../domain/models/tafsir.dart';

final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) {
  final baseUri = configuredCloudflareApiBaseUri;
  if (baseUri == null) {
    return const QuranFoundationTafsirRepository(
      transport: UnconfiguredTafsirTransport(),
    );
  }
  final client = http.Client();
  ref.onDispose(client.close);
  final transport = CloudflareTafsirTransport(baseUri: baseUri, client: client);
  return QuranFoundationTafsirRepository(transport: transport);
});

final tafsirSourcesProvider = FutureProvider.autoDispose<List<TafsirSource>>((
  ref,
) {
  return ref.watch(tafsirRepositoryProvider).getSources();
});

class TafsirRequest {
  final String verseKey;
  final TafsirSource source;

  const TafsirRequest({required this.verseKey, required this.source});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TafsirRequest &&
          verseKey == other.verseKey &&
          source == other.source;

  @override
  int get hashCode => Object.hash(verseKey, source);
}

final tafsirPassageProvider = FutureProvider.autoDispose
    .family<TafsirPassage, TafsirRequest>((ref, request) {
      return ref
          .watch(tafsirRepositoryProvider)
          .getTafsir(verseKey: request.verseKey, source: request.source);
    });
