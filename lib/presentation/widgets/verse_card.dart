import 'package:flutter/material.dart';
import '../../domain/models/verse.dart';
import '../theme/app_theme.dart';

class VerseCard extends StatelessWidget {
  final Verse verse;

  const VerseCard({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VerseNumber(number: verse.verseNumber),
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
          color: AppTheme.islamicGreen.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.islamicGreen.withAlpha(60),
          ),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.islamicGreen,
          ),
        ),
      ),
    );
  }
}
