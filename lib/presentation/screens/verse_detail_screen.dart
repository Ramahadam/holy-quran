import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/verse.dart';
import '../../l10n/l10n.dart';
import '../providers/quran_providers.dart';
import '../providers/tafsir_providers.dart';
import '../tafsir/tafsir_source_selection.dart';

const _kfgqpcHafsFontFamily = 'KFGQPCHafsUthmanicScript';
final _embeddedAyahMarkerPattern = RegExp(
  r'\s*(?:[\u06DD\u06DE\u06E9]\s*[٠-٩0-9]*|[﴾﴿])\s*',
);
final _ayahWhitespacePattern = RegExp(r'\s+');

class VerseDetailScreen extends ConsumerStatefulWidget {
  final Verse verse;

  const VerseDetailScreen({super.key, required this.verse});

  @override
  ConsumerState<VerseDetailScreen> createState() => _VerseDetailScreenState();
}

class _VerseDetailScreenState extends ConsumerState<VerseDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  late Verse _verse;
  bool _isChangingVerse = false;

  bool get _canGoPrevious => _verse.surahNumber > 1 || _verse.verseNumber > 1;

  bool get _canGoNext => _verse.surahNumber < 114 || _verse.verseNumber < 6;

  @override
  void initState() {
    super.initState();
    _verse = widget.verse;
  }

  @override
  void didUpdateWidget(covariant VerseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verse != widget.verse) {
      _verse = widget.verse;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(bookmarksBySurahProvider(_verse.surahNumber));
    final isBookmarked =
        bookmarks.valueOrNull?.contains(_verse.verseId) ?? false;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final ayahText = isArabic
        ? _cleanArabicAyahText(_verse.arabicText)
        : _verse.translation ?? _verse.arabicText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(context.l10n.ayahStudy),
            Text(
              '${_verse.surahNumber}:${_verse.verseNumber}',
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
            onPressed: () => _toggleBookmark(context, isBookmarked),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    key: const ValueKey('verseDetailAyahCard'),
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Directionality(
                        textDirection: isArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: _VerseBadge(number: _verse.verseNumber),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ayahText,
                              style: isArabic
                                  ? Theme.of(
                                      context,
                                    ).textTheme.headlineMedium?.copyWith(
                                      fontFamily: _kfgqpcHafsFontFamily,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                      height: 1.9,
                                    )
                                  : Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                      height: 1.7,
                                    ),
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TafsirSection(verseKey: _verse.verseId),
                  const SizedBox(height: 16),
                  _AyahNavigation(
                    onPrevious: _canGoPrevious && !_isChangingVerse
                        ? _goToPreviousAyah
                        : null,
                    onNext: _canGoNext && !_isChangingVerse
                        ? _goToNextAyah
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBookmark(BuildContext context, bool isBookmarked) async {
    final verse = _verse;
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

  Future<void> _goToPreviousAyah() async {
    if (!_canGoPrevious || _isChangingVerse) return;
    final currentVerse = _verse;
    await _loadAdjacentAyah(() async {
      final repository = ref.read(quranRepositoryProvider);
      if (currentVerse.verseNumber > 1) {
        return repository.getVerseById(
          '${currentVerse.surahNumber}:${currentVerse.verseNumber - 1}',
        );
      }
      final previousSurah = await repository.getVersesBySurah(
        currentVerse.surahNumber - 1,
      );
      return previousSurah.isEmpty ? null : previousSurah.last;
    });
  }

  Future<void> _goToNextAyah() async {
    if (!_canGoNext || _isChangingVerse) return;
    final currentVerse = _verse;
    await _loadAdjacentAyah(() async {
      final repository = ref.read(quranRepositoryProvider);
      final nextInSurah = await repository.getVerseById(
        '${currentVerse.surahNumber}:${currentVerse.verseNumber + 1}',
      );
      if (nextInSurah != null) return nextInSurah;
      return repository.getVerseById('${currentVerse.surahNumber + 1}:1');
    });
  }

  Future<void> _loadAdjacentAyah(Future<Verse?> Function() load) async {
    setState(() => _isChangingVerse = true);
    try {
      final adjacentVerse = await load();
      if (!mounted) return;
      if (adjacentVerse == null) {
        _showNavigationError();
        return;
      }
      setState(() => _verse = adjacentVerse);
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (mounted) _showNavigationError();
    } finally {
      if (mounted) setState(() => _isChangingVerse = false);
    }
  }

  void _showNavigationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.ayahNavigationUnavailable),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AyahNavigation extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _AyahNavigation({required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('previousAyahButton'),
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(context.l10n.previousAyah),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('nextAyahButton'),
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(context.l10n.nextAyah),
          ),
        ),
      ],
    );
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('tafsirCard'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 22,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tafsir,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.tafsirProvider,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                if (localizedSources.isEmpty) {
                  return Text(context.l10n.noTafsirSources);
                }
                final selectedSource = selectTafsirSource(
                  localizedSources,
                  appLanguageCode,
                  selectedSourceId: _selectedSourceId,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.tafsirSource,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      key: ValueKey('tafsirSourcePicker-${selectedSource.id}'),
                      initialValue: selectedSource.id,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: colorScheme.surfaceContainer,
                      menuMaxHeight: 320,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          14,
                          12,
                          14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      selectedItemBuilder: (context) => localizedSources
                          .map(
                            (source) => Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                tafsirSourceNameForLanguage(
                                  source,
                                  appLanguageCode,
                                ),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      items: localizedSources
                          .map(
                            (source) => DropdownMenuItem(
                              value: source.id,
                              alignment: AlignmentDirectional.centerStart,
                              child: Row(
                                key: ValueKey(
                                  'tafsirSourceOption-${source.id}',
                                ),
                                children: [
                                  Expanded(
                                    child: Text(
                                      tafsirSourceNameForLanguage(
                                        source,
                                        appLanguageCode,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (source.id == selectedSource.id) ...[
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ],
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
                    const SizedBox(height: 24),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    const SizedBox(height: 24),
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
        ),
      ),
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
      data: (value) {
        final textDirection = value.source.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr;
        final colorScheme = Theme.of(context).colorScheme;
        return Directionality(
          textDirection: textDirection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                value.text,
                key: const ValueKey('tafsirPassageText'),
                textAlign: TextAlign.start,
                textDirection: textDirection,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.8),
              ),
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
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
                          key: const ValueKey('tafsirAttributionText'),
                          textAlign: TextAlign.start,
                          textDirection: textDirection,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

String _attribution(BuildContext context, String name, String authorName) {
  return authorName.isEmpty
      ? context.l10n.sourceName(name)
      : context.l10n.sourceNameAuthor(name, authorName);
}

String _cleanArabicAyahText(String text) => text
    .replaceAll(_embeddedAyahMarkerPattern, ' ')
    .replaceAll(_ayahWhitespacePattern, ' ')
    .trim();

class _VerseBadge extends StatelessWidget {
  final int number;

  const _VerseBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          context.l10n.verseNumber('$number'),
          key: const ValueKey('ayahNumberMarker'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
