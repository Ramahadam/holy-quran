import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/backup/quran_backup_file_operations.dart';
import '../../domain/models/surah.dart';
import '../../l10n/l10n.dart';
import '../providers/locale_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/theme_mode_provider.dart';
import '../widgets/home_actions_menu.dart';
import '../widgets/home_backup_passphrase_dialog.dart';
import '../widgets/home_feedback_dialog.dart';
import '../widgets/home_prayer_reminder_dialog.dart';
import '../widgets/quran_index.dart';
import 'bookmarks_screen.dart';
import 'reading_screen.dart';

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
    final feedbackPromptAsync = ref.watch(feedbackPromptShouldShowProvider);
    _maybeScheduleHeartbeatPrompt(feedbackPromptAsync);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 44 + MediaQuery.textScalerOf(context).scale(44),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القرآن الكريم',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineLarge,
              textDirection: TextDirection.rtl,
            ),
            Text(
              l10n.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [_buildActionsMenu()],
      ),
      bottomNavigationBar: _HomeNavigation(
        onOpenBookmarks: () => unawaited(_openBookmarksScreen()),
        settingsMenu: _buildActionsMenu(bottom: true),
      ),
      body: surahsAsync.when(
        data: (surahs) {
          final lastPosition = lastPositionAsync.valueOrNull;
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

          return QuranIndex(
            surahs: surahs,
            onOpenReading: _openReadingScreen,
            header: lastSurah == null
                ? null
                : _LastReadBanner(
                    surah: lastSurah,
                    verseId: lastPosition!.verseId,
                    onOpenReading: _openReadingScreen,
                  ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.surahLoadError,
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

  Widget _buildActionsMenu({bool bottom = false}) {
    final darkModeEnabled = ref.watch(themeModeProvider) == ThemeMode.dark;
    final locale = ref.watch(appLocaleProvider);
    return HomeActionsMenu(
      buttonKey: bottom ? const ValueKey('homeSettingsDestination') : null,
      darkModeEnabled: darkModeEnabled,
      onSwitchLanguage: () => unawaited(
        ref
            .read(appLocaleProvider.notifier)
            .setLocale(
              locale.languageCode == 'ar'
                  ? const Locale('en')
                  : const Locale('ar'),
            ),
      ),
      onToggleDarkMode: () => unawaited(
        ref
            .read(themeModeProvider.notifier)
            .setThemeMode(darkModeEnabled ? ThemeMode.light : ThemeMode.dark),
      ),
      onOpenReminders: () => unawaited(_showPrayerReminderDialog(context)),
      onSendFeedback: () => unawaited(_showFeedbackDialog(context)),
      onSaveBackup: () => unawaited(_saveBackup(context)),
      onShareBackup: () => unawaited(_shareBackup(context)),
      onRestoreBackup: () => unawaited(_restoreBackup(context)),
      child: bottom
          ? _HomeNavigationLabel(
              icon: CupertinoIcons.slider_horizontal_3,
              label: context.l10n.settings,
            )
          : null,
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

  Future<void> _openBookmarksScreen() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const BookmarksScreen()));
    if (!mounted) return;
    ref.invalidate(recentBookmarksProvider);
    ref.invalidate(allBookmarksProvider);
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
        ref.invalidate(allBookmarksProvider);
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
    final action = await showDialog<HomeFeedbackPromptAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const HomeFeedbackPromptDialog(),
    );

    if (!mounted || action == null) return;

    if (action == HomeFeedbackPromptAction.notNow) {
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
    final page = ref.watch(pageForVerseProvider(verseId)).valueOrNull;
    final readingLabel =
        '${surah.nameArabic} · ${context.l10n.verseNumber(verseNum)}';
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
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
          color: colors.primary,
          shape: cardShape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: cardShape,
            onTap: openReading,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.continueReading,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                      Icon(CupertinoIcons.book, color: colors.onPrimary),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    surah.nameArabic,
                    textDirection: TextDirection.rtl,
                    textAlign: Directionality.of(context) == TextDirection.rtl
                        ? TextAlign.right
                        : TextAlign.left,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.l10n.verseNumber(verseNum)}${page == null ? '' : ' · ${context.l10n.pageNumber(page)}'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('continueReadingButton'),
                    onPressed: openReading,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(context.l10n.continueReading),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
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

class _HomeNavigation extends StatelessWidget {
  final VoidCallback onOpenBookmarks;
  final Widget settingsMenu;

  const _HomeNavigation({
    required this.onOpenBookmarks,
    required this.settingsMenu,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  selected: true,
                  child: TextButton(
                    onPressed: () {},
                    child: _HomeNavigationLabel(
                      icon: CupertinoIcons.book,
                      label: context.l10n.quranNavigation,
                      selected: true,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  key: const ValueKey('homeBookmarksDestination'),
                  onPressed: onOpenBookmarks,
                  child: _HomeNavigationLabel(
                    icon: CupertinoIcons.bookmark,
                    label: context.l10n.bookmarks,
                  ),
                ),
              ),
              Expanded(child: settingsMenu),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeNavigationLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _HomeNavigationLabel({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
