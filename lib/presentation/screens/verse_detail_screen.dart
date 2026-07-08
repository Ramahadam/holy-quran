import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/verse.dart';
import '../providers/quran_providers.dart';

const _kfgqpcHafsFontFamily = 'KFGQPCHafsUthmanicScript';

class VerseDetailScreen extends ConsumerWidget {
  final Verse verse;

  const VerseDetailScreen({super.key, required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksBySurahProvider(verse.surahNumber));
    final isBookmarked =
        bookmarks.valueOrNull?.contains(verse.verseId) ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${verse.surahNumber}:${verse.verseNumber}'),
        actions: [
          IconButton(
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark verse',
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _toggleBookmark(context, ref, isBookmarked),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _VerseBadge(number: verse.verseNumber),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    verse.arabicText,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontFamily: _kfgqpcHafsFontFamily,
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      height: 2.1,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  if (verse.translation != null) ...[
                    const SizedBox(height: 28),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 20),
                    Text(
                      verse.translation!,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(height: 1.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBookmark(
    BuildContext context,
    WidgetRef ref,
    bool isBookmarked,
  ) async {
    final repo = ref.read(bookmarkRepositoryProvider);
    if (isBookmarked) {
      await repo.removeBookmark(verse.verseId);
    } else {
      await repo.addBookmark(verse.verseId, DateTime.now());
    }

    ref.invalidate(recentBookmarksProvider);
    ref.invalidate(bookmarksBySurahProvider(verse.surahNumber));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBookmarked ? 'Bookmark removed' : 'Bookmarked'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _VerseBadge extends StatelessWidget {
  final int number;

  const _VerseBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          '$number',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
