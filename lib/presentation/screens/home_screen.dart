import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/feedback/anonymous_feedback_service.dart';
import '../../data/notifications/prayer_reminder_settings.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/surah.dart';
import '../providers/quran_providers.dart';
import '../widgets/juz_tile.dart';
import '../widgets/surah_tile.dart';
import 'reading_screen.dart';

enum _HomeMenuAction {
  toggleDarkMode,
  exportBackup,
  importBackup,
  feedback,
  reminders,
}

enum _FeedbackPromptAction { notNow, giveFeedback }

enum _QuranIndexSection { surahs, juz }

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
    final surahsAsync = ref.watch(surahListProvider);
    final lastPositionAsync = ref.watch(lastReadPositionProvider);
    final bookmarksAsync = ref.watch(recentBookmarksProvider);
    final feedbackPromptAsync = ref.watch(feedbackPromptShouldShowProvider);
    final themeMode = ref.watch(themeModeProvider);
    final darkModeEnabled = themeMode == ThemeMode.dark;
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
            Text('Holy Quran', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        actions: [
          PopupMenuButton<_HomeMenuAction>(
            key: const ValueKey('homeMenuButton'),
            tooltip: 'Menu',
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
                case _HomeMenuAction.toggleDarkMode:
                  ref.read(themeModeProvider.notifier).state = darkModeEnabled
                      ? ThemeMode.system
                      : ThemeMode.dark;
                case _HomeMenuAction.exportBackup:
                  _exportBackup(context);
                case _HomeMenuAction.importBackup:
                  _importBackup(context);
                case _HomeMenuAction.feedback:
                  _showFeedbackDialog(context);
                case _HomeMenuAction.reminders:
                  _showPrayerReminderDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _HomeMenuAction.toggleDarkMode,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: const ValueKey('homeMenu-darkMode'),
                  icon: darkModeEnabled
                      ? Icons.dark_mode_rounded
                      : Icons.dark_mode_outlined,
                  label: 'Dark mode',
                  checked: darkModeEnabled,
                ),
              ),
              const PopupMenuDivider(height: 9),
              const PopupMenuItem(
                value: _HomeMenuAction.reminders,
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: ValueKey('homeMenu-reminders'),
                  icon: Icons.notifications_active_outlined,
                  label: 'Reading reminders',
                ),
              ),
              const PopupMenuItem(
                value: _HomeMenuAction.feedback,
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: ValueKey('homeMenu-feedback'),
                  icon: Icons.feedback_outlined,
                  label: 'Send feedback',
                ),
              ),
              const PopupMenuDivider(height: 9),
              const PopupMenuItem(
                value: _HomeMenuAction.exportBackup,
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: ValueKey('homeMenu-exportBackup'),
                  icon: Icons.upload_file_rounded,
                  label: 'Export backup',
                ),
              ),
              const PopupMenuItem(
                value: _HomeMenuAction.importBackup,
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _HomeMenuItem(
                  rowKey: ValueKey('homeMenu-importBackup'),
                  icon: Icons.download_rounded,
                  label: 'Import backup',
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
                  segments: const [
                    ButtonSegment(
                      value: _QuranIndexSection.surahs,
                      label: Text('Surahs'),
                    ),
                    ButtonSegment(
                      value: _QuranIndexSection.juz,
                      label: Text('Juz'),
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
              'Failed to load surahs.\nPlease restart the app.',
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
      return const Center(child: Text('No surahs found.'));
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
                'Failed to load Juz.\nPlease restart the app.',
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

  Future<void> _exportBackup(BuildContext context) async {
    final passphrase = await _promptPassphrase(context, confirm: true);
    if (passphrase == null) return;

    try {
      final exported = await ref
          .read(quranBackupFileServiceProvider)
          .exportBackup(passphrase);
      if (!context.mounted) return;
      _showSnackBar(context, exported ? 'Backup exported' : 'Export canceled');
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, 'Export failed');
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final passphrase = await _promptPassphrase(context);
    if (passphrase == null) return;

    try {
      final imported = await ref
          .read(quranBackupFileServiceProvider)
          .importBackup(passphrase);
      if (!context.mounted) return;
      if (imported) {
        ref.invalidate(lastReadPositionProvider);
        ref.invalidate(recentBookmarksProvider);
        ref.invalidate(bookmarksBySurahProvider);
      }
      _showSnackBar(context, imported ? 'Backup imported' : 'Import canceled');
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, 'Import failed. Check the file and passphrase.');
      }
    }
  }

  Future<String?> _promptPassphrase(
    BuildContext context, {
    bool confirm = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _BackupPassphraseDialog(confirm: confirm),
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
        title: 'How is your Quran reading experience?',
        subtitle: 'A quick anonymous note can help shape what comes next.',
        content: const Text(
          'If you have a moment, share what would make the app better. Your note is anonymous.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(72, 44)),
            onPressed: () =>
                Navigator.of(context).pop(_FeedbackPromptAction.notNow),
            child: const Text('Not now'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(136, 44)),
            onPressed: () =>
                Navigator.of(context).pop(_FeedbackPromptAction.giveFeedback),
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('Give feedback'),
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
  final bool confirm;

  const _BackupPassphraseDialog({required this.confirm});

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
    final confirm = widget.confirm;
    final colors = Theme.of(context).colorScheme;

    return _HomeDialog(
      dialogKey: ValueKey(
        confirm ? 'homeDialog-exportBackup' : 'homeDialog-importBackup',
      ),
      headerKey: ValueKey(
        confirm
            ? 'homeDialogHeader-exportBackup'
            : 'homeDialogHeader-importBackup',
      ),
      icon: confirm ? Icons.upload_file_rounded : Icons.download_rounded,
      title: confirm ? 'Export backup' : 'Import backup',
      subtitle: confirm
          ? 'Create an encrypted copy of your reading progress.'
          : 'Restore your bookmarks and last reading position.',
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
                labelText: 'Passphrase',
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
                  labelText: 'Confirm passphrase',
                  prefixIcon: Icons.lock_outline_rounded,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _HomeDialogNotice(
              noticeKey: const ValueKey('backupProtectionNotice'),
              icon: Icons.shield_outlined,
              text: confirm
                  ? 'This passphrase encrypts your bookmarks and last reading position. It cannot be recovered, so keep it safe.'
                  : 'Importing replaces your current bookmarks and last reading position. Use the original passphrase.',
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
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: _submit,
          icon: Icon(
            confirm ? Icons.upload_rounded : Icons.download_rounded,
            size: 18,
          ),
          label: Text(confirm ? 'Export' : 'Replace & import'),
        ),
      ],
    );
  }

  void _submit() {
    if (!mounted || _submitted) return;
    final passphrase = _passphraseController.text;
    if (passphrase.trim().isEmpty) {
      setState(() {
        _errorText = 'Passphrase is required';
      });
      return;
    }
    if (widget.confirm && passphrase != _confirmController.text) {
      setState(() {
        _errorText = 'Passphrases do not match';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return settingsAsync.when(
      loading: () => _HomeDialog(
        dialogKey: const ValueKey('homeDialog-remindersLoading'),
        headerKey: const ValueKey('homeDialogHeader-remindersLoading'),
        icon: Icons.notifications_active_outlined,
        title: 'Reading reminders',
        subtitle: 'Loading your reminder settings.',
        content: SizedBox(
          height: 96,
          child: Center(
            child: Semantics(
              label: 'Loading reminder settings',
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
        title: 'Reading reminders',
        subtitle: 'Your settings are unavailable right now.',
        content: const _HomeDialogNotice(
          noticeKey: ValueKey('reminderLoadErrorNotice'),
          icon: Icons.error_outline_rounded,
          text: 'Reminder settings could not be loaded.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            key: const ValueKey('reminderRetryAction'),
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => ref.invalidate(prayerReminderSettingsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
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
          title: 'Reading reminders',
          subtitle: 'Build a gentle reading habit around a prayer time.',
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
                      'Enable reminder',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _enabled
                          ? 'A daily reading reminder is on.'
                          : 'Turn this on when you are ready.',
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
                    labelText: 'Prayer',
                    prefixIcon: Icons.mosque_outlined,
                  ),
                  items: PrayerReminderPrayer.values
                      .map(
                        (prayer) => DropdownMenuItem(
                          value: prayer,
                          child: Text(
                            prayer.label,
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
                                  'Prayer time',
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
                    labelText: 'Reminder after',
                    prefixIcon: Icons.notifications_none_rounded,
                  ),
                  items: const [0, 5, 10, 15, 20, 30, 45, 60]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            minutes == 0 ? 'At prayer time' : '$minutes min',
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
                    labelText: 'Snooze',
                    prefixIcon: Icons.snooze_rounded,
                  ),
                  items: const [5, 10, 15, 30, 45, 60]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            '$minutes min',
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
              child: const Text('Cancel'),
            ),
            if (_saving)
              FilledButton(
                key: const ValueKey('reminderSaveAction'),
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                onPressed: null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Saving'),
                  ],
                ),
              )
            else
              FilledButton.icon(
                key: const ValueKey('reminderSaveAction'),
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                onPressed: _save,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save'),
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
        const SnackBar(
          content: Text('Reminder could not be scheduled. Please try again.'),
          duration: Duration(seconds: 2),
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
                    ? 'Reading reminder scheduled'
                    : 'Reading reminder disabled'
              : 'Reminder permission was not granted',
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
    final colors = Theme.of(context).colorScheme;

    return _HomeDialog(
      dialogKey: const ValueKey('homeDialog-feedback'),
      headerKey: const ValueKey('homeDialogHeader-feedback'),
      icon: Icons.feedback_outlined,
      title: 'Send feedback',
      subtitle: 'Help us improve the Quran reading experience.',
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
                labelText: 'Feedback',
                hintText: 'Share what would make the app better.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            const _HomeDialogNotice(
              noticeKey: ValueKey('feedbackPrivacyNotice'),
              icon: Icons.privacy_tip_outlined,
              text: 'Sent anonymously. Do not include private information.',
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
          child: const Text('Cancel'),
        ),
        if (_submitting)
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: null,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Sending'),
              ],
            ),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: _submit,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send'),
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
        const SnackBar(
          content: Text('Feedback sent'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FeedbackValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Failed to submit anonymous feedback: $e');
      setState(() {
        _errorText = 'Feedback could not be sent. Please try again later.';
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
    final readingLabel =
        '${surah.nameEnglish}${verseNum.isNotEmpty ? ' · Verse $verseNum' : ''}';
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
        label: 'Continue reading, $readingLabel',
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
                          'Continue Reading',
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
                    'Bookmarks',
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
        surah?.nameEnglish ?? 'Surah ${bookmark.verseId.split(':').first}';
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
              tooltip: 'Remove bookmark',
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
                '$title${verseNum.isNotEmpty ? ' · Verse $verseNum' : ''}',
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
        const SnackBar(
          content: Text('Bookmark removed'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
