import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/core/theme/app_colors.dart';
import 'package:pes_arena/core/theme/app_theme.dart';

void main() {
  test('AppColors uses Mono Ink light palette', () {
    expect(AppColors.lightBackground, const Color(0xFFFAFAFA));
    expect(AppColors.lightSurface, const Color(0xFFFFFFFF));
    expect(AppColors.lightSurfaceVariant, const Color(0xFFF4F4F5));
    expect(AppColors.lightOnBackground, const Color(0xFF111827));
    expect(AppColors.lightOnSurface, const Color(0xFF52525B));
    expect(AppColors.lightOutline, const Color(0xFFE4E4E7));
    expect(AppColors.lightPrimary, const Color(0xFF111827));
    expect(AppColors.accent, const Color(0xFF111827));
  });

  test('AppColors uses contrast-safe Mono Ink dark palette', () {
    final scheme = AppColors.darkColorScheme;

    expect(AppColors.darkBackground, const Color(0xFF121212));
    expect(scheme.surface, const Color(0xFF1B1B1D));
    expect(scheme.primary, const Color(0xFFE7E5E0));
    expect(scheme.onPrimary, const Color(0xFF121212));
    expect(scheme.primaryContainer, const Color(0xFF262629));
    expect(scheme.onPrimaryContainer, const Color(0xFFE7E5E0));
    expect(scheme.secondary, const Color(0xFFE7E5E0));
    expect(scheme.onSecondary, const Color(0xFF121212));
    expect(scheme.secondaryContainer, const Color(0xFF262629));
    expect(scheme.onSecondaryContainer, const Color(0xFFE7E5E0));
  });

  test('AppTheme keeps navigation monochrome and low elevation', () {
    final theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, const Color(0xFFFAFAFA));
    expect(theme.colorScheme.primary, const Color(0xFF111827));
    expect(theme.navigationBarTheme.elevation, 0);
    expect(theme.navigationBarTheme.indicatorColor, const Color(0xFFF4F4F5));
    expect(theme.navigationBarTheme.labelTextStyle?.resolve({})?.fontSize, 12);
    expect(theme.cardTheme.elevation, 0);
  });

  test(
    'AppTheme resolves navigation bar styles for selected and unselected states',
    () {
      final lightNavTheme = AppTheme.light.navigationBarTheme;
      final darkNavTheme = AppTheme.dark.navigationBarTheme;

      expect(
        lightNavTheme.labelTextStyle?.resolve({WidgetState.selected})?.color,
        AppTheme.light.colorScheme.onSurface,
      );
      expect(
        lightNavTheme.labelTextStyle?.resolve({})?.color,
        AppColors.lightOnSurface,
      );
      expect(
        darkNavTheme.labelTextStyle?.resolve({})?.color,
        AppColors.darkOnSurface,
      );

      expect(
        lightNavTheme.iconTheme?.resolve({WidgetState.selected})?.color,
        AppTheme.light.colorScheme.onSurface,
      );
      expect(lightNavTheme.iconTheme?.resolve({})?.size, 22);
      expect(
        lightNavTheme.iconTheme?.resolve({})?.color,
        AppColors.lightOnSurface,
      );
      expect(
        darkNavTheme.iconTheme?.resolve({})?.color,
        AppColors.darkOnSurface,
      );
    },
  );

  test(
    'AppTheme resolves switch theme states for both selected and unselected',
    () {
      final lightSwitchTheme = AppTheme.light.switchTheme;
      final darkSwitchTheme = AppTheme.dark.switchTheme;

      expect(
        lightSwitchTheme.thumbColor?.resolve({WidgetState.selected}),
        AppTheme.light.colorScheme.primary,
      );
      expect(
        lightSwitchTheme.thumbColor?.resolve({}),
        AppColors.lightOnSurface,
      );
      expect(
        lightSwitchTheme.trackColor?.resolve({WidgetState.selected}),
        AppTheme.light.colorScheme.primary.withValues(alpha: 0.28),
      );
      expect(
        lightSwitchTheme.trackColor?.resolve({}),
        AppTheme.light.colorScheme.outline,
      );

      expect(
        darkSwitchTheme.thumbColor?.resolve({WidgetState.selected}),
        AppTheme.dark.colorScheme.primary,
      );
      expect(darkSwitchTheme.thumbColor?.resolve({}), AppColors.darkOnSurface);
      expect(
        darkSwitchTheme.trackColor?.resolve({WidgetState.selected}),
        AppTheme.dark.colorScheme.primary.withValues(alpha: 0.28),
      );
      expect(
        darkSwitchTheme.trackColor?.resolve({}),
        AppTheme.dark.colorScheme.outline,
      );
    },
  );
}
