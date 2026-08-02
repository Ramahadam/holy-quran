import 'package:isar/isar.dart';

part 'quran_data_metadata_entity.g.dart';

/// Records which verified Quran asset bundle is installed in Isar.
@collection
class QuranDataMetadataEntity {
  static const int singletonId = 1;

  Id id = singletonId;
  late String contentDigest;
  late int surahCount;
  late int verseCount;

  QuranDataMetadataEntity();

  QuranDataMetadataEntity.installed({
    required this.contentDigest,
    required this.surahCount,
    required this.verseCount,
  });
}
