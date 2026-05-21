class Surah {
  final int surahNumber;
  final String nameArabic;
  final String nameEnglish;
  final int numberOfVerses;

  const Surah({
    required this.surahNumber,
    required this.nameArabic,
    required this.nameEnglish,
    required this.numberOfVerses,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Surah &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber;

  @override
  int get hashCode => surahNumber.hashCode;
}
