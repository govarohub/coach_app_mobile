import 'package:flutter/material.dart';

import '../../shared/design_system/colors/app_colors.dart';
import '../../shared/design_system/elevation/app_elevation.dart';
import '../../shared/design_system/radius/app_radius.dart';
import '../../shared/design_system/typography/app_typography.dart';

abstract final class DarkTheme {
  DarkTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondary,
        surface: Color(0xFF1E1E1E),
        error: AppColors.error,
      ),

      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        headlineLarge: AppTypography.headlineLarge,
        titleLarge: AppTypography.titleLarge,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        labelLarge: AppTypography.labelLarge,
      ),

      cardTheme: const CardThemeData(
        elevation: AppElevation.sm,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
        ),
      ),

      appBarTheme: const AppBarTheme(
        elevation: AppElevation.none,
        centerTitle: true,
      ),
    );
  }
}