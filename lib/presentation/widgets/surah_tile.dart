import 'package:flutter/material.dart';

import '../../domain/models/surah.dart';
import '../../l10n/l10n.dart';
import 'quran_index_tile.dart';

class SurahTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const SurahTile({super.key, required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final verseCount = l10n.verseCount(surah.numberOfVerses);
    return QuranIndexTile(
      keyPrefix: 'surah',
      number: surah.surahNumber,
      title: surah.nameArabic,
      subtitle: isEnglish ? '${surah.nameEnglish} · $verseCount' : verseCount,
      semanticsLabel: isEnglish
          ? '${l10n.surahNumber(surah.surahNumber.toString())}, '
                '${surah.nameArabic}, '
                '${surah.nameEnglish}, $verseCount'
          : l10n.surahSemantics(
              surah.surahNumber,
              surah.nameArabic,
              surah.numberOfVerses,
            ),
      onTap: onTap,
    );
  }
}
