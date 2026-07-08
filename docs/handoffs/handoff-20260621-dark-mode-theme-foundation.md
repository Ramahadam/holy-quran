# Handoff: Dark Mode Theme Foundation (Issue #47)

Date: 2026-06-21
Repository: `/Users/ram/Desktop/Holy Quran`

## Focus

Implement dark mode theme foundation for the Holy Quran app. Core screens must remain
legible in dark mode while respecting Mushaf mode's design integrity.

## Completed Work

### Theme Layer (`lib/presentation/theme/app_theme.dart`)
- Added dark theme colors: `darkBackground`, `darkSurface`, `darkTextPrimary`, `darkTextSecondary`, `darkDivider`, `darkIslamicGreenSubtle`, `darkIslamicGreenBorder`
- Added `ThemeData get dark` theme definition with Material 3 color scheme

### App Configuration (`lib/presentation/app.dart`)
- Added `darkTheme: AppTheme.dark` and `themeMode: ThemeMode.system` to MaterialApp
- Updated DatabaseErrorApp to use theme-aware background and text colors

### Screens Updated for Dark Mode Awareness
- `loading_screen.dart`: Background uses `Theme.of(context).scaffoldBackgroundColor`; secondary text uses theme textMedium
- `home_screen.dart`: Updated _LastReadBanner, _BookmarksSection, _BookmarkRow to use `colorScheme.primaryContainer`, `dividerColor`, `colorScheme.primary`, `colorScheme.onSurfaceVariant`
- `reading_screen.dart`: Updated _BismillahHeader, _SurahHeader, _ArabicVerse, _QuranPageContent for theme awareness
- `verse_detail_screen.dart`: Background, text styling, and _VerseBadge use theme tokens (`primaryContainer`, `onPrimaryContainer`)

### Widgets Updated for Dark Mode Awareness
- `verse_card.dart`: Text styles and _VerseNumber use theme tokens
- `surah_tile.dart`: _SurahNumber uses theme's primary color

### Test Updates
- Updated widget tests to use theme-aware color expectations
- All 44 widget tests pass
- `flutter analyze` passes with no issues

## Files Modified

```
lib/presentation/app.dart
lib/presentation/theme/app_theme.dart
lib/presentation/screens/loading_screen.dart
lib/presentation/screens/home_screen.dart
lib/presentation/screens/reading_screen.dart
lib/presentation/screens/verse_detail_screen.dart
lib/presentation/widgets/verse_card.dart
lib/presentation/widgets/surah_tile.dart
test/widget_test.dart
test/anonymous_feedback_test.dart
```

## Pending Work (Issue #48)

Per the issue requirements and handoff guidance, issue #48 ("Apply dark mode to Quran reading experiences")
is marked HITL (human-in-the-loop) because:

1. **Mushaf mode**: Dark Mushaf is a design decision, not only a technical one. Inverting or recoloring
   Mushaf-style content may reduce sacred-page familiarity. The MushafSamplePage retains its hardcoded
   Mushaf-specific colors.

2. **Visual review needed**: The theme colors should be visually reviewed on device before finalizing
   Mushaf dark mode. Consider:
   - `MushafSamplePage` overlay widget colors (page number badge)
   - Any other Mushaf-specific UI elements

## Implementation Notes

- Used Material 3 semantic tokens: `primaryContainer` for badge/accent backgrounds, `onPrimaryContainer`
  for text on those backgrounds
- Removed unused imports after theme token migration
- Tests updated to use `MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, ...)` instead of
  hardcoded color assertions

## Verification Commands

```bash
flutter analyze
flutter test test/widget_test.dart
```

## Next Steps

Issue #47 is complete. For issue #48:
1. Perform visual review on device
2. Decide whether to apply dark mode to Mushaf-specific elements
3. Update MushafSamplePage if dark mode is approved for that mode