import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/surah.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/surah_tile.dart';
import 'reading_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahListProvider);
    final lastPositionAsync = ref.watch(lastReadPositionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'القرآن الكريم',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.islamicGreen,
                  ),
              textDirection: TextDirection.rtl,
            ),
            Text(
              'Holy Quran',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: surahsAsync.when(
        data: (surahs) {
          final lastPosition = lastPositionAsync.valueOrNull;
          Surah? lastSurah;
          if (lastPosition != null) {
            final surahNum =
                int.tryParse(lastPosition.verseId.split(':').first);
            if (surahNum != null) {
              try {
                lastSurah =
                    surahs.firstWhere((s) => s.surahNumber == surahNum);
              } catch (_) {
                lastSurah = null;
              }
            }
          }

          return Column(
            children: [
              if (lastSurah != null)
                _LastReadBanner(surah: lastSurah, verseId: lastPosition!.verseId),
              Expanded(
                child: surahs.isEmpty
                    ? const Center(child: Text('No surahs found.'))
                    : ListView.separated(
                        itemCount: surahs.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppTheme.divider),
                        itemBuilder: (context, index) {
                          final surah = surahs[index];
                          return SurahTile(
                            surah: surah,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReadingScreen(surah: surah),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.islamicGreen),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load surahs.\nPlease restart the app.',
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

class _LastReadBanner extends ConsumerWidget {
  final Surah surah;
  final String verseId;

  const _LastReadBanner({required this.surah, required this.verseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseNum = verseId.split(':').elementAtOrNull(1) ?? '';
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReadingScreen(surah: surah)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.islamicGreenSubtle,
          border: Border(
            bottom: BorderSide(color: AppTheme.islamicGreenBorder),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.bookmark, color: AppTheme.islamicGreen, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue Reading',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.islamicGreen,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${surah.nameEnglish}${verseNum.isNotEmpty ? ' · Verse $verseNum' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.islamicGreen, size: 18),
          ],
        ),
      ),
    );
  }
}
