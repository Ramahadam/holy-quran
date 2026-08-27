import 'package:qcf_quran/qcf_quran.dart';

const QcfQuranDataSource qcfQuranDataSource = PackageQcfQuranDataSource();

abstract interface class QcfQuranDataSource {
  List<QcfPageRange> pageRanges(int pageNumber);

  String verseText(int surahNumber, int verseNumber);

  String verseGlyphs(int surahNumber, int verseNumber);

  String verseNumberGlyph(int surahNumber, int verseNumber);

  bool verseEndsWithLineBreak(int surahNumber, int verseNumber);

  String surahNameArabic(int surahNumber);

  int verseCount(int surahNumber);

  int juzNumber(int surahNumber, int verseNumber);

  String arabicNumber(String value);

  String normalizedText(String value);
}

final class PackageQcfQuranDataSource implements QcfQuranDataSource {
  const PackageQcfQuranDataSource();

  @override
  List<QcfPageRange> pageRanges(int pageNumber) {
    final ranges = getPageData(pageNumber);
    return List.unmodifiable(
      ranges.map((range) {
        if (range is! Map) {
          throw const FormatException('Invalid QCF page range.');
        }
        final surahNumber = _positiveInt(range['surah']);
        final firstVerse = _positiveInt(range['start']);
        final lastVerse = _positiveInt(range['end']);
        if (firstVerse > lastVerse) {
          throw const FormatException('Invalid QCF page range.');
        }
        return QcfPageRange(surahNumber, firstVerse, lastVerse);
      }),
    );
  }

  @override
  String verseText(int surahNumber, int verseNumber) =>
      getVerse(surahNumber, verseNumber);

  @override
  String verseGlyphs(int surahNumber, int verseNumber) =>
      getVerseQCF(surahNumber, verseNumber, verseEndSymbol: false);

  @override
  String verseNumberGlyph(int surahNumber, int verseNumber) =>
      getVerseNumberQCF(surahNumber, verseNumber);

  @override
  bool verseEndsWithLineBreak(int surahNumber, int verseNumber) =>
      getVerseQCF(surahNumber, verseNumber).endsWith('\n');

  @override
  String surahNameArabic(int surahNumber) => getSurahNameArabic(surahNumber);

  @override
  int verseCount(int surahNumber) => getVerseCount(surahNumber);

  @override
  int juzNumber(int surahNumber, int verseNumber) =>
      getJuzNumber(surahNumber, verseNumber);

  @override
  String arabicNumber(String value) => convertToArabicNumber(value);

  @override
  String normalizedText(String value) => normalise(value);

  static int _positiveInt(Object? value) {
    final number = value is int ? value : int.tryParse(value.toString());
    if (number == null || number < 1) {
      throw const FormatException('Invalid QCF page range.');
    }
    return number;
  }
}

final class QcfPageRange {
  final int surahNumber;
  final int firstVerse;
  final int lastVerse;

  const QcfPageRange(this.surahNumber, this.firstVerse, this.lastVerse);

  @override
  bool operator ==(Object other) =>
      other is QcfPageRange &&
      other.surahNumber == surahNumber &&
      other.firstVerse == firstVerse &&
      other.lastVerse == lastVerse;

  @override
  int get hashCode => Object.hash(surahNumber, firstVerse, lastVerse);
}
