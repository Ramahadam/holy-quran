import 'package:flutter/material.dart';
import '../../domain/models/verse.dart';
import '../theme/app_theme.dart';

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
                  const Icon(
                    Icons.bookmark,
                    color: AppTheme.islamicGreen,
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
                color: AppTheme.textPrimary,
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
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(color: AppTheme.divider, thickness: 1),
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
          color: AppTheme.islamicGreenSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.islamicGreenBorder),
        ),
        child: Text(
          '$number',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.islamicGreen,
          ),
        ),
      ),
    );
  }
}
