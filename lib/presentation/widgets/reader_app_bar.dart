import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double height = 68;

  final String surahName;
  final String contextLabel;
  final String switchModeLabel;
  final IconData switchModeIcon;
  final VoidCallback onSwitchMode;

  const ReaderAppBar({
    super.key,
    required this.surahName,
    required this.contextLabel,
    required this.switchModeLabel,
    required this.switchModeIcon,
    required this.onSwitchMode,
  });

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBar(
      key: const ValueKey('readerAppBar'),
      automaticallyImplyLeading: false,
      toolbarHeight: height,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
      leadingWidth: 64,
      leading: Center(
        child: IconButton(
          key: const ValueKey('readerBackButton'),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
          icon: const BackButtonIcon(),
          style: IconButton.styleFrom(foregroundColor: colors.onSurface),
        ),
      ),
      titleSpacing: 0,
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            surahName,
            key: const ValueKey('readerHeaderSurah'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: AppTheme.quranFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            contextLabel,
            key: const ValueKey('readerHeaderContext'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Center(
            child: TextButton.icon(
              key: const ValueKey('readerModeSwitch'),
              onPressed: onSwitchMode,
              icon: Icon(switchModeIcon, size: 18),
              label: Text(switchModeLabel),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: const StadiumBorder(),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
