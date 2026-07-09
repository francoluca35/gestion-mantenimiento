import 'package:flutter/material.dart';

/// Paleta corporativa Sika + neutros y semánticos de OT.
class AppColors {
  const AppColors._();

  // —— Marca Sika ——
  static const Color brandYellow = Color(0xFFFFB11B);
  static const Color brandRed = Color(0xFFE30613);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Negro suave para texto principal (mejor lectura que #000 puro).
  static const Color ink = Color(0xFF1A1A1A);

  // —— Alias de tema ——
  static const Color primary = brandYellow;
  static const Color onPrimary = ink;
  static const Color accent = brandRed;
  static const Color onAccent = white;

  static const Color secondary = Color(0xFF5C5C5C);
  static const Color secondaryLight = Color(0xFF8A8A8A);

  // —— Semánticos OT (SGwing-17) ——
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFE6A000);
  static const Color danger = brandRed;

  // —— Superficies ——
  static const Color surfaceLight = white;
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color cardDark = Color(0xFF1A1A1A);
  static const Color cardElevated = Color(0xFF242424);
  static const Color cardBorder = Color(0xFF2E2E2E);
  static const Color mutedText = Color(0xFF8A8A8A);

  /// Panel explorador lateral (sin tinte azul).
  static const Color explorerPanel = Color(0xFF131313);
  static const Color explorerSelected = Color(0xFF3A3530);
  static const Color surfaceMuted = Color(0xFFF5F5F5);

  // Compatibilidad con código existente
  static const Color primaryDark = brandYellow;
}
