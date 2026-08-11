import 'package:flutter/material.dart';

import '../../domain/models/juz.dart';
import '../../domain/models/surah.dart';
import '../../l10n/l10n.dart';
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
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final startSurahName = isArabic
        ? startSurah.nameArabic
        : startSurah.nameEnglish;
    final startLabel =
        '$startSurahName '
        '${juz.startSurahNumber}:${juz.startVerseNumber}';
    return QuranIndexTile(
      keyPrefix: 'juz',
      number: juz.number,
      title: l10n.juzNumber(juz.number),
      subtitle: l10n.juzStartsAt(startLabel, page),
      semanticsLabel: l10n.juzSemantics(juz.number, startLabel, page),
      onTap: onTap,
    );
  }
}
