import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ecdb_colors.dart';
import 'ecdb_typography.dart';

/// Tema completo de ECDB para MaterialApp.
/// Premium vinícola: burdeos + oro + neutros cálidos.
class ECDBTheme {
  ECDBTheme._();

  static ThemeData get light {
    final textTheme = ECDBTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: ECDBColors.wine,
      scaffoldBackgroundColor: ECDBColors.bg,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: ECDBColors.surface,
        foregroundColor: ECDBColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),

      // Cards — border radius 14px, sombras suaves
      cardTheme: CardThemeData(
        color: ECDBColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: ECDBColors.border, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Elevated Buttons — burdeos con radius 14
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ECDBColors.wine,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ECDBColors.wine,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: ECDBColors.wine),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ECDBColors.wine,
          textStyle: textTheme.labelLarge,
        ),
      ),

      // FAB — oro ECDB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ECDBColors.gold,
        foregroundColor: ECDBColors.textPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ECDBColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ECDBColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ECDBColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ECDBColors.wine, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ECDBColors.error),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: ECDBColors.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: ECDBColors.textSecondary),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ECDBColors.surface,
        selectedItemColor: ECDBColors.wine,
        unselectedItemColor: ECDBColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // Bottom Sheet — radius 20px
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ECDBColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: ECDBColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: ECDBColors.bgAlt,
        selectedColor: ECDBColors.wine.withOpacity(0.15),
        labelStyle: textTheme.labelMedium!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: ECDBColors.border),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: ECDBColors.border,
        thickness: 0.5,
        space: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ECDBColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
