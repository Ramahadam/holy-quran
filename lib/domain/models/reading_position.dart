class ReadingPosition {
  final String verseId;
  final DateTime lastReadAt;

  const ReadingPosition({
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
