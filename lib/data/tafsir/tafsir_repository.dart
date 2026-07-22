import '../../domain/models/tafsir.dart';

abstract class TafsirRepository {
  Future<List<TafsirSource>> getSources();

  Future<TafsirPassage> getTafsir({
    required String verseKey,
    required TafsirSource source,
  });
}
