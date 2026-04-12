import 'package:flutter/material.dart';

/// Paleta de colores oficial de En Copa de Balón.
/// Diseñada para transmitir premium vinícola, no app corporativa genérica.
class ECDBColors {
  ECDBColors._();

  // ── Primarios (Burdeos / Wine) ──
  static const wine = Color(0xFF722F37);
  static const wineLight = Color(0xFF8B4049);
  static const wineDark = Color(0xFF5A252C);

  // ── Acentos (Oro) ──
  static const gold = Color(0xFFD4B974);
  static const goldLight = Color(0xFFE8D5A3);

  // ── Neutros cálidos ──
  static const bg = Color(0xFFFAF8F5);
  static const bgAlt = Color(0xFFF0EDE1);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1E1E1E);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textMuted = Color(0xFF9B9B9B);
  static const border = Color(0xFFE5E2DB);

  // ── Semánticos ──
  static const success = Color(0xFF4CAF50);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFF8E1);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFDECEC);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFEBF5FF);

  // ── MaterialColor para el tema ──
  static const MaterialColor wineSwatch = MaterialColor(
    0xFF722F37,
    <int, Color>{
      50: Color(0xFFF5E6E8),
      100: Color(0xFFE6C1C5),
      200: Color(0xFFD5989E),
      300: Color(0xFFC46F77),
      400: Color(0xFFB8505A),
      500: Color(0xFFAB313D),
      600: Color(0xFF9C2C37),
      700: Color(0xFF8B4049),
      800: Color(0xFF722F37),
      900: Color(0xFF5A252C),
    },
  );
}
