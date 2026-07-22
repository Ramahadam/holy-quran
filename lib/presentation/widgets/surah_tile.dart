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
    return QuranIndexTile(
      keyPrefix: 'surah',
      number: surah.surahNumber,
      title: surah.nameArabic,
      subtitle: l10n.verseCount(surah.numberOfVerses),
      semanticsLabel: l10n.surahSemantics(
        surah.surahNumber,
        surah.nameArabic,
        surah.numberOfVerses,
      ),
      onTap: onTap,
    );
  }
}
