class Bookmark {
  final int id;
  final String verseId;
  final DateTime timestamp;
  final String? note;

  const Bookmark({
    required this.id,
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
