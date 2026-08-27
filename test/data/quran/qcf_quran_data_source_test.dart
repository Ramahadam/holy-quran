import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/quran/qcf_quran_data_source.dart';

void main() {
  const dataSource = PackageQcfQuranDataSource();

  group('PackageQcfQuranDataSource', () {
    test('returns typed page ranges for early, middle, and late pages', () {
      expect(dataSource.pageRanges(3), const [QcfPageRange(2, 6, 16)]);
      expect(dataSource.pageRanges(446), const [QcfPageRange(37, 1, 24)]);
      expect(dataSource.pageRanges(604), const [
        QcfPageRange(112, 1, 4),
        QcfPageRange(113, 1, 5),
        QcfPageRange(114, 1, 6),
      ]);
    });

    test('preserves representative canonical Quran text', () {
      expect(
        dataSource.verseText(1, 1),
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
      );
      expect(dataSource.verseText(36, 1), 'يسٓ');
      expect(dataSource.verseText(114, 6), 'مِنَ ٱلۡجِنَّةِ وَٱلنَّاسِ');
    });

    test('preserves representative QCF verse and marker glyphs', () {
      expect(dataSource.verseGlyphs(1, 1), 'ﱁﱂﱃﱄ');
      expect(dataSource.verseNumberGlyph(1, 1), 'ﱅ');
      expect(dataSource.verseGlyphs(36, 1), 'ﱜ');
      expect(dataSource.verseNumberGlyph(36, 1), 'ﱝ');
      expect(dataSource.verseGlyphs(114, 6), '\nﲆﲇﲈ');
      expect(dataSource.verseNumberGlyph(114, 6), 'ﲉ');
    });

    test('preserves Surah-opening and line-break metadata', () {
      expect(dataSource.surahNameArabic(112), 'الإخلاص');
      expect(dataSource.verseCount(112), 4);
      expect(dataSource.juzNumber(112, 1), 30);
      expect(dataSource.verseEndsWithLineBreak(2, 45), isTrue);
      expect(dataSource.verseEndsWithLineBreak(2, 46), isFalse);
    });

    test('normalizes vocalized Allah text through the public package API', () {
      expect(dataSource.normalizedText('ٱللَّهِ'), 'ٱلله');
    });
  });
}
