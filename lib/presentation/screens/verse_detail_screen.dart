import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/verse.dart';
import '../../l10n/l10n.dart';
import '../providers/quran_providers.dart';
import '../providers/tafsir_providers.dart';
import '../tafsir/tafsir_source_selection.dart';

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.ayahStudy),
            Text(
              '${verse.surahNumber}:${verse.verseNumber}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isBookmarked
                ? context.l10n.removeBookmark
                : context.l10n.bookmarkVerse,
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
                  const SizedBox(height: 32),
                  Divider(color: Theme.of(context).dividerColor),
                  const SizedBox(height: 24),
                  _TafsirSection(verseKey: verse.verseId),
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
          content: Text(
            isBookmarked
                ? context.l10n.bookmarkRemoved
                : context.l10n.bookmarked,
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TafsirSection extends ConsumerStatefulWidget {
  final String verseKey;

  const _TafsirSection({required this.verseKey});

  @override
  ConsumerState<_TafsirSection> createState() => _TafsirSectionState();
}

class _TafsirSectionState extends ConsumerState<_TafsirSection> {
  int? _selectedSourceId;

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(tafsirSourcesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.tafsir,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.tafsirProvider,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        sources.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                key: ValueKey('tafsirSourcesLoading'),
              ),
            ),
          ),
          error: (_, _) => _TafsirError(
            onRetry: () => ref.invalidate(tafsirSourcesProvider),
          ),
          data: (availableSources) {
            if (availableSources.isEmpty) {
              return Text(context.l10n.noTafsirSources);
            }
            final appLanguageCode = Localizations.localeOf(
              context,
            ).languageCode;
            final localizedSources = tafsirSourcesForLanguage(
              availableSources,
              appLanguageCode,
            );
            final selectedSource = selectTafsirSource(
              localizedSources,
              appLanguageCode,
              selectedSourceId: _selectedSourceId,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey('tafsirSourcePicker-${selectedSource.id}'),
                  initialValue: selectedSource.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.tafsirSource,
                    border: const OutlineInputBorder(),
                  ),
                  items: localizedSources
                      .map(
                        (source) => DropdownMenuItem(
                          value: source.id,
                          child: Text(
                            '${tafsirSourceNameForLanguage(source, appLanguageCode)} '
                            '· ${_localizedLanguageName(context, source.languageName)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (sourceId) {
                    if (sourceId == null || sourceId == _selectedSourceId) {
                      return;
                    }
                    setState(() => _selectedSourceId = sourceId);
                  },
                ),
                const SizedBox(height: 20),
                _TafsirPassageView(
                  request: TafsirRequest(
                    verseKey: widget.verseKey,
                    source: selectedSource,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TafsirPassageView extends ConsumerWidget {
  final TafsirRequest request;

  const _TafsirPassageView({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passage = ref.watch(tafsirPassageProvider(request));
    return passage.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            key: ValueKey('tafsirPassageLoading'),
          ),
        ),
      ),
      error: (_, _) => _TafsirError(
        onRetry: () => ref.invalidate(tafsirPassageProvider(request)),
      ),
      data: (value) => Column(
        crossAxisAlignment: value.source.isArabic
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            value.text,
            textDirection: value.source.isArabic
                ? TextDirection.rtl
                : TextDirection.ltr,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 20),
          Text(
            _attribution(
              context,
              tafsirSourceNameForLanguage(
                value.source,
                Localizations.localeOf(context).languageCode,
              ),
              tafsirAuthorNameForLanguage(
                value.source,
                Localizations.localeOf(context).languageCode,
              ),
            ),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TafsirError extends StatelessWidget {
  final VoidCallback onRetry;

  const _TafsirError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(context.l10n.tafsirUnavailable)),
            TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

String _localizedLanguageName(BuildContext context, String value) {
  return switch (value.toLowerCase()) {
    'arabic' => context.l10n.languageArabic,
    'english' => context.l10n.languageEnglish,
    'bengali' => context.l10n.languageBengali,
    'russian' => context.l10n.languageRussian,
    'swahili' => context.l10n.languageSwahili,
    'urdu' => context.l10n.languageUrdu,
    'kurdish' => context.l10n.languageKurdish,
    _ => value,
  };
}

String _attribution(BuildContext context, String name, String authorName) {
  return authorName.isEmpty
      ? context.l10n.sourceName(name)
      : context.l10n.sourceNameAuthor(name, authorName);
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
