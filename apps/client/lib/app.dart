import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/seguridad/presentation/perfiles_page.dart';
import 'features/seguridad/presentation/sucursales_page.dart';
import 'features/seguridad/presentation/usuarios_page.dart';

class GestionMantenimientoApp extends ConsumerWidget {
	const GestionMantenimientoApp({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final auth = ref.watch(authControllerProvider);

		final router = ref.watch(_routerProvider);

		if (!auth.bootstrapped) {
			return MaterialApp(
				title: AppConfig.appName,
				debugShowCheckedModeBanner: false,
				theme: AppTheme.light(),
				home: const Scaffold(
					body: Center(child: CircularProgressIndicator()),
				),
			);
		}

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

final _routerProvider = Provider<GoRouter>((ref) {
	final refresh = ValueNotifier<int>(0);
	ref.listen(authControllerProvider, (_, __) {
		refresh.value++;
	});
	ref.onDispose(refresh.dispose);

	return GoRouter(
		initialLocation: '/login',
		refreshListenable: refresh,
		redirect: (context, state) {
			final auth = ref.read(authControllerProvider);
			if (!auth.bootstrapped) return null;

			final loggingIn = state.matchedLocation == '/login';
			final isAuth = auth.isAuthenticated;

			if (!isAuth && !loggingIn) return '/login';
			if (isAuth && loggingIn) return '/home';
			return null;
		},
		routes: [
			GoRoute(
				path: '/login',
				builder: (context, state) => const LoginPage(),
			),
			GoRoute(
				path: '/home',
				builder: (context, state) => const HomePage(),
			),
			GoRoute(
				path: '/usuarios',
				builder: (context, state) => const UsuariosPage(),
			),
			GoRoute(
				path: '/perfiles',
				builder: (context, state) => const PerfilesPage(),
			),
			GoRoute(
				path: '/sucursales',
				builder: (context, state) => const SucursalesPage(),
			),
		],
	);
});
