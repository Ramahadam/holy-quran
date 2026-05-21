import 'package:isar/isar.dart';

part 'bookmark.g.dart';

@collection
class Bookmark {
  Id id = Isar.autoIncrement;

  @Index()
  final String verseId;

  final DateTime timestamp;
  final String? note;

  Bookmark({
    this.id = Isar.autoIncrement,
    required this.verseId,
    required this.timestamp,
    this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bookmark &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
