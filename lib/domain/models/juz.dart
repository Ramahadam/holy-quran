class Juz {
  final int number;
  final int startSurahNumber;
  final int startVerseNumber;

  const Juz({
    required this.number,
    required this.startSurahNumber,
    required this.startVerseNumber,
  });

  String get startVerseId => '$startSurahNumber:$startVerseNumber';
}

const canonicalJuzs = <Juz>[
  Juz(number: 1, startSurahNumber: 1, startVerseNumber: 1),
  Juz(number: 2, startSurahNumber: 2, startVerseNumber: 142),
  Juz(number: 3, startSurahNumber: 2, startVerseNumber: 253),
  Juz(number: 4, startSurahNumber: 3, startVerseNumber: 93),
  Juz(number: 5, startSurahNumber: 4, startVerseNumber: 24),
  Juz(number: 6, startSurahNumber: 4, startVerseNumber: 148),
  Juz(number: 7, startSurahNumber: 5, startVerseNumber: 82),
  Juz(number: 8, startSurahNumber: 6, startVerseNumber: 111),
  Juz(number: 9, startSurahNumber: 7, startVerseNumber: 88),
  Juz(number: 10, startSurahNumber: 8, startVerseNumber: 41),
  Juz(number: 11, startSurahNumber: 9, startVerseNumber: 93),
  Juz(number: 12, startSurahNumber: 11, startVerseNumber: 6),
  Juz(number: 13, startSurahNumber: 12, startVerseNumber: 53),
  Juz(number: 14, startSurahNumber: 15, startVerseNumber: 1),
  Juz(number: 15, startSurahNumber: 17, startVerseNumber: 1),
  Juz(number: 16, startSurahNumber: 18, startVerseNumber: 75),
  Juz(number: 17, startSurahNumber: 21, startVerseNumber: 1),
  Juz(number: 18, startSurahNumber: 23, startVerseNumber: 1),
  Juz(number: 19, startSurahNumber: 25, startVerseNumber: 21),
  Juz(number: 20, startSurahNumber: 27, startVerseNumber: 56),
  Juz(number: 21, startSurahNumber: 29, startVerseNumber: 46),
  Juz(number: 22, startSurahNumber: 33, startVerseNumber: 31),
  Juz(number: 23, startSurahNumber: 36, startVerseNumber: 28),
  Juz(number: 24, startSurahNumber: 39, startVerseNumber: 32),
  Juz(number: 25, startSurahNumber: 41, startVerseNumber: 47),
  Juz(number: 26, startSurahNumber: 46, startVerseNumber: 1),
  Juz(number: 27, startSurahNumber: 51, startVerseNumber: 31),
  Juz(number: 28, startSurahNumber: 58, startVerseNumber: 1),
  Juz(number: 29, startSurahNumber: 67, startVerseNumber: 1),
  Juz(number: 30, startSurahNumber: 78, startVerseNumber: 1),
];
