import 'package:isar/isar.dart';

part 'reading_position.g.dart';

@collection
class ReadingPosition {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String verseId;

  final DateTime lastReadAt;

  ReadingPosition({
    this.id = Isar.autoIncrement,
    required this.verseId,
    required this.lastReadAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingPosition &&
          runtimeType == other.runtimeType &&
          verseId == other.verseId;

  @override
  int get hashCode => verseId.hashCode;
}
