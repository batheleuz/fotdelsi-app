import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Échelle typographique de l'application, basée sur Poppins.
abstract final class AppTypography {
  const AppTypography._();

  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.2,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.25,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.3,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.6,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.6,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.onPrimary,
    ),
  );
}
