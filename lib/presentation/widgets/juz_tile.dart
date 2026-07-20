import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

import '../../domain/models/juz.dart';
import '../../domain/models/surah.dart';
import 'quran_index_tile.dart';

class JuzTile extends StatelessWidget {
  final Juz juz;
  final Surah startSurah;
  final int page;
  final VoidCallback onTap;

  const JuzTile({
    super.key,
    required this.juz,
    required this.startSurah,
    required this.page,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startLabel =
        '${startSurah.nameEnglish} '
        '${juz.startSurahNumber}:${juz.startVerseNumber}';
    final arabicTitle = 'الجزء ${convertToArabicNumber(juz.number.toString())}';
    return QuranIndexTile(
      keyPrefix: 'juz',
      number: juz.number,
      title: 'Juz ${juz.number}',
      subtitle: 'Starts at $startLabel · Page $page',
      arabicTitle: arabicTitle,
      semanticsLabel:
          'Juz ${juz.number}, $arabicTitle, starts at $startLabel, page $page',
      onTap: onTap,
    );
  }
}
