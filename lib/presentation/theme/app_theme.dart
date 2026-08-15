import 'package:flutter/material.dart';

class AppTheme {
  static const String quranFontFamily = 'KFGQPCHafsUthmanicScript';

  // Light semantic roles.
  static const Color appBackground = Color(0xFFFFF9F0);
  static const Color appSurface = Color(0xFFFFFBF2);
  static const Color readerPage = appSurface;
  static const Color mushafPaper = Color(0xFFFFF4CB);
  static const Color surfaceContainer = Color(0xFFFCF6EB);
  static const Color elevatedSurface = Color(0xFFF7EFE2);
  static const Color highestSurface = Color(0xFFF1E7D8);
  static const Color dimSurface = Color(0xFFF2EADF);

  static const Color primaryAction = Color(0xFF2E7D32);
  static const Color onPrimaryAction = Color(0xFFFFFFFF);
  static const Color selectedSurface = Color(0xFFE6F0E4);
  static const Color onSelectedSurface = Color(0xFF1C4C20);

  static const Color primaryText = Color(0xFF1A1A1A);
  static const Color secondaryText = Color(0xFF555555);
  static const Color controlOutline = Color(0xFF756B5C);
  static const Color subtleDivider = Color(0xFFE8DCC8);

  // Quranic accents stay separate from application interaction colors.
  static const Color quranGold = Color(0xFFB8860B);
  static const Color quranAyahMarker = Color(0xFFA87400);
  static const Color quranRed = Color(0xFFB34437);
  static const Color bookmarkHighlight = Color(0x332E7D32);

  // Dark semantic roles remain neutral; green still indicates interaction.
  static const Color darkAppBackground = Color(0xFF121212);
  static const Color darkAppSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceContainer = Color(0xFF202023);
  static const Color darkElevatedSurface = Color(0xFF242428);
  static const Color darkHighestSurface = Color(0xFF29292E);
  static const Color darkPrimaryAction = Color(0xFF8BC985);
  static const Color darkOnPrimaryAction = Color(0xFF102B13);
  static const Color darkSelectedSurface = Color(0xFF213523);
  static const Color darkOnSelectedSurface = Color(0xFFD8E8D5);
  static const Color darkPrimaryText = Color(0xFFF5F5F5);
  static const Color darkSecondaryText = Color(0xFFB8B8B8);
  static const Color darkControlOutline = Color(0xFF8E8E93);
  static const Color darkSubtleDivider = Color(0xFF2C2C2E);

  static final ColorScheme _lightColors =
      ColorScheme.fromSeed(
        seedColor: primaryAction,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryAction,
        onPrimary: onPrimaryAction,
        primaryContainer: selectedSurface,
        onPrimaryContainer: onSelectedSurface,
        surface: appSurface,
        onSurface: primaryText,
        onSurfaceVariant: secondaryText,
        outline: controlOutline,
        outlineVariant: subtleDivider,
        surfaceDim: dimSurface,
        surfaceBright: appSurface,
        surfaceContainerLowest: appSurface,
        surfaceContainerLow: appSurface,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: elevatedSurface,
        surfaceContainerHighest: highestSurface,
      );

  static final ColorScheme _darkColors =
      ColorScheme.fromSeed(
        seedColor: darkPrimaryAction,
        brightness: Brightness.dark,
      ).copyWith(
        primary: darkPrimaryAction,
        onPrimary: darkOnPrimaryAction,
        primaryContainer: darkSelectedSurface,
        onPrimaryContainer: darkOnSelectedSurface,
        surface: darkAppSurface,
        onSurface: darkPrimaryText,
        onSurfaceVariant: darkSecondaryText,
        outline: darkControlOutline,
        outlineVariant: darkSubtleDivider,
        surfaceDim: darkAppBackground,
        surfaceBright: darkHighestSurface,
        surfaceContainerLowest: darkAppBackground,
        surfaceContainerLow: darkAppSurface,
        surfaceContainer: darkSurfaceContainer,
        surfaceContainerHigh: darkElevatedSurface,
        surfaceContainerHighest: darkHighestSurface,
      );

  static ThemeData get light => _theme(
    colors: _lightColors,
    background: appBackground,
    primaryTextColor: primaryText,
    secondaryTextColor: secondaryText,
  );

  static ThemeData get dark => _theme(
    colors: _darkColors,
    background: darkAppBackground,
    primaryTextColor: darkPrimaryText,
    secondaryTextColor: darkSecondaryText,
  );

  static ThemeData _theme({
    required ColorScheme colors,
    required Color background,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: colors,
      dividerColor: colors.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: primaryTextColor),
        bodyMedium: TextStyle(fontSize: 14, color: secondaryTextColor),
        bodySmall: TextStyle(fontSize: 12, color: secondaryTextColor),
      ),
    );
  }
}
