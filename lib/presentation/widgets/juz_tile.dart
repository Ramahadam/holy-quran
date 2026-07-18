import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

import '../../domain/models/juz.dart';
import '../../domain/models/surah.dart';

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

    return Semantics(
      button: true,
      label: 'Juz ${juz.number}, starts at $startLabel, page $page',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _JuzNumber(number: juz.number),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Juz ${juz.number}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Starts at $startLabel · Page $page',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الجزء ${convertToArabicNumber(juz.number.toString())}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 20,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JuzNumber extends StatelessWidget {
  final int number;

  const _JuzNumber({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
