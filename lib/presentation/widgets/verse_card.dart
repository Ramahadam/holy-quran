import 'package:flutter/material.dart';
import '../../domain/models/verse.dart';

class VerseCard extends StatelessWidget {
  final Verse verse;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;

  const VerseCard({
    super.key,
    required this.verse,
    this.isBookmarked = false,
    this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onBookmarkToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isBookmarked)
                  Icon(
                    Icons.bookmark,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  )
                else
                  const SizedBox(width: 18),
                _VerseNumber(number: verse.verseNumber),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              verse.arabicText,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                height: 2.0,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            if (verse.translation != null) ...[
              const SizedBox(height: 12),
              Text(
                verse.translation!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Divider(color: Theme.of(context).dividerColor, thickness: 1),
          ],
        ),
      ),
    );
  }
}

class _VerseNumber extends StatelessWidget {
  final int number;

  const _VerseNumber({required this.number});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Text(
          '$number',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
