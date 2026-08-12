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
  final List<Surah> surahs;
  final Future<void> Function(Surah surah, {String? initialVerseId})
  onOpenReading;

  const QuranIndex({
    super.key,
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<_QuranIndexSection>(
            segments: [
              ButtonSegment(
                value: _QuranIndexSection.surahs,
                label: Text(l10n.surahs),
              ),
              ButtonSegment(
                value: _QuranIndexSection.juz,
                label: Text(l10n.juz),
              ),
            ],
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                final colors = Theme.of(context).colorScheme;
                return states.contains(WidgetState.selected)
                    ? colors.primaryContainer
                    : colors.surfaceContainerLow;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                final colors = Theme.of(context).colorScheme;
                return states.contains(WidgetState.selected)
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant;
              }),
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            selected: {_section},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() => _section = selection.first);
            },
          ),
        ),
        Expanded(
          child: _section == _QuranIndexSection.surahs
              ? _buildSurahList()
              : _buildJuzList(),
        ),
      ],
    );
  }

  Widget _buildSurahList() {
    if (widget.surahs.isEmpty) {
      return Center(child: Text(context.l10n.noSurahs));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: widget.surahs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final surah = widget.surahs[index];
        return SurahTile(
          surah: surah,
          onTap: () => unawaited(widget.onOpenReading(surah)),
        );
      },
    );
  }

  Widget _buildJuzList() {
    final surahsByNumber = {
      for (final surah in widget.surahs) surah.surahNumber: surah,
    };
    return ref
        .watch(juzListProvider)
        .when(
          data: (entries) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.juzLoadError,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
            ),
          ),
        );
  }
}
