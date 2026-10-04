import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  final VoidCallback onOpenReminders;
  final VoidCallback onSaveBackup;
  final VoidCallback onShareBackup;
  final VoidCallback onRestoreBackup;
  final VoidCallback onSendFeedback;

  const SettingsScreen({
    super.key,
    required this.onOpenReminders,
    required this.onSaveBackup,
    required this.onShareBackup,
    required this.onRestoreBackup,
    required this.onSendFeedback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final locale = ref.watch(appLocaleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        key: const ValueKey('settingsList'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l10n.settingsSubtitle, style: theme.textTheme.bodyMedium),
          _section(context, l10n.appearanceAndLanguage),
          _SettingsGroup(
            children: [
              SwitchListTile(
                key: const ValueKey('settingsDarkMode'),
                secondary: Icon(CupertinoIcons.moon, color: colors.primary),
                title: Text(l10n.darkMode),
                value: dark,
                onChanged: (enabled) => unawaited(
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light),
                ),
              ),
              ListTile(
                key: const ValueKey('settingsLanguage'),
                leading: Icon(CupertinoIcons.globe, color: colors.primary),
                title: Text(l10n.appLanguage),
                subtitle: Text(
                  locale.languageCode == 'ar'
                      ? l10n.languageArabic
                      : l10n.languageEnglish,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => unawaited(
                  ref
                      .read(appLocaleProvider.notifier)
                      .setLocale(
                        locale.languageCode == 'ar'
                            ? const Locale('en')
                            : const Locale('ar'),
                      ),
                ),
              ),
            ],
          ),
          _section(context, l10n.readingSettings),
          _SettingsGroup(
            children: [
              _action(
                context,
                'reminders',
                CupertinoIcons.bell,
                l10n.readingReminders,
                onOpenReminders,
              ),
            ],
          ),
          _section(context, l10n.yourData),
          _SettingsGroup(
            children: [
              _action(
                context,
                'save',
                CupertinoIcons.arrow_down_to_line,
                l10n.saveBackupToDevice,
                onSaveBackup,
              ),
              _action(
                context,
                'share',
                CupertinoIcons.square_arrow_up,
                l10n.shareBackup,
                onShareBackup,
              ),
              _action(
                context,
                'restore',
                CupertinoIcons.arrow_counterclockwise,
                l10n.restoreBackup,
                onRestoreBackup,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _action(
            context,
            'feedback',
            CupertinoIcons.bubble_left,
            l10n.sendFeedback,
            onSendFeedback,
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
    ),
  );

  Widget _action(
    BuildContext context,
    String action,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => ListTile(
    key: ValueKey('settings-$action'),
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.outlineVariant),
            children[index],
          ],
        ],
      ),
    );
  }
}
