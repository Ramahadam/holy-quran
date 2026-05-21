class Verse {
  final String verseId;
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String? translation;

  const Verse({
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
