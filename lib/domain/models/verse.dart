class Verse {
  final String verseId;
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String? translation;
  final int page;

  const Verse({
    required this.verseId,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    this.translation,
    this.page = 0,
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
