import 'package:flutter/material.dart';

class QuranIndexTile extends StatelessWidget {
  final String keyPrefix;
  final int number;
  final String title;
  final String subtitle;
  final String? arabicTitle;
  final String semanticsLabel;
  final VoidCallback onTap;

  const QuranIndexTile({
    super.key,
    required this.keyPrefix,
    required this.number,
    required this.title,
    required this.subtitle,
    this.arabicTitle,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        key: ValueKey('${keyPrefix}Card-$number'),
        color: Theme.of(context).scaffoldBackgroundColor,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              child: Row(
                children: [
                  _NumberBadge(
                    badgeKey: ValueKey('${keyPrefix}NumberBadge-$number'),
                    number: number,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          textDirection: _containsArabic(title)
                              ? TextDirection.rtl
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (arabicTitle != null) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 2,
                      child: Text(
                        arabicTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.end,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
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

bool _containsArabic(String value) =>
    RegExp(r'[\u0600-\u06FF]').hasMatch(value);

class _NumberBadge extends StatelessWidget {
  final Key badgeKey;
  final int number;

  const _NumberBadge({required this.badgeKey, required this.number});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      key: badgeKey,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
