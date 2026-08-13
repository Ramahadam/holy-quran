import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/verse.dart';
import '../../l10n/l10n.dart';
import '../providers/quran_providers.dart';
import '../widgets/verse_detail_tafsir_section.dart';

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
                  VerseDetailTafsirSection(verseKey: _verse.verseId),
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
