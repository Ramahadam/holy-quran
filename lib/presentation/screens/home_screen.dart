import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/surah_tile.dart';
import 'reading_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahListProvider);

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
        data: (surahs) => ListView.separated(
          itemCount: surahs.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: Color(0xFFE8DCC8)),
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.islamicGreen),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load surahs.\n$e',
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
