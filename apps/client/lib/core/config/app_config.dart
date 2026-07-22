import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
	const AppConfig._();

	static const String _prefsKey = 'api_base_url';

	/// Emulador Android: `http://10.0.2.2:3000/v1`
	/// Web / desktop: localhost.
	/// Dispositivo físico: IP de la PC, hotspot, o `http://127.0.0.1:3000/v1` con adb reverse.
	static const String compileTimeApiBaseUrl = String.fromEnvironment(
		'API_BASE_URL',
		defaultValue: 'http://localhost:3000/v1',
	);

	static String? _override;

	/// URL efectiva (override SharedPreferences o dart-define).
	static String get apiBaseUrl {
		final override = _override?.trim();
		if (override != null && override.isNotEmpty) return override;
		return compileTimeApiBaseUrl;
	}

	static bool get hasOverride {
		final override = _override?.trim();
		return override != null && override.isNotEmpty;
	}

	static Future<void> loadOverride(SharedPreferences prefs) async {
		_override = prefs.getString(_prefsKey);
	}

	/// Guarda o limpia el override. Devuelve la URL efectiva resultante.
	static Future<String> setOverride(
		SharedPreferences prefs,
		String? url,
	) async {
		final trimmed = url?.trim();
		if (trimmed == null || trimmed.isEmpty) {
			await prefs.remove(_prefsKey);
			_override = null;
		} else {
			final normalized = trimmed.endsWith('/')
					? trimmed.substring(0, trimmed.length - 1)
					: trimmed;
			await prefs.setString(_prefsKey, normalized);
			_override = normalized;
		}
		return apiBaseUrl;
	}

	static const String appName = 'GestionMantenimiento';
}
