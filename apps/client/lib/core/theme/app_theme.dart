import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
	const AppTheme._();

	static ThemeData light() {
		const scheme = ColorScheme(
			brightness: Brightness.light,
			primary: AppColors.primary,
			onPrimary: AppColors.onPrimary,
			secondary: AppColors.accent,
			onSecondary: AppColors.onAccent,
			error: AppColors.danger,
			onError: AppColors.white,
			surface: AppColors.surfaceLight,
			onSurface: AppColors.ink,
			onSurfaceVariant: AppColors.secondary,
			outline: Color(0xFFE0E0E0),
			outlineVariant: Color(0xFFEEEEEE),
			surfaceContainerHighest: AppColors.surfaceMuted,
			tertiary: AppColors.accent,
			onTertiary: AppColors.white,
		);

		return ThemeData(
			useMaterial3: true,
			colorScheme: scheme,
			scaffoldBackgroundColor: AppColors.backgroundLight,
			iconTheme: const IconThemeData(color: AppColors.ink),
			primaryIconTheme: const IconThemeData(color: AppColors.ink),
			textTheme: GoogleFonts.interTextTheme().apply(
				bodyColor: AppColors.ink,
				displayColor: AppColors.ink,
			),
			listTileTheme: const ListTileThemeData(
				iconColor: AppColors.ink,
				textColor: AppColors.ink,
			),
			tabBarTheme: const TabBarThemeData(
				labelColor: AppColors.ink,
				unselectedLabelColor: AppColors.secondary,
			),
			appBarTheme: const AppBarTheme(
				centerTitle: false,
				elevation: 0,
				backgroundColor: AppColors.white,
				foregroundColor: AppColors.ink,
				iconTheme: IconThemeData(color: AppColors.ink),
				actionsIconTheme: IconThemeData(color: AppColors.ink),
				surfaceTintColor: Colors.transparent,
			),
			cardTheme: CardThemeData(
				elevation: 0,
				color: AppColors.surfaceLight,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(16),
					side: const BorderSide(color: Color(0xFFE8E8E8)),
				),
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: AppColors.white,
				labelStyle: const TextStyle(color: AppColors.secondary),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.primary, width: 2),
				),
			),
			filledButtonTheme: FilledButtonThemeData(
				style: FilledButton.styleFrom(
					backgroundColor: AppColors.primary,
					foregroundColor: AppColors.onPrimary,
					minimumSize: const Size(48, 48),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(12),
					),
				),
			),
			dividerTheme: const DividerThemeData(
				color: Color(0xFFE8E8E8),
				thickness: 1,
			),
		);
	}

	static ThemeData dark() {
		const scheme = ColorScheme(
			brightness: Brightness.dark,
			primary: AppColors.brandYellow,
			onPrimary: AppColors.ink,
			secondary: AppColors.accent,
			onSecondary: AppColors.white,
			error: AppColors.danger,
			onError: AppColors.white,
			surface: AppColors.cardDark,
			onSurface: AppColors.white,
			onSurfaceVariant: AppColors.mutedText,
			outline: AppColors.cardBorder,
			outlineVariant: AppColors.cardBorder,
			surfaceContainerHighest: AppColors.cardElevated,
			tertiary: AppColors.accent,
			onTertiary: AppColors.white,
		);

		final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
			bodyColor: AppColors.white,
			displayColor: AppColors.white,
		);

		return ThemeData(
			useMaterial3: true,
			colorScheme: scheme,
			scaffoldBackgroundColor: AppColors.backgroundDark,
			iconTheme: const IconThemeData(color: AppColors.white),
			primaryIconTheme: const IconThemeData(color: AppColors.white),
			textTheme: base,
			listTileTheme: const ListTileThemeData(
				iconColor: AppColors.white,
				textColor: AppColors.white,
			),
			tabBarTheme: const TabBarThemeData(
				labelColor: AppColors.white,
				unselectedLabelColor: AppColors.mutedText,
			),
			appBarTheme: const AppBarTheme(
				centerTitle: false,
				elevation: 0,
				backgroundColor: AppColors.backgroundDark,
				foregroundColor: AppColors.white,
				iconTheme: IconThemeData(color: AppColors.white),
				actionsIconTheme: IconThemeData(color: AppColors.white),
				surfaceTintColor: Colors.transparent,
			),
			cardTheme: CardThemeData(
				elevation: 0,
				color: AppColors.cardDark,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(16),
					side: const BorderSide(color: AppColors.cardBorder),
				),
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: AppColors.cardElevated,
				hintStyle: TextStyle(color: AppColors.mutedText.withValues(alpha: 0.85)),
				labelStyle: const TextStyle(color: AppColors.mutedText),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.cardBorder),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.cardBorder),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.brandYellow, width: 1.5),
				),
			),
			filledButtonTheme: FilledButtonThemeData(
				style: FilledButton.styleFrom(
					backgroundColor: AppColors.brandYellow,
					foregroundColor: AppColors.ink,
					minimumSize: const Size(48, 44),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(12),
					),
				),
			),
			outlinedButtonTheme: OutlinedButtonThemeData(
				style: OutlinedButton.styleFrom(
					foregroundColor: AppColors.white,
					side: const BorderSide(color: AppColors.cardBorder),
					minimumSize: const Size(48, 44),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(12),
					),
				),
			),
			chipTheme: ChipThemeData(
				backgroundColor: AppColors.cardElevated,
				selectedColor: AppColors.brandYellow.withValues(alpha: 0.15),
				labelStyle: const TextStyle(color: AppColors.white, fontSize: 12),
				secondaryLabelStyle: const TextStyle(color: AppColors.white, fontSize: 12),
				side: const BorderSide(color: AppColors.cardBorder),
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
			),
			dividerTheme: const DividerThemeData(
				color: AppColors.cardBorder,
				thickness: 1,
			),
			navigationBarTheme: NavigationBarThemeData(
				backgroundColor: AppColors.cardDark,
				indicatorColor: AppColors.accent.withValues(alpha: 0.2),
				elevation: 0,
				height: 64,
				labelTextStyle: WidgetStateProperty.resolveWith((states) {
					final selected = states.contains(WidgetState.selected);
					return TextStyle(
						fontSize: 11,
						fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
						color: selected ? AppColors.brandYellow : AppColors.mutedText,
					);
				}),
				iconTheme: WidgetStateProperty.resolveWith((states) {
					final selected = states.contains(WidgetState.selected);
					return IconThemeData(
						color: selected ? AppColors.brandYellow : AppColors.mutedText,
						size: 22,
					);
				}),
			),
			dropdownMenuTheme: DropdownMenuThemeData(
				inputDecorationTheme: InputDecorationTheme(
					filled: true,
					fillColor: AppColors.cardElevated,
					border: OutlineInputBorder(
						borderRadius: BorderRadius.circular(12),
						borderSide: const BorderSide(color: AppColors.cardBorder),
					),
				),
			),
			progressIndicatorTheme: const ProgressIndicatorThemeData(
				color: AppColors.brandYellow,
			),
		);
	}
}
