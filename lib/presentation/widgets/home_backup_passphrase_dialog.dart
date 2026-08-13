import 'package:flutter/material.dart';

import '../../data/backup/quran_backup_service.dart';
import '../../l10n/l10n.dart';
import 'home_dialog.dart';

enum BackupPassphrasePurpose { save, share, restore }

class HomeBackupPassphraseDialog extends StatefulWidget {
  final BackupPassphrasePurpose purpose;

  const HomeBackupPassphraseDialog({super.key, required this.purpose});

  @override
  State<HomeBackupPassphraseDialog> createState() =>
      _HomeBackupPassphraseDialogState();
}

class _HomeBackupPassphraseDialogState
    extends State<HomeBackupPassphraseDialog> {
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
    final confirm = purpose != BackupPassphrasePurpose.restore;
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final (keyName, icon, title, subtitle, actionLabel) = switch (purpose) {
      BackupPassphrasePurpose.save => (
        'saveBackup',
        Icons.save_alt_rounded,
        l10n.saveBackupToDevice,
        l10n.saveBackupSubtitle,
        l10n.save,
      ),
      BackupPassphrasePurpose.share => (
        'shareBackup',
        Icons.share_outlined,
        l10n.shareBackup,
        l10n.shareBackupSubtitle,
        l10n.share,
      ),
      BackupPassphrasePurpose.restore => (
        'restoreBackup',
        Icons.download_rounded,
        l10n.restoreBackup,
        l10n.restoreBackupSubtitle,
        l10n.replaceAndRestore,
      ),
    };

    return HomeDialog(
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
              decoration: homeDialogInputDecoration(
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
                decoration: homeDialogInputDecoration(
                  context,
                  labelText: l10n.confirmPassphrase,
                  prefixIcon: Icons.lock_outline_rounded,
                ),
              ),
            ],
            const SizedBox(height: 12),
            HomeDialogNotice(
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
    if (widget.purpose != BackupPassphrasePurpose.restore &&
        passphrase.trim().length < minimumBackupPassphraseLength) {
      setState(() {
        _errorText = context.l10n.passphraseTooShort;
      });
      return;
    }
    if (widget.purpose != BackupPassphrasePurpose.restore &&
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
