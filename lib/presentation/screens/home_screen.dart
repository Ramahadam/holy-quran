import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/feedback/anonymous_feedback_service.dart';
import '../../data/notifications/prayer_reminder_settings.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/surah.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/surah_tile.dart';
import 'reading_screen.dart';

enum _HomeMenuAction { exportBackup, importBackup, feedback, reminders }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahListProvider);
    final lastPositionAsync = ref.watch(lastReadPositionProvider);
    final bookmarksAsync = ref.watch(recentBookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'القرآن الكريم',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.islamicGreen),
              textDirection: TextDirection.rtl,
            ),
            Text('Holy Quran', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        actions: [
          PopupMenuButton<_HomeMenuAction>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              switch (action) {
                case _HomeMenuAction.exportBackup:
                  _exportBackup(context, ref);
                case _HomeMenuAction.importBackup:
                  _importBackup(context, ref);
                case _HomeMenuAction.feedback:
                  _showFeedbackDialog(context);
                case _HomeMenuAction.reminders:
                  _showPrayerReminderDialog(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _HomeMenuAction.reminders,
                child: ListTile(
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Reading reminders'),
                ),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.feedback,
                child: ListTile(
                  leading: Icon(Icons.feedback_outlined),
                  title: Text('Send feedback'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _HomeMenuAction.exportBackup,
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Export backup'),
                ),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.importBackup,
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Import backup'),
                ),
              ),
            ],
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
                ),
              if (bookmarks.isNotEmpty)
                _BookmarksSection(
                  bookmarks: bookmarks,
                  surahsByNumber: surahsByNumber,
                ),
              Expanded(
                child: surahs.isEmpty
                    ? const Center(child: Text('No surahs found.'))
                    : ListView.separated(
                        itemCount: surahs.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppTheme.divider),
                        itemBuilder: (context, index) {
                          final surah = surahs[index];
                          return SurahTile(
                            surah: surah,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReadingScreen(surah: surah),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.islamicGreen),
        ),
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

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
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

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
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

  Future<void> _showFeedbackDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const _FeedbackDialog(),
    );
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
    return AlertDialog(
      title: Text(confirm ? 'Export backup' : 'Import backup'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              decoration: const InputDecoration(labelText: 'Passphrase'),
            ),
            if (confirm) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirm passphrase',
                ),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _navigator.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(confirm ? 'Export' : 'Import'),
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

    return settingsAsync.when(
      loading: () => const AlertDialog(
        content: SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => AlertDialog(
        title: const Text('Reading reminders'),
        content: const Text('Reminder settings could not be loaded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
      data: (settings) {
        _initialize(settings);

        return AlertDialog(
          title: const Text('Reading reminders'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable reminder'),
                  value: _enabled,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _enabled = value),
                ),
                DropdownButtonFormField<PrayerReminderPrayer>(
                  initialValue: _prayer,
                  decoration: const InputDecoration(labelText: 'Prayer'),
                  items: PrayerReminderPrayer.values
                      .map(
                        (prayer) => DropdownMenuItem(
                          value: prayer,
                          child: Text(prayer.label),
                        ),
                      )
                      .toList(),
                  onChanged: _saving || !_enabled
                      ? null
                      : (value) => setState(() {
                          if (value != null) _prayer = value;
                        }),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Prayer time'),
                  subtitle: Text(_formatTimeOfDay(_prayerTimeMinutes)),
                  trailing: const Icon(Icons.schedule),
                  enabled: !_saving && _enabled,
                  onTap: _saving || !_enabled ? null : _pickPrayerTime,
                ),
                DropdownButtonFormField<int>(
                  initialValue: _offsetMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Reminder after',
                  ),
                  items: const [0, 5, 10, 15, 20, 30, 45, 60]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            minutes == 0 ? 'At prayer time' : '$minutes min',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _saving || !_enabled
                      ? null
                      : (value) => setState(() {
                          if (value != null) _offsetMinutes = value;
                        }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _snoozeMinutes,
                  decoration: const InputDecoration(labelText: 'Snooze'),
                  items: const [5, 10, 15, 30, 45, 60]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text('$minutes min'),
                        ),
                      )
                      .toList(),
                  onChanged: _saving || !_enabled
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
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
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
  const _FeedbackDialog();

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
    return AlertDialog(
      title: const Text('Send feedback'),
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
              decoration: const InputDecoration(
                labelText: 'Feedback',
                hintText: 'Share what would make the app better.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sent anonymously. Do not include private information.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
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
      if (!mounted) return;
      Navigator.of(context).pop();
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Feedback could not be sent. Please try again later.';
        _submitting = false;
      });
    }
  }
}

class _LastReadBanner extends ConsumerWidget {
  final Surah surah;
  final String verseId;

  const _LastReadBanner({required this.surah, required this.verseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseNum = verseId.split(':').elementAtOrNull(1) ?? '';
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReadingScreen(surah: surah, initialVerseId: verseId),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.islamicGreenSubtle,
          border: Border(
            bottom: BorderSide(color: AppTheme.islamicGreenBorder),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book, color: AppTheme.islamicGreen, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue Reading',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.islamicGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${surah.nameEnglish}${verseNum.isNotEmpty ? ' · Verse $verseNum' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.islamicGreen,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarksSection extends ConsumerWidget {
  final List<Bookmark> bookmarks;
  final Map<int, Surah> surahsByNumber;

  const _BookmarksSection({
    required this.bookmarks,
    required this.surahsByNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.cream,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Bookmarks',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...bookmarks.map(
            (bookmark) => _BookmarkRow(
              bookmark: bookmark,
              surah: _surahForBookmark(bookmark),
            ),
          ),
        ],
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

  const _BookmarkRow({required this.bookmark, required this.surah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseNum = bookmark.verseId.split(':').elementAtOrNull(1) ?? '';
    final title =
        surah?.nameEnglish ?? 'Surah ${bookmark.verseId.split(':').first}';

    return InkWell(
      onTap: surah == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReadingScreen(
                  surah: surah!,
                  initialVerseId: bookmark.verseId,
                ),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Remove bookmark',
              icon: const Icon(Icons.bookmark, color: AppTheme.islamicGreen),
              onPressed: () => _removeBookmark(context, ref),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '$title${verseNum.isNotEmpty ? ' · Verse $verseNum' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 18,
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
