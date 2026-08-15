import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/presentation/theme/app_theme.dart';

void main() {
  group('AppTheme semantic colors', () {
    test(
      'maps light surfaces and interaction states to calm palette roles',
      () {
        final theme = AppTheme.light;
        final colors = theme.colorScheme;

        expect(theme.scaffoldBackgroundColor, AppTheme.appBackground);
        expect(colors.surface, AppTheme.appSurface);
        expect(colors.surfaceContainerLow, AppTheme.surfaceContainer);
        expect(colors.surfaceContainerHigh, AppTheme.elevatedSurface);
        expect(AppTheme.readerPage, isNot(AppTheme.appSurface));
        expect(AppTheme.mushafPaper, isNot(AppTheme.appSurface));
        expect(colors.primary, AppTheme.primaryAction);
        expect(colors.onPrimary, AppTheme.onPrimaryAction);
        expect(colors.primaryContainer, AppTheme.selectedSurface);
        expect(colors.onPrimaryContainer, AppTheme.onSelectedSurface);
        expect(colors.onSurface, AppTheme.primaryText);
        expect(colors.onSurfaceVariant, AppTheme.secondaryText);
        expect(colors.outline, AppTheme.controlOutline);
        expect(colors.outlineVariant, AppTheme.subtleDivider);
      },
    );

    test('maps dark surfaces and interaction states to neutral roles', () {
      final theme = AppTheme.dark;
      final colors = theme.colorScheme;

      expect(theme.scaffoldBackgroundColor, AppTheme.darkAppBackground);
      expect(colors.surface, AppTheme.darkAppSurface);
      expect(colors.surfaceContainerLow, AppTheme.darkAppSurface);
      expect(colors.surfaceContainerHigh, AppTheme.darkElevatedSurface);
      expect(colors.primary, AppTheme.darkPrimaryAction);
      expect(colors.onPrimary, AppTheme.darkOnPrimaryAction);
      expect(colors.primaryContainer, AppTheme.darkSelectedSurface);
      expect(colors.onPrimaryContainer, AppTheme.darkOnSelectedSurface);
      expect(colors.onSurface, AppTheme.darkPrimaryText);
      expect(colors.onSurfaceVariant, AppTheme.darkSecondaryText);
      expect(colors.outline, AppTheme.darkControlOutline);
      expect(colors.outlineVariant, AppTheme.darkSubtleDivider);
    });

    test(
      'normal text, actions, and essential boundaries meet WCAG contrast',
      () {
        expect(
          _contrast(AppTheme.primaryText, AppTheme.appBackground),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(AppTheme.secondaryText, AppTheme.appSurface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(AppTheme.onPrimaryAction, AppTheme.primaryAction),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(AppTheme.onSelectedSurface, AppTheme.selectedSurface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(AppTheme.controlOutline, AppTheme.appSurface),
          greaterThanOrEqualTo(3),
        );

        expect(
          _contrast(AppTheme.darkPrimaryText, AppTheme.darkAppBackground),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(AppTheme.darkSecondaryText, AppTheme.darkAppSurface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(AppTheme.darkOnPrimaryAction, AppTheme.darkPrimaryAction),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(
            AppTheme.darkOnSelectedSurface,
            AppTheme.darkSelectedSurface,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(AppTheme.darkControlOutline, AppTheme.darkAppSurface),
          greaterThanOrEqualTo(3),
        );
      },
    );

    test('keeps large light surfaces below near-white glare levels', () {
      final backgroundLuminance = AppTheme.appBackground.computeLuminance();
      final surfaceLuminance = AppTheme.appSurface.computeLuminance();
      final containerLuminance = AppTheme.surfaceContainer.computeLuminance();
      final readerLuminance = AppTheme.readerPage.computeLuminance();

      expect(backgroundLuminance, lessThanOrEqualTo(.86));
      expect(surfaceLuminance, lessThanOrEqualTo(.91));
      expect(readerLuminance, lessThanOrEqualTo(.93));
      expect(containerLuminance, lessThan(surfaceLuminance));
      expect(backgroundLuminance, lessThan(surfaceLuminance));
    });

    test('Quranic accents remain distinct and readable on the reader page', () {
      expect(AppTheme.quranGold, isNot(AppTheme.primaryAction));
      expect(AppTheme.quranRed, isNot(AppTheme.primaryAction));
      expect(
        _contrast(AppTheme.quranGold, AppTheme.readerPage),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(AppTheme.quranAyahMarker, AppTheme.readerPage),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(AppTheme.quranRed, AppTheme.readerPage),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = lighter == foreground ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
