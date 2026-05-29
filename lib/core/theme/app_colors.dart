import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // coverage:ignore-line

  // --- Light Mode ---
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF4F4F5);
  static const Color lightOnBackground = Color(0xFF111827);
  static const Color lightOnSurface = Color(0xFF52525B);
  static const Color lightOutline = Color(0xFFE4E4E7);
  static const Color lightPrimary = Color(0xFF111827);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  // --- Dark Mode ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1B1B1D);
  static const Color darkSurfaceVariant = Color(0xFF262629);
  static const Color darkOnBackground = Color(0xFFE7E5E0);
  static const Color darkOnSurface = Color(0xFFBDBAB4);
  static const Color darkOutline = Color(0xFF333336);
  static const Color darkPrimary = Color(0xFFE7E5E0);
  static const Color darkOnPrimary = Color(0xFF121212);

  // --- Shared Accent ---
  static const Color accent = Color(0xFF111827);
  static const Color onAccent = Color(0xFFFFFFFF);

  // --- Semantic Colors (light) ---
  static const Color lightSuccess = Color(0xFF4CAF50);
  static const Color lightError = Color(0xFFE53935);
  static const Color lightWarning = Color(0xFFFFA726);

  // --- Semantic Colors (dark) ---
  static const Color darkSuccess = Color(0xFF66BB6A);
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkWarning = Color(0xFFFFB74D);

  /// Get success color based on current brightness.
  static Color success(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSuccess
        : lightSuccess;
  }

  /// Get warning color based on current brightness.
  static Color warning(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkWarning
        : lightWarning;
  }

  static ColorScheme get lightColorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    primaryContainer: lightSurfaceVariant,
    onPrimaryContainer: lightOnBackground,
    secondary: accent,
    onSecondary: onAccent,
    secondaryContainer: lightSurfaceVariant,
    onSecondaryContainer: lightOnBackground,
    tertiary: accent,
    onTertiary: onAccent,
    tertiaryContainer: lightSurfaceVariant,
    onTertiaryContainer: lightOnBackground,
    error: lightError,
    onError: Color(0xFFFFFFFF),
    surface: lightSurface,
    onSurface: lightOnBackground,
    surfaceContainerHighest: lightSurfaceVariant,
    surfaceContainerLow: lightSurfaceVariant,
    outline: lightOutline,
    outlineVariant: Color(0xFFF4F4F5),
  );

  static ColorScheme get darkColorScheme => const ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    primaryContainer: darkSurfaceVariant,
    onPrimaryContainer: darkOnBackground,
    secondary: darkPrimary,
    onSecondary: darkOnPrimary,
    secondaryContainer: darkSurfaceVariant,
    onSecondaryContainer: darkOnBackground,
    tertiary: darkPrimary,
    onTertiary: darkOnPrimary,
    tertiaryContainer: darkSurfaceVariant,
    onTertiaryContainer: darkOnBackground,
    error: darkError,
    onError: Color(0xFFFFFFFF),
    surface: darkSurface,
    onSurface: darkOnBackground,
    surfaceContainerHighest: darkSurfaceVariant,
    surfaceContainerLow: darkSurfaceVariant,
    outline: darkOutline,
    outlineVariant: Color(0xFF262629),
  );
}
