import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecdb_colors.dart';

/// Tipografía ECDB.
/// - Cuerpo: Inter (legibilidad máxima)
/// - Títulos destacados: Cormorant Garamond (elegancia vinícola)
/// - Datos/números: Inter tabular figures
class ECDBTypography {
  ECDBTypography._();

  static TextTheme get textTheme {
    final inter = GoogleFonts.interTextTheme();
    final cormorant = GoogleFonts.cormorantGaramondTextTheme();

    return TextTheme(
      // Títulos con serif elegante
      displayLarge: cormorant.displayLarge!.copyWith(
        color: ECDBColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 32,
      ),
      displayMedium: cormorant.displayMedium!.copyWith(
        color: ECDBColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 28,
      ),
      displaySmall: cormorant.displaySmall!.copyWith(
        color: ECDBColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),

      // Headings con serif
      headlineLarge: cormorant.headlineLarge!.copyWith(
        color: ECDBColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
      ),
      headlineMedium: cormorant.headlineMedium!.copyWith(
        color: ECDBColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineSmall: inter.headlineSmall!.copyWith(
        color: ECDBColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),

      // Títulos de sección con sans-serif
      titleLarge: inter.titleLarge!.copyWith(
        color: ECDBColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: inter.titleMedium!.copyWith(
        color: ECDBColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: inter.titleSmall!.copyWith(
        color: ECDBColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),

      // Cuerpo
      bodyLarge: inter.bodyLarge!.copyWith(
        color: ECDBColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: inter.bodyMedium!.copyWith(
        color: ECDBColors.textPrimary,
        fontSize: 14,
      ),
      bodySmall: inter.bodySmall!.copyWith(
        color: ECDBColors.textSecondary,
        fontSize: 12,
      ),

      // Labels
      labelLarge: inter.labelLarge!.copyWith(
        color: ECDBColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: inter.labelMedium!.copyWith(
        color: ECDBColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: inter.labelSmall!.copyWith(
        color: ECDBColors.textMuted,
        fontWeight: FontWeight.w500,
        fontSize: 11,
      ),
    );
  }
}
