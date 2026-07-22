import 'package:flutter/material.dart';

/// Paleta de marca GESTION (Mantenimiento | Stock | Eficiencia).
class AppColors {
	const AppColors._();

	// —— Marca (logo) ——
	/// Mantenimiento — violeta / magenta del hexágono.
	static const Color brandPurple = Color(0xFFC026FF);

	/// Stock — verde lima del logo.
	static const Color brandGreen = Color(0xFF39E639);

	/// Eficiencia — rojo-naranja del logo.
	static const Color brandOrange = Color(0xFFFF3B1F);

	static const Color white = Color(0xFFFFFFFF);
	static const Color black = Color(0xFF000000);

	/// Negro suave para texto principal en tema claro.
	static const Color ink = Color(0xFF1A1A1A);

	/// Violeta más oscuro: texto / bordes sobre fondos claros.
	static const Color brandPurpleDark = Color(0xFF9B1AD9);

	/// Verde más oscuro: contraste en tema claro.
	static const Color brandGreenDark = Color(0xFF1A9E1A);

	// Compat: nombres legacy → nuevos acentos de marca.
	static const Color brandYellow = brandPurple;
	static const Color brandRed = brandOrange;

	// —— Alias de tema ——
	static const Color primary = brandPurple;
	static const Color onPrimary = white;
	static const Color accent = brandOrange;
	static const Color onAccent = white;

	static const Color secondary = Color(0xFF5C5C5C);
	static const Color secondaryLight = Color(0xFF8A8A8A);

	// —— Semánticos ——
	static const Color success = brandGreen;
	static const Color warning = Color(0xFFFF8A1A);
	static const Color danger = brandOrange;

	// —— Superficies ——
	static const Color surfaceLight = white;
	static const Color backgroundLight = Color(0xFFF7F5FA);
	static const Color surfaceDark = Color(0xFF141216);
	static const Color backgroundDark = Color(0xFF000000);
	static const Color cardDark = Color(0xFF141216);
	static const Color cardElevated = Color(0xFF1E1A24);
	static const Color cardBorder = Color(0xFF2E2838);
	static const Color mutedText = Color(0xFF9A94A6);

	/// Panel explorador lateral (tinte violeta suave).
	static const Color explorerPanel = Color(0xFF0E0C12);
	static const Color explorerSelected = Color(0xFF2A1838);
	static const Color surfaceMuted = Color(0xFFF3EFF8);

	// Compatibilidad con código existente
	static const Color primaryDark = brandPurpleDark;
}
