import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/bookmark.dart';
import '../../domain/models/surah.dart';
import '../../l10n/l10n.dart';
import '../providers/quran_providers.dart';
import 'reading_screen.dart';

typedef _OpenReading =
    Future<void> Function(Surah surah, {String? initialVerseId});

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(allBookmarksProvider);
    final surahsAsync = ref.watch(surahListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bookmarks)),
      body: bookmarksAsync.when(
        data: (bookmarks) {
          if (bookmarks.isEmpty) return _buildEmptyState(context);
          return surahsAsync.when(
            data: (surahs) => _buildContent(context, bookmarks, surahs),
            loading: () => _BookmarksLoadingState(),
            error: (_, _) => _BookmarksErrorState(onRetry: _retry),
          );
        },
        loading: () => _BookmarksLoadingState(),
        error: (_, _) => _BookmarksErrorState(onRetry: _retry),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Bookmark> bookmarks,
    List<Surah> surahs,
  ) {
    final surahsByNumber = {
      for (final surah in surahs) surah.surahNumber: surah,
    };

    return ListView.separated(
      key: const ValueKey('bookmarksList'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: bookmarks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        final surah = _surahForBookmark(bookmark, surahsByNumber);
        return _BookmarkListTile(
          bookmark: bookmark,
          surah: surah,
          onOpenReading: _openReadingScreen,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      key: const ValueKey('bookmarksEmptyState'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(context.l10n.bookmarksEmpty, textAlign: TextAlign.center),
      ),
    );
  }

  Surah? _surahForBookmark(Bookmark bookmark, Map<int, Surah> surahsByNumber) {
    final surahNumber = int.tryParse(bookmark.verseId.split(':').first);
    if (surahNumber == null) return null;
    return surahsByNumber[surahNumber];
  }

  Future<void> _openReadingScreen(Surah surah, {String? initialVerseId}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ReadingScreen(surah: surah, initialVerseId: initialVerseId),
      ),
    );
    if (!mounted) return;
    ref.invalidate(allBookmarksProvider);
  }

  void _retry() {
    ref.invalidate(allBookmarksProvider);
    ref.invalidate(surahListProvider);
  }
}

class _BookmarksLoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey('bookmarksLoadingState'),
      child: CircularProgressIndicator(),
    );
  }
}

class _BookmarksErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _BookmarksErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('bookmarksErrorState'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.bookmarksLoadError, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _BookmarkListTile extends ConsumerWidget {
  final Bookmark bookmark;
  final Surah? surah;
  final _OpenReading onOpenReading;

  const _BookmarkListTile({
    required this.bookmark,
    required this.surah,
    required this.onOpenReading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseNumber = bookmark.verseId.split(':').elementAtOrNull(1) ?? '';
    final surahNumber = bookmark.verseId.split(':').first;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final surahName = surah == null
        ? context.l10n.surahNumber(surahNumber)
        : isArabic
        ? surah!.nameArabic
        : surah!.nameEnglish;
    final title = verseNumber.isEmpty
        ? surahName
        : '$surahName · ${context.l10n.verseNumber(verseNumber)}';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: ValueKey('bookmarkRow-${bookmark.verseId}'),
        onTap: surah == null
            ? null
            : () => unawaited(
                onOpenReading(surah!, initialVerseId: bookmark.verseId),
              ),
        leading: IconButton(
          key: ValueKey('removeBookmark-${bookmark.verseId}'),
          tooltip: context.l10n.removeBookmark,
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            minimumSize: const Size.square(48),
            maximumSize: const Size.square(48),
          ),
          icon: const Icon(Icons.bookmark_rounded, size: 20),
          onPressed: () => _removeBookmark(context, ref),
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Future<void> _removeBookmark(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(bookmarkRepositoryProvider)
          .removeBookmark(bookmark.verseId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.bookmarkRemoveFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    ref.invalidate(allBookmarksProvider);
    ref.invalidate(recentBookmarksProvider);
    final surahNumber = int.tryParse(bookmark.verseId.split(':').first);
    if (surahNumber != null) {
      ref.invalidate(bookmarksBySurahProvider(surahNumber));
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.bookmarkRemoved),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
