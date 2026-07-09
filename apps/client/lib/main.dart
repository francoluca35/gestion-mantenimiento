import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'features/auth/application/auth_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
	WidgetsFlutterBinding.ensureInitialized();
	final prefs = await SharedPreferences.getInstance();

	try {
		await Firebase.initializeApp(
			options: DefaultFirebaseOptions.currentPlatform,
		);
	} catch (_) {
		// Si falla la init, la app sigue (FCM quedará deshabilitado).
	}

	runApp(
		ProviderScope(
			overrides: [
				sharedPreferencesProvider.overrideWithValue(prefs),
			],
			child: const GestionMantenimientoApp(),
		),
	);
}
