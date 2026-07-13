import 'package:flutter/material.dart';

class AppTheme {
  static const Color cream = Color(0xFFFFF9F0);
  static const Color mushafBackground = Color(0xFFFFF4CB);
  static const Color mushafPage = Color(0xFFFFFBF2);
  static const Color islamicGreen = Color(0xFF2E7D32);
  static const Color goldAccent = Color(0xFFB8860B);
  static const Color classicAyahMarker = Color(0xFF8A6508);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);
  static const Color divider = Color(0xFFE8DCC8);
  // Tinted badge backgrounds: islamicGreen at ~8% opacity (fill) and ~24% (border).
  static const Color islamicGreenSubtle = Color(0x142E7D32);
  static const Color islamicGreenBorder = Color(0x3C2E7D32);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkDivider = Color(0xFF2C2C2E);
  static const Color darkIslamicGreenSubtle = Color(0x1A4A7A2E);
  static const Color darkIslamicGreenBorder = Color(0x4D2E7D32);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: islamicGreen,
      brightness: Brightness.light,
      surface: cream,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: islamicGreen,
      brightness: Brightness.dark,
      surface: const Color(0xFF1C1C1E),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1C1C1E),
      foregroundColor: const Color(0xFFF5F5F5),
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: TextTheme(
      headlineLarge: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF5F5F5),
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF5F5F5),
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF5F5F5),
      ),
      bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFFF5F5F5)),
      bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
      bodySmall: const TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
    ),
  );
}
