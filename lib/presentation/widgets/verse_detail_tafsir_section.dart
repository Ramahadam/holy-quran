import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../providers/tafsir_providers.dart';
import '../tafsir/tafsir_source_selection.dart';

class VerseDetailTafsirSection extends ConsumerStatefulWidget {
  final String verseKey;

  const VerseDetailTafsirSection({super.key, required this.verseKey});

  @override
  ConsumerState<VerseDetailTafsirSection> createState() =>
      _VerseDetailTafsirSectionState();
}

class _VerseDetailTafsirSectionState
    extends ConsumerState<VerseDetailTafsirSection> {
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
