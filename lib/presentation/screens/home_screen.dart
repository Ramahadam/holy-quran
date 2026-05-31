import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/surah.dart';
import '../providers/quran_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/surah_tile.dart';
import 'reading_screen.dart';

enum _BackupAction { export, import }

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
          PopupMenuButton<_BackupAction>(
            tooltip: 'Backup',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              switch (action) {
                case _BackupAction.export:
                  _exportBackup(context, ref);
                case _BackupAction.import:
                  _importBackup(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _BackupAction.export,
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Export backup'),
                ),
              ),
              PopupMenuItem(
                value: _BackupAction.import,
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
