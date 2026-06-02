import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Thème global de l'application FOT DELSI (Material 3).
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,
      splashColor: AppColors.primaryLight.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
    );
  }
}
