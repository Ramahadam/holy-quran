class Bookmark {
  final String verseId;
  final DateTime timestamp;
  final String? note;

  const Bookmark({
    required this.verseId,
    required this.timestamp,
    this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bookmark &&
          runtimeType == other.runtimeType &&
          verseId == other.verseId &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(verseId, timestamp);
}
