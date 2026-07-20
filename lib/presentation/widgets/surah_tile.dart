import 'package:flutter/material.dart';

import '../../domain/models/surah.dart';
import 'quran_index_tile.dart';

class SurahTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const SurahTile({super.key, required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return QuranIndexTile(
      keyPrefix: 'surah',
      number: surah.surahNumber,
      title: surah.nameEnglish,
      subtitle: '${surah.numberOfVerses} verses',
      arabicTitle: surah.nameArabic,
      semanticsLabel:
          'Surah ${surah.surahNumber}, ${surah.nameEnglish}, '
          '${surah.nameArabic}, '
          '${surah.numberOfVerses} verses',
      onTap: onTap,
    );
  }
}
