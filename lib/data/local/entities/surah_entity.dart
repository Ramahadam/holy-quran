import 'package:isar/isar.dart';
import 'package:holy_quran_app/domain/models/surah.dart';

part 'surah_entity.g.dart';

/// Isar database entity for Surah model.
/// Uses surahNumber as primary key (1-114).
@Name('SurahEntity_web_360')
@collection
class SurahEntity {
  Id get id => surahNumber;

  late int surahNumber;
  late String nameArabic;
  late String nameEnglish;
  late int numberOfVerses;

  SurahEntity();

  /// Create entity from domain model
  SurahEntity.fromDomain(Surah surah) {
    surahNumber = surah.surahNumber;
    nameArabic = surah.nameArabic;
    nameEnglish = surah.nameEnglish;
    numberOfVerses = surah.numberOfVerses;
  }

  /// Convert entity to domain model
  Surah toDomain() {
    return Surah(
      surahNumber: surahNumber,
      nameArabic: nameArabic,
      nameEnglish: nameEnglish,
      numberOfVerses: numberOfVerses,
    );
  }
}
