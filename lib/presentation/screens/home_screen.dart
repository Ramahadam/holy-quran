import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/backup/quran_backup_file_operations.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/surah.dart';
import '../../l10n/l10n.dart';
import '../providers/locale_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/theme_mode_provider.dart';
import '../widgets/home_actions_menu.dart';
import '../widgets/home_backup_passphrase_dialog.dart';
import '../widgets/home_dialog.dart';
import '../widgets/home_feedback_dialog.dart';
import '../widgets/home_prayer_reminder_dialog.dart';
import '../widgets/quran_index.dart';
import 'reading_screen.dart';

enum _FeedbackPromptAction { notNow, giveFeedback }

typedef _OpenReading =
    Future<void> Function(Surah surah, {String? initialVerseId});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _heartbeatPromptScheduled = false;
  Timer? _heartbeatPromptRefreshTimer;

  @override
  void dispose() {
    _heartbeatPromptRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surahsAsync = ref.watch(surahListProvider);
    final lastPositionAsync = ref.watch(lastReadPositionProvider);
    final bookmarksAsync = ref.watch(recentBookmarksProvider);
    final feedbackPromptAsync = ref.watch(feedbackPromptShouldShowProvider);
    final themeMode = ref.watch(themeModeProvider);
    final darkModeEnabled = themeMode == ThemeMode.dark;
    final locale = ref.watch(appLocaleProvider);

    _maybeScheduleHeartbeatPrompt(feedbackPromptAsync);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'القرآن الكريم',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
              textDirection: TextDirection.rtl,
            ),
            Text(l10n.appTitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        actions: [
          HomeActionsMenu(
            darkModeEnabled: darkModeEnabled,
            onSwitchLanguage: () {
              final nextLocale = locale.languageCode == 'ar'
                  ? const Locale('en')
                  : const Locale('ar');
              unawaited(
                ref.read(appLocaleProvider.notifier).setLocale(nextLocale),
              );
            },
            onToggleDarkMode: () => unawaited(
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(
                    darkModeEnabled ? ThemeMode.light : ThemeMode.dark,
                  ),
            ),
            onOpenReminders: () =>
                unawaited(_showPrayerReminderDialog(context)),
            onSendFeedback: () => unawaited(_showFeedbackDialog(context)),
            onSaveBackup: () => unawaited(_saveBackup(context)),
            onShareBackup: () => unawaited(_shareBackup(context)),
            onRestoreBackup: () => unawaited(_restoreBackup(context)),
          ),
        ],
      ),
      body: surahsAsync.when(
        data: (surahs) {
          final lastPosition = lastPositionAsync.valueOrNull;
          final bookmarks = bookmarksAsync.valueOrNull ?? const <Bookmark>[];
          final surahsByNumber = {
            for (final surah in surahs) surah.surahNumber: surah,
          };
          Surah? lastSurah;
          if (lastPosition != null) {
            final surahNum = int.tryParse(
              lastPosition.verseId.split(':').first,
            );
            if (surahNum != null) {
              lastSurah = surahs.firstWhereOrNull(
                (s) => s.surahNumber == surahNum,
              );
            }
          }

          return Column(
            children: [
              if (lastSurah != null)
                _LastReadBanner(
                  surah: lastSurah,
                  verseId: lastPosition!.verseId,
                  onOpenReading: _openReadingScreen,
                ),
              if (bookmarks.isNotEmpty)
                _BookmarksSection(
                  bookmarks: bookmarks,
                  surahsByNumber: surahsByNumber,
                  onOpenReading: _openReadingScreen,
                ),
              Expanded(
                child: QuranIndex(
                  surahs: surahs,
                  onOpenReading: _openReadingScreen,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.surahLoadError,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  void _maybeScheduleHeartbeatPrompt(AsyncValue<bool> promptAsync) {
    if (_heartbeatPromptScheduled || promptAsync.valueOrNull != true) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _heartbeatPromptScheduled = true;
    _heartbeatPromptRefreshTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showHeartbeatFeedbackPrompt(context);
    });
  }

  Future<void> _openReadingScreen(Surah surah, {String? initialVerseId}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ReadingScreen(surah: surah, initialVerseId: initialVerseId),
      ),
    );
    if (!mounted) return;
    ref.invalidate(feedbackPromptShouldShowProvider);
    _scheduleHeartbeatPromptRefresh();
  }

  void _scheduleHeartbeatPromptRefresh() {
    final delay = feedbackPromptTestDelay;
    if (delay == null) return;
    _heartbeatPromptRefreshTimer?.cancel();
    _heartbeatPromptRefreshTimer = Timer(delay, () {
      if (!mounted) return;
      ref.invalidate(feedbackPromptShouldShowProvider);
    });
  }

  Future<void> _saveBackup(BuildContext context) async {
    final passphrase = await _promptPassphrase(
      context,
      purpose: BackupPassphrasePurpose.save,
    );
    if (passphrase == null || !context.mounted) return;
    final l10n = context.l10n;

    try {
      final result = await ref
          .read(quranBackupFileServiceProvider)
          .saveBackup(passphrase, confirmButtonText: l10n.save);
      if (!context.mounted) return;
      _showSnackBar(context, switch (result) {
        BackupFileOperationResult.completed => l10n.backupSaved,
        BackupFileOperationResult.canceled => l10n.saveCanceled,
        BackupFileOperationResult.unavailable => l10n.saveUnavailable,
      });
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, l10n.saveBackupFailed);
      }
    }
  }

  Future<void> _shareBackup(BuildContext context) async {
    final passphrase = await _promptPassphrase(
      context,
      purpose: BackupPassphrasePurpose.share,
    );
    if (passphrase == null || !context.mounted) return;
    final l10n = context.l10n;

    try {
      final result = await ref
          .read(quranBackupFileServiceProvider)
          .shareBackup(
            passphrase,
            subject: l10n.backupFileSubject,
            title: l10n.shareBackupTitle,
          );
      if (!context.mounted) return;
      _showSnackBar(context, switch (result) {
        BackupFileOperationResult.completed => l10n.backupShared,
        BackupFileOperationResult.canceled => l10n.shareCanceled,
        BackupFileOperationResult.unavailable => l10n.shareUnavailable,
      });
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, l10n.shareBackupFailed);
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final passphrase = await _promptPassphrase(
      context,
      purpose: BackupPassphrasePurpose.restore,
    );
    if (passphrase == null || !context.mounted) return;
    final l10n = context.l10n;

    try {
      final result = await ref
          .read(quranBackupFileServiceProvider)
          .restoreBackup(passphrase, confirmButtonText: l10n.restore);
      if (!context.mounted) return;
      if (result == BackupFileOperationResult.completed) {
        ref.invalidate(lastReadPositionProvider);
        ref.invalidate(recentBookmarksProvider);
        ref.invalidate(bookmarksBySurahProvider);
      }
      _showSnackBar(context, switch (result) {
        BackupFileOperationResult.completed => l10n.backupRestored,
        BackupFileOperationResult.canceled => l10n.restoreCanceled,
        BackupFileOperationResult.unavailable => l10n.restoreUnavailable,
      });
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, l10n.restoreFailed);
      }
    }
  }

  Future<String?> _promptPassphrase(
    BuildContext context, {
    required BackupPassphrasePurpose purpose,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => HomeBackupPassphraseDialog(purpose: purpose),
    );
  }

  Future<bool> _showFeedbackDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => HomeFeedbackDialog(
            onSubmitted: () async {
              await ref
                  .read(feedbackPromptServiceProvider)
                  .markFeedbackSubmitted();
              ref.invalidate(feedbackPromptShouldShowProvider);
            },
          ),
        ) ??
        false;
  }

  Future<void> _showHeartbeatFeedbackPrompt(BuildContext context) async {
    final action = await showDialog<_FeedbackPromptAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => HomeDialog(
        dialogKey: const ValueKey('homeDialog-feedbackPrompt'),
        headerKey: const ValueKey('homeDialogHeader-feedbackPrompt'),
        icon: Icons.favorite_border_rounded,
        title: context.l10n.feedbackPromptTitle,
        subtitle: context.l10n.feedbackPromptSubtitle,
        content: Text(context.l10n.feedbackPromptBody),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(72, 44)),
            onPressed: () =>
                Navigator.of(context).pop(_FeedbackPromptAction.notNow),
            child: Text(context.l10n.notNow),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(136, 44)),
            onPressed: () =>
                Navigator.of(context).pop(_FeedbackPromptAction.giveFeedback),
            icon: const Icon(Icons.feedback_outlined),
            label: Text(context.l10n.giveFeedback),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;

    if (action == _FeedbackPromptAction.notNow) {
      await ref.read(feedbackPromptServiceProvider).dismissPrompt();
      ref.invalidate(feedbackPromptShouldShowProvider);
      return;
    }

    if (!mounted) return;
    await _showFeedbackDialog(this.context);
  }

  Future<void> _showPrayerReminderDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const HomePrayerReminderDialog(),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LastReadBanner extends ConsumerWidget {
  final Surah surah;
  final String verseId;
  final _OpenReading onOpenReading;

  const _LastReadBanner({
    required this.surah,
    required this.verseId,
    required this.onOpenReading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseNum = verseId.split(':').elementAtOrNull(1) ?? '';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final readingLabel = verseNum.isEmpty
        ? surah.nameArabic
        : '${surah.nameArabic} · ${context.l10n.verseNumber(verseNum)}';
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
    );
    void openReading() =>
        unawaited(onOpenReading(surah, initialVerseId: verseId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Semantics(
        button: true,
        label: context.l10n.continueReadingSemantics(readingLabel),
        onTap: openReading,
        excludeSemantics: true,
        child: Material(
          key: const ValueKey('continueReadingCard'),
          color: colors.surfaceContainerLow,
          shape: cardShape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: cardShape,
            onTap: openReading,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: colors.onPrimaryContainer,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.continueReading,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          readingLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarksSection extends ConsumerWidget {
  final List<Bookmark> bookmarks;
  final Map<int, Surah> surahsByNumber;
  final _OpenReading onOpenReading;

  const _BookmarksSection({
    required this.bookmarks,
    required this.surahsByNumber,
    required this.onOpenReading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        key: const ValueKey('bookmarksCard'),
        color: colors.surfaceContainerLow,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    color: colors.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.bookmarks,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.7),
            ),
            for (var index = 0; index < bookmarks.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 14,
                  color: colors.outlineVariant.withValues(alpha: 0.55),
                ),
              _BookmarkRow(
                bookmark: bookmarks[index],
                surah: _surahForBookmark(bookmarks[index]),
                onOpenReading: onOpenReading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Surah? _surahForBookmark(Bookmark bookmark) {
    final surahNum = int.tryParse(bookmark.verseId.split(':').first);
    if (surahNum == null) return null;
    return surahsByNumber[surahNum];
  }
}

class _BookmarkRow extends ConsumerWidget {
  final Bookmark bookmark;
  final Surah? surah;
  final _OpenReading onOpenReading;

  const _BookmarkRow({
    required this.bookmark,
    required this.surah,
    required this.onOpenReading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseNum = bookmark.verseId.split(':').elementAtOrNull(1) ?? '';
    final title =
        surah?.nameArabic ??
        context.l10n.surahNumber(bookmark.verseId.split(':').first);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: surah == null
          ? null
          : () => unawaited(
              onOpenReading(surah!, initialVerseId: bookmark.verseId),
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: context.l10n.removeBookmark,
              style: IconButton.styleFrom(
                foregroundColor: colors.onPrimaryContainer,
                backgroundColor: colors.primaryContainer,
                minimumSize: const Size.square(48),
                maximumSize: const Size.square(48),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.bookmark_rounded, size: 20),
              onPressed: () => _removeBookmark(context, ref),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                verseNum.isEmpty
                    ? title
                    : '$title · ${context.l10n.verseNumber(verseNum)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeBookmark(BuildContext context, WidgetRef ref) async {
    await ref.read(bookmarkRepositoryProvider).removeBookmark(bookmark.verseId);
    ref.invalidate(recentBookmarksProvider);
    final surahNum = int.tryParse(bookmark.verseId.split(':').first);
    if (surahNum != null) {
      ref.invalidate(bookmarksBySurahProvider(surahNum));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.bookmarkRemoved),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
