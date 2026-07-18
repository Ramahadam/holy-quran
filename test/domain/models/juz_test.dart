import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/juz.dart';

void main() {
  group('canonicalJuzs', () {
    test('contains all 30 Juz in order', () {
      expect(canonicalJuzs, hasLength(30));
      expect(
        canonicalJuzs.map((juz) => juz.number),
        orderedEquals(List<int>.generate(30, (index) => index + 1)),
      );
    });

    test('uses the canonical start verse for each Juz', () {
      expect(
        canonicalJuzs.map((juz) => juz.startVerseId),
        orderedEquals(const [
          '1:1',
          '2:142',
          '2:253',
          '3:93',
          '4:24',
          '4:148',
          '5:82',
          '6:111',
          '7:88',
          '8:41',
          '9:93',
          '11:6',
          '12:53',
          '15:1',
          '17:1',
          '18:75',
          '21:1',
          '23:1',
          '25:21',
          '27:56',
          '29:46',
          '33:31',
          '36:28',
          '39:32',
          '41:47',
          '46:1',
          '51:31',
          '58:1',
          '67:1',
          '78:1',
        ]),
      );
    });

    test('keeps the Juz 11 regression boundary at At-Tawbah 9:93', () {
      expect(canonicalJuzs[10].startVerseId, '9:93');
    });
  });
}
