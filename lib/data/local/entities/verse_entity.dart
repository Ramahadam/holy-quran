import 'package:isar/isar.dart';
import 'package:holy_quran_app/domain/models/verse.dart';

part 'verse_entity.g.dart';

/// Isar database entity for Verse model.
/// Maps between domain model and database representation.
@collection
class VerseEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String verseId;

  @Index()
  late int surahNumber;

  late int verseNumber;
  late String arabicText;
  String? translation;

  VerseEntity();

  /// Create entity from domain model
  VerseEntity.fromDomain(Verse verse) {
    verseId = verse.verseId;
    surahNumber = verse.surahNumber;
    verseNumber = verse.verseNumber;
    arabicText = verse.arabicText;
    translation = verse.translation;
  }

  /// Convert entity to domain model
  Verse toDomain() {
    return Verse(
      verseId: verseId,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      arabicText: arabicText,
      translation: translation,
    );
  }
}
