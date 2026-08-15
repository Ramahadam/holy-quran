import 'package:flutter/material.dart';

class HomeDialog extends StatelessWidget {
  final Key dialogKey;
  final Key headerKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget content;
  final List<Widget> actions;

  const HomeDialog({
    super.key,
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

class HomeDialogNotice extends StatelessWidget {
  final Key noticeKey;
  final IconData icon;
  final String text;

  const HomeDialogNotice({
    super.key,
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

InputDecoration homeDialogInputDecoration(
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
      borderSide: BorderSide(color: colors.outline),
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
