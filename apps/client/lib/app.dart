import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_page.dart';

class GestionMantenimientoApp extends ConsumerWidget {
	const GestionMantenimientoApp({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final router = GoRouter(
			initialLocation: '/login',
			routes: [
				GoRoute(
					path: '/login',
					builder: (context, state) => const LoginPage(),
				),
				GoRoute(
					path: '/home',
					builder: (context, state) => const HomePage(),
				),
			],
		);

		return MaterialApp.router(
			title: AppConfig.appName,
			debugShowCheckedModeBanner: false,
			theme: AppTheme.light(),
			darkTheme: AppTheme.dark(),
			themeMode: ThemeMode.system,
			routerConfig: router,
		);
	}
}
