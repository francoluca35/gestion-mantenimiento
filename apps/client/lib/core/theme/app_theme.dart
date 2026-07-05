import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
	const AppTheme._();

	static ThemeData light() {
		final base = ColorScheme.fromSeed(
			seedColor: AppColors.primary,
			brightness: Brightness.light,
		);

		return ThemeData(
			useMaterial3: true,
			colorScheme: base.copyWith(
				primary: AppColors.primary,
				surface: AppColors.surfaceLight,
			),
			scaffoldBackgroundColor: AppColors.backgroundLight,
			textTheme: GoogleFonts.interTextTheme(),
			appBarTheme: const AppBarTheme(
				centerTitle: false,
				elevation: 0,
				backgroundColor: AppColors.surfaceLight,
				foregroundColor: Color(0xFF0F172A),
			),
			cardTheme: CardThemeData(
				elevation: 0,
				color: AppColors.surfaceLight,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(12),
					side: BorderSide(color: Colors.grey.shade200),
				),
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: Colors.white,
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(8),
				),
			),
			filledButtonTheme: FilledButtonThemeData(
				style: FilledButton.styleFrom(
					minimumSize: const Size(48, 48),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(8),
					),
				),
			),
		);
	}

	static ThemeData dark() {
		final base = ColorScheme.fromSeed(
			seedColor: AppColors.primaryDark,
			brightness: Brightness.dark,
		);

		return ThemeData(
			useMaterial3: true,
			colorScheme: base.copyWith(
				primary: AppColors.primaryDark,
				surface: AppColors.surfaceDark,
			),
			scaffoldBackgroundColor: AppColors.backgroundDark,
			textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
			cardTheme: CardThemeData(
				elevation: 0,
				color: AppColors.surfaceDark,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(12),
				),
			),
		);
	}
}
