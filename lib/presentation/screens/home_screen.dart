import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/backup/quran_backup_file_operations.dart';
import '../../data/backup/quran_backup_service.dart';
import '../../data/feedback/anonymous_feedback_service.dart';
import '../../data/notifications/prayer_reminder_settings.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/surah.dart';
import '../../l10n/l10n.dart';
import '../providers/locale_provider.dart';
import '../providers/quran_providers.dart';
import '../widgets/juz_tile.dart';
import '../widgets/surah_tile.dart';
import 'reading_screen.dart';

enum _HomeMenuAction {
  switchLanguage,
  toggleDarkMode,
  saveBackup,
  shareBackup,
  restoreBackup,
  feedback,
  reminders,
}

enum _FeedbackPromptAction { notNow, giveFeedback }

enum _QuranIndexSection { surahs, juz }

enum _BackupPassphrasePurpose { save, share, restore }

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
  _QuranIndexSection _indexSection = _QuranIndexSection.surahs;

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
          PopupMenuButton<_HomeMenuAction>(
            key: const ValueKey('homeMenuButton'),
            tooltip: l10n.menu,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 4),
            color: colors.surfaceContainerHigh,
            surfaceTintColor: Colors.transparent,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            constraints: const BoxConstraints(minWidth: 252, maxWidth: 280),
            onSelected: (action) {
              switch (action) {
                case _HomeMenuAction.switchLanguage:
                  final nextLocale = locale.languageCode == 'ar'
                      ? const Locale('en')
                      : const Locale('ar');
                  unawaited(
                    ref.read(appLocaleProvider.notifier).setLocale(nextLocale),
                  );
                case _HomeMenuAction.toggleDarkMode:
                  ref.read(themeModeProvider.notifier).state = darkModeEnabled
                      ? ThemeMode.system
                      : ThemeMode.dark;
                case _HomeMenuAction.saveBackup:
                  _saveBackup(context);
                case _HomeMenuAction.shareBackup:
                  _shareBackup(context);
                case _HomeMenuAction.restoreBackup:
                  _restoreBackup(context);
                case _HomeMenuAction.feedback:
                  _showFeedbackDialog(context);
                case _HomeMenuAction.reminders:
                  _showPrayerReminderDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _HomeMenuAction.switchLanguage,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: const ValueKey('homeMenu-language'),
                  icon: Icons.translate_rounded,
                  label: l10n.switchLanguage,
                ),
              ),
              const PopupMenuDivider(height: 9),
              PopupMenuItem(
                value: _HomeMenuAction.toggleDarkMode,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: const ValueKey('homeMenu-darkMode'),
                  icon: darkModeEnabled
                      ? Icons.dark_mode_rounded
                      : Icons.dark_mode_outlined,
                  label: l10n.darkMode,
                  checked: darkModeEnabled,
                ),
              ),
              const PopupMenuDivider(height: 9),
              PopupMenuItem(
                value: _HomeMenuAction.reminders,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: const ValueKey('homeMenu-reminders'),
                  icon: Icons.notifications_active_outlined,
                  label: l10n.readingReminders,
                ),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.feedback,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: const ValueKey('homeMenu-feedback'),
                  icon: Icons.feedback_outlined,
                  label: l10n.sendFeedback,
                ),
              ),
              const PopupMenuDivider(height: 9),
              PopupMenuItem(
                value: _HomeMenuAction.saveBackup,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: const ValueKey('homeMenu-saveBackup'),
                  icon: Icons.save_alt_rounded,
                  label: l10n.saveBackupToDevice,
                ),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.shareBackup,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: const ValueKey('homeMenu-shareBackup'),
                  icon: Icons.share_outlined,
                  label: l10n.shareBackup,
                ),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.restoreBackup,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: const ValueKey('homeMenu-restoreBackup'),
                  icon: Icons.download_rounded,
                  label: l10n.restoreBackup,
                ),
              ),
            ],
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: colors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ),
            ),
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
                  selected: {_indexSection},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => _indexSection = selection.first);
                  },
                ),
              ),
              Expanded(
                child: _indexSection == _QuranIndexSection.surahs
                    ? _buildSurahList(surahs)
                    : _buildJuzList(surahsByNumber),
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

  Widget _buildSurahList(List<Surah> surahs) {
    if (surahs.isEmpty) {
      return Center(child: Text(context.l10n.noSurahs));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: surahs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return SurahTile(
          surah: surah,
          onTap: () => unawaited(_openReadingScreen(surah)),
        );
      },
    );
  }

  Widget _buildJuzList(Map<int, Surah> surahsByNumber) {
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
                  _openReadingScreen(
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
      purpose: _BackupPassphrasePurpose.save,
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
      purpose: _BackupPassphrasePurpose.share,
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
      purpose: _BackupPassphrasePurpose.restore,
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
    required _BackupPassphrasePurpose purpose,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _BackupPassphraseDialog(purpose: purpose),
    );
  }

  Future<bool> _showFeedbackDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => _FeedbackDialog(
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
      builder: (context) => _HomeDialog(
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
      builder: (context) => const _PrayerReminderDialog(),
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

class _HomeDialog extends StatelessWidget {
  final Key dialogKey;
  final Key headerKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget content;
  final List<Widget> actions;

  const _HomeDialog({
    required this.dialogKey,
    required this.headerKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      key: dialogKey,
      backgroundColor: colors.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Row(
        key: headerKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.onPrimaryContainer, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      content: content,
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      actions: actions,
    );
  }
}

class _HomeDialogNotice extends StatelessWidget {
  final Key noticeKey;
  final IconData icon;
  final String text;

  const _HomeDialogNotice({
    required this.noticeKey,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
    );

    return Material(
      key: noticeKey,
      color: colors.surfaceContainerLow,
      shape: shape,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _homeDialogInputDecoration(
  BuildContext context, {
  required String labelText,
  String? hintText,
  IconData? prefixIcon,
  bool alignLabelWithHint = false,
}) {
  final colors = Theme.of(context).colorScheme;
  final borderRadius = BorderRadius.circular(14);

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    alignLabelWithHint: alignLabelWithHint,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
    filled: true,
    fillColor: colors.surfaceContainerLow,
    border: OutlineInputBorder(borderRadius: borderRadius),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: colors.outlineVariant.withValues(alpha: 0.7),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colors.error, width: 1.5),
    ),
  );
}

class _BackupPassphraseDialog extends StatefulWidget {
  final _BackupPassphrasePurpose purpose;

  const _BackupPassphraseDialog({required this.purpose});

  @override
  State<_BackupPassphraseDialog> createState() =>
      _BackupPassphraseDialogState();
}

class _BackupPassphraseDialogState extends State<_BackupPassphraseDialog> {
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  late NavigatorState _navigator;
  String? _errorText;
  bool _submitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purpose = widget.purpose;
    final confirm = purpose != _BackupPassphrasePurpose.restore;
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final (keyName, icon, title, subtitle, actionLabel) = switch (purpose) {
      _BackupPassphrasePurpose.save => (
        'saveBackup',
        Icons.save_alt_rounded,
        l10n.saveBackupToDevice,
        l10n.saveBackupSubtitle,
        l10n.save,
      ),
      _BackupPassphrasePurpose.share => (
        'shareBackup',
        Icons.share_outlined,
        l10n.shareBackup,
        l10n.shareBackupSubtitle,
        l10n.share,
      ),
      _BackupPassphrasePurpose.restore => (
        'restoreBackup',
        Icons.download_rounded,
        l10n.restoreBackup,
        l10n.restoreBackupSubtitle,
        l10n.replaceAndRestore,
      ),
    };

    return _HomeDialog(
      dialogKey: ValueKey('homeDialog-$keyName'),
      headerKey: ValueKey('homeDialogHeader-$keyName'),
      icon: icon,
      title: title,
      subtitle: subtitle,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _passphraseController,
              autofocus: true,
              obscureText: true,
              textInputAction: confirm
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: (_) {
                if (!confirm) _submit();
              },
              decoration: _homeDialogInputDecoration(
                context,
                labelText: l10n.passphrase,
                prefixIcon: Icons.lock_outline_rounded,
              ),
            ),
            if (confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: _homeDialogInputDecoration(
                  context,
                  labelText: l10n.confirmPassphrase,
                  prefixIcon: Icons.lock_outline_rounded,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _HomeDialogNotice(
              noticeKey: const ValueKey('backupProtectionNotice'),
              icon: Icons.shield_outlined,
              text: confirm
                  ? l10n.backupProtectionCreate
                  : l10n.backupProtectionRestore,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _errorText!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => _navigator.pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: _submit,
          icon: Icon(icon, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }

  void _submit() {
    if (!mounted || _submitted) return;
    final passphrase = _passphraseController.text;
    if (passphrase.trim().isEmpty) {
      setState(() {
        _errorText = context.l10n.passphraseRequired;
      });
      return;
    }
    if (widget.purpose != _BackupPassphrasePurpose.restore &&
        passphrase.trim().length < minimumBackupPassphraseLength) {
      setState(() {
        _errorText = context.l10n.passphraseTooShort;
      });
      return;
    }
    if (widget.purpose != _BackupPassphrasePurpose.restore &&
        passphrase != _confirmController.text) {
      setState(() {
        _errorText = context.l10n.passphrasesMismatch;
      });
      return;
    }
    _submitted = true;
    _navigator.pop(passphrase);
  }
}

class _PrayerReminderDialog extends ConsumerStatefulWidget {
  const _PrayerReminderDialog();

  @override
  ConsumerState<_PrayerReminderDialog> createState() =>
      _PrayerReminderDialogState();
}

class _PrayerReminderDialogState extends ConsumerState<_PrayerReminderDialog> {
  bool _initialized = false;
  bool _saving = false;
  bool _enabled = PrayerReminderSettings.defaults.enabled;
  PrayerReminderPrayer _prayer = PrayerReminderSettings.defaults.prayer;
  int _prayerTimeMinutes = PrayerReminderSettings.defaults.prayerTimeMinutes;
  int _offsetMinutes = PrayerReminderSettings.defaults.offsetMinutes;
  int _snoozeMinutes = PrayerReminderSettings.defaults.snoozeMinutes;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(prayerReminderSettingsProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return settingsAsync.when(
      loading: () => _HomeDialog(
        dialogKey: const ValueKey('homeDialog-remindersLoading'),
        headerKey: const ValueKey('homeDialogHeader-remindersLoading'),
        icon: Icons.notifications_active_outlined,
        title: l10n.readingReminders,
        subtitle: l10n.loadingReminderSettings,
        content: SizedBox(
          height: 96,
          child: Center(
            child: Semantics(
              label: l10n.loadingReminderSettingsLabel,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        actions: [],
      ),
      error: (_, _) => _HomeDialog(
        dialogKey: const ValueKey('homeDialog-remindersError'),
        headerKey: const ValueKey('homeDialogHeader-remindersError'),
        icon: Icons.notifications_off_outlined,
        title: l10n.readingReminders,
        subtitle: l10n.reminderSettingsUnavailable,
        content: _HomeDialogNotice(
          noticeKey: const ValueKey('reminderLoadErrorNotice'),
          icon: Icons.error_outline_rounded,
          text: l10n.reminderSettingsLoadFailed,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          FilledButton.icon(
            key: const ValueKey('reminderRetryAction'),
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => ref.invalidate(prayerReminderSettingsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      ),
      data: (settings) {
        _initialize(settings);
        final controlsEnabled = !_saving && _enabled;
        final sectionShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.65),
          ),
        );

        return _HomeDialog(
          dialogKey: const ValueKey('homeDialog-reminders'),
          headerKey: const ValueKey('homeDialogHeader-reminders'),
          icon: Icons.notifications_active_outlined,
          title: l10n.readingReminders,
          subtitle: l10n.reminderSubtitle,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  key: const ValueKey('reminderEnableCard'),
                  color: colors.surfaceContainerLow,
                  shape: sectionShape,
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
                    title: Text(
                      l10n.enableReminder,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _enabled
                          ? l10n.reminderEnabledBody
                          : l10n.reminderDisabledBody,
                    ),
                    value: _enabled,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _enabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PrayerReminderPrayer>(
                  initialValue: _prayer,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(Icons.expand_more_rounded),
                  decoration: _homeDialogInputDecoration(
                    context,
                    labelText: l10n.prayer,
                    prefixIcon: Icons.mosque_outlined,
                  ),
                  items: PrayerReminderPrayer.values
                      .map(
                        (prayer) => DropdownMenuItem(
                          value: prayer,
                          child: Text(
                            _localizedPrayerLabel(context, prayer),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: !controlsEnabled
                      ? null
                      : (value) => setState(() {
                          if (value != null) _prayer = value;
                        }),
                ),
                const SizedBox(height: 12),
                Material(
                  key: const ValueKey('reminderPrayerTimeCard'),
                  color: colors.surfaceContainerLow,
                  shape: sectionShape,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: sectionShape,
                    onTap: controlsEnabled ? _pickPrayerTime : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: controlsEnabled
                                  ? colors.primaryContainer
                                  : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.schedule_rounded,
                              color: controlsEnabled
                                  ? colors.onPrimaryContainer
                                  : colors.onSurfaceVariant.withValues(
                                      alpha: 0.55,
                                    ),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.prayerTime,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTimeOfDay(_prayerTimeMinutes),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: controlsEnabled
                                        ? colors.onSurface
                                        : colors.onSurface.withValues(
                                            alpha: 0.38,
                                          ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: controlsEnabled ? 1 : 0.38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _offsetMinutes,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(Icons.expand_more_rounded),
                  decoration: _homeDialogInputDecoration(
                    context,
                    labelText: l10n.reminderAfter,
                    prefixIcon: Icons.notifications_none_rounded,
                  ),
                  items: const [0, 5, 10, 15, 20, 30, 45, 60]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            minutes == 0
                                ? l10n.atPrayerTime
                                : l10n.minutesShort(minutes),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: !controlsEnabled
                      ? null
                      : (value) => setState(() {
                          if (value != null) _offsetMinutes = value;
                        }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _snoozeMinutes,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(Icons.expand_more_rounded),
                  decoration: _homeDialogInputDecoration(
                    context,
                    labelText: l10n.snooze,
                    prefixIcon: Icons.snooze_rounded,
                  ),
                  items: const [5, 10, 15, 30, 45, 60]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            l10n.minutesShort(minutes),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: !controlsEnabled
                      ? null
                      : (value) => setState(() {
                          if (value != null) _snoozeMinutes = value;
                        }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            if (_saving)
              FilledButton(
                key: const ValueKey('reminderSaveAction'),
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                onPressed: null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.saving),
                  ],
                ),
              )
            else
              FilledButton.icon(
                key: const ValueKey('reminderSaveAction'),
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                onPressed: _save,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(l10n.save),
              ),
          ],
        );
      },
    );
  }

  void _initialize(PrayerReminderSettings settings) {
    if (_initialized) return;
    _initialized = true;
    _enabled = settings.enabled;
    _prayer = settings.prayer;
    _prayerTimeMinutes = settings.prayerTimeMinutes;
    _offsetMinutes = settings.offsetMinutes;
    _snoozeMinutes = settings.snoozeMinutes;
  }

  Future<void> _pickPrayerTime() async {
    final currentTime = TimeOfDay(
      hour: _prayerTimeMinutes ~/ 60,
      minute: _prayerTimeMinutes % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final outline = BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.7),
        );

        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: colors.surfaceContainerHigh,
              dialBackgroundColor: colors.surfaceContainerLow,
              dialHandColor: colors.primary,
              dialTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.onPrimary
                    : colors.onSurface,
              ),
              entryModeIconColor: colors.primary,
              hourMinuteColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.primaryContainer
                    : colors.surfaceContainerLow,
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.onPrimaryContainer
                    : colors.onSurface,
              ),
              dayPeriodColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.primaryContainer
                    : colors.surfaceContainerLow,
              ),
              dayPeriodTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: outline,
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: outline,
              ),
              cancelButtonStyle: TextButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
              confirmButtonStyle: TextButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    setState(() {
      _prayerTimeMinutes = picked.hour * 60 + picked.minute;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final settings = PrayerReminderSettings(
      enabled: _enabled,
      prayer: _prayer,
      prayerTimeMinutes: _prayerTimeMinutes,
      offsetMinutes: _offsetMinutes,
      snoozeMinutes: _snoozeMinutes,
    );

    late final bool saved;
    try {
      saved = await ref
          .read(prayerReminderServiceProvider)
          .saveSettings(settings);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.reminderScheduleFailed),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;

    ref.invalidate(prayerReminderSettingsProvider);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? _enabled
                    ? context.l10n.reminderScheduled
                    : context.l10n.reminderDisabled
              : context.l10n.reminderPermissionDenied,
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTimeOfDay(int minutesOfDay) {
    final time = TimeOfDay(hour: minutesOfDay ~/ 60, minute: minutesOfDay % 60);
    return time.format(context);
  }

  String _localizedPrayerLabel(
    BuildContext context,
    PrayerReminderPrayer prayer,
  ) {
    return switch (prayer) {
      PrayerReminderPrayer.fajr => context.l10n.fajr,
      PrayerReminderPrayer.dhuhr => context.l10n.dhuhr,
      PrayerReminderPrayer.asr => context.l10n.asr,
      PrayerReminderPrayer.maghrib => context.l10n.maghrib,
      PrayerReminderPrayer.isha => context.l10n.isha,
    };
  }
}

class _FeedbackDialog extends ConsumerStatefulWidget {
  final Future<void> Function()? onSubmitted;

  const _FeedbackDialog({this.onSubmitted});

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return _HomeDialog(
      dialogKey: const ValueKey('homeDialog-feedback'),
      headerKey: const ValueKey('homeDialogHeader-feedback'),
      icon: Icons.feedback_outlined,
      title: l10n.sendFeedback,
      subtitle: l10n.feedbackSubtitle,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _feedbackController,
              autofocus: true,
              minLines: 4,
              maxLines: 6,
              maxLength: AnonymousFeedbackService.maxLength,
              textInputAction: TextInputAction.newline,
              decoration: _homeDialogInputDecoration(
                context,
                labelText: l10n.feedback,
                hintText: l10n.feedbackHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            _HomeDialogNotice(
              noticeKey: const ValueKey('feedbackPrivacyNotice'),
              icon: Icons.privacy_tip_outlined,
              text: l10n.feedbackPrivacy,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _errorText!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        if (_submitting)
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(l10n.sending),
              ],
            ),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: _submit,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(l10n.send),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await ref
          .read(anonymousFeedbackServiceProvider)
          .submitFeedback(_feedbackController.text);
      try {
        await widget.onSubmitted?.call();
      } catch (e) {
        debugPrint('Failed to mark feedback prompt submitted: $e');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.feedbackSent),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FeedbackValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message == 'Feedback is too long.'
            ? context.l10n.feedbackTooLong
            : context.l10n.feedbackRequired;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Failed to submit anonymous feedback: $e');
      setState(() {
        _errorText = context.l10n.feedbackSendFailed;
        _submitting = false;
      });
    }
  }
}

class _HomeMenuItem extends StatelessWidget {
  final Key rowKey;
  final IconData icon;
  final String label;
  final bool? checked;

  const _HomeMenuItem({
    required this.rowKey,
    required this.icon,
    required this.label,
    this.checked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      key: rowKey,
      checked: checked,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (checked == true) ...[
                const SizedBox(width: 12),
                Icon(Icons.check_rounded, color: colors.primary, size: 18),
              ],
            ],
          ),
        ),
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
