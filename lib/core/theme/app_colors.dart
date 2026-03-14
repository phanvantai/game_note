import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Light Mode ---
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F3F3);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFF4A4A4A);
  static const Color lightOutline = Color(0xFFE0E0E0);
  static const Color lightPrimary = Color(0xFF2D2D2D);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  // --- Dark Mode ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);
  static const Color darkOnBackground = Color(0xFFF0F0F0);
  static const Color darkOnSurface = Color(0xFFB0B0B0);
  static const Color darkOutline = Color(0xFF3A3A3A);
  static const Color darkPrimary = Color(0xFFF0F0F0);
  static const Color darkOnPrimary = Color(0xFF1A1A1A);

  // --- Shared Accent ---
  static const Color accent = Color(0xFFE8734A);
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
        secondary: accent,
        onSecondary: onAccent,
        tertiary: accent,
        onTertiary: onAccent,
        error: lightError,
        onError: Color(0xFFFFFFFF),
        surface: lightSurface,
        onSurface: lightOnBackground,
        surfaceContainerHighest: lightSurfaceVariant,
        surfaceContainerLow: lightSurfaceVariant,
        outline: lightOutline,
        outlineVariant: Color(0xFFEEEEEE),
      );

  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        secondary: accent,
        onSecondary: onAccent,
        tertiary: accent,
        onTertiary: onAccent,
        error: darkError,
        onError: Color(0xFFFFFFFF),
        surface: darkSurface,
        onSurface: darkOnBackground,
        surfaceContainerHighest: darkSurfaceVariant,
        surfaceContainerLow: darkSurfaceVariant,
        outline: darkOutline,
        outlineVariant: Color(0xFF2E2E2E),
      );
}
