// app_theme.dart file
import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the Material theme used by the application.
class AppTheme {
  /// Creates the light theme with app colors, text styles, and component styles.
  static ThemeData build() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        labelLarge: AppTextStyles.label,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingL, // 32
            vertical: AppSizes.spacingM, // 24 — 20 yerine en yakın token
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.white,
        ),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
    );
  }
}
