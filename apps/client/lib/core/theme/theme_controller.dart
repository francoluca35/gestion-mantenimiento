import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/application/auth_controller.dart';

const _themeModeKey = 'app_theme_mode';

class ThemeController extends StateNotifier<ThemeMode> {
	ThemeController(this._prefs) : super(_read(_prefs));

	final SharedPreferences _prefs;

	static ThemeMode _read(SharedPreferences prefs) {
		final raw = prefs.getString(_themeModeKey);
		return switch (raw) {
			'light' => ThemeMode.light,
			'dark' => ThemeMode.dark,
			'system' => ThemeMode.system,
			_ => ThemeMode.dark,
		};
	}

	Future<void> setMode(ThemeMode mode) async {
		state = mode;
		final value = switch (mode) {
			ThemeMode.light => 'light',
			ThemeMode.dark => 'dark',
			ThemeMode.system => 'system',
		};
		await _prefs.setString(_themeModeKey, value);
	}

	Future<void> toggleLightDark() async {
		await setMode(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
	}
}

final themeControllerProvider =
		StateNotifierProvider<ThemeController, ThemeMode>((ref) {
	return ThemeController(ref.watch(sharedPreferencesProvider));
});
