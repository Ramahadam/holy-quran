import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/surah.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/verse_card.dart';

class ReadingScreen extends ConsumerWidget {
  final Surah surah;

  const ReadingScreen({super.key, required this.surah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(versesBySurahProvider(surah.surahNumber));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              surah.nameArabic,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.islamicGreen,
                  ),
              textDirection: TextDirection.rtl,
            ),
            Text(
              surah.nameEnglish,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: versesAsync.when(
        data: (verses) => ListView.builder(
          itemCount: verses.length,
          itemBuilder: (context, index) => VerseCard(verse: verses[index]),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.islamicGreen),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load verses.\nPlease restart the app.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
