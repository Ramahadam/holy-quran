import 'package:isar/isar.dart';

part 'verse.g.dart';

@collection
class Verse {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String verseId;

  @Index()
  final int surahNumber;

  final int verseNumber;
  final String arabicText;
  final String? translation;

  Verse({
    this.id = Isar.autoIncrement,
    required this.verseId,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    this.translation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Verse &&
          runtimeType == other.runtimeType &&
          verseId == other.verseId;

  @override
  int get hashCode => verseId.hashCode;
}
