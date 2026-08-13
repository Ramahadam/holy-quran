import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

enum _HomeMenuAction {
  switchLanguage,
  toggleDarkMode,
  saveBackup,
  shareBackup,
  restoreBackup,
  feedback,
  reminders,
}

class HomeActionsMenu extends StatelessWidget {
  final bool darkModeEnabled;
  final VoidCallback onSwitchLanguage;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onOpenReminders;
  final VoidCallback onSendFeedback;
  final VoidCallback onSaveBackup;
  final VoidCallback onShareBackup;
  final VoidCallback onRestoreBackup;

  const HomeActionsMenu({
    super.key,
    required this.darkModeEnabled,
    required this.onSwitchLanguage,
    required this.onToggleDarkMode,
    required this.onOpenReminders,
    required this.onSendFeedback,
    required this.onSaveBackup,
    required this.onShareBackup,
    required this.onRestoreBackup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<_HomeMenuAction>(
      key: const ValueKey('homeMenuButton'),
      tooltip: l10n.menu,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      color: colors.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      constraints: const BoxConstraints(minWidth: 252, maxWidth: 280),
      onSelected: (action) {
        switch (action) {
          case _HomeMenuAction.switchLanguage:
            onSwitchLanguage();
          case _HomeMenuAction.toggleDarkMode:
            onToggleDarkMode();
          case _HomeMenuAction.reminders:
            onOpenReminders();
          case _HomeMenuAction.feedback:
            onSendFeedback();
          case _HomeMenuAction.saveBackup:
            onSaveBackup();
          case _HomeMenuAction.shareBackup:
            onShareBackup();
          case _HomeMenuAction.restoreBackup:
            onRestoreBackup();
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
    );
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
