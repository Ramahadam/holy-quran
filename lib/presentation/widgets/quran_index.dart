import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/surah.dart';
import '../../l10n/l10n.dart';
import '../providers/quran_providers.dart';
import 'juz_tile.dart';
import 'surah_tile.dart';

enum _QuranIndexSection { surahs, juz }

class QuranIndex extends ConsumerStatefulWidget {
  final Widget? header;
  final List<Surah> surahs;
  final Future<void> Function(Surah surah, {String? initialVerseId})
  onOpenReading;

  const QuranIndex({
    super.key,
    this.header,
    required this.surahs,
    required this.onOpenReading,
  });

  @override
  ConsumerState<QuranIndex> createState() => _QuranIndexState();
}

class _QuranIndexState extends ConsumerState<QuranIndex> {
  _QuranIndexSection _section = _QuranIndexSection.surahs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DefaultTabController(
      length: 2,
      child: CustomScrollView(
        key: const ValueKey('homeQuranScroll'),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: TabBar(
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
                dividerColor: Theme.of(context).colorScheme.outlineVariant,
                onTap: (index) =>
                    setState(() => _section = _QuranIndexSection.values[index]),
                tabs: [
                  Tab(text: l10n.surahs),
                  Tab(text: l10n.juz),
                ],
              ),
            ),
          ),
          _section == _QuranIndexSection.surahs
              ? _buildSurahList()
              : _buildJuzList(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSurahList() {
    if (widget.surahs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text(context.l10n.noSurahs)),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: widget.surahs.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (context, index) {
          final surah = widget.surahs[index];
          return SurahTile(
            surah: surah,
            onTap: () => unawaited(widget.onOpenReading(surah)),
          );
        },
      ),
    );
  }

  Widget _buildJuzList() {
    final surahsByNumber = {
      for (final surah in widget.surahs) surah.surahNumber: surah,
    };
    return ref
        .watch(juzListProvider)
        .when(
          data: (entries) => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: entries.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final startSurah = surahsByNumber[entry.juz.startSurahNumber]!;
                return JuzTile(
                  juz: entry.juz,
                  startSurah: startSurah,
                  page: entry.page,
                  onTap: () => unawaited(
                    widget.onOpenReading(
                      startSurah,
                      initialVerseId: entry.juz.startVerseId,
                    ),
                  ),
                );
              },
            ),
          ),
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.juzLoadError,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        );
  }
}
