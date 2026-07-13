import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/layout/app_shell.dart';
import 'core/notifications/fcm_bootstrap.dart';
import 'core/notifications/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/config_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/home/presentation/perfil_page.dart';
import 'features/mantenimiento/presentation/contadores_page.dart';
import 'features/mantenimiento/presentation/emitir_ot_no_periodica_page.dart';
import 'features/mantenimiento/presentation/emitir_ot_periodica_page.dart';
import 'features/mantenimiento/presentation/ot_necesarias_page.dart';
import 'features/mantenimiento/presentation/mis_ot_page.dart';
import 'features/mantenimiento/presentation/ot_page.dart';
import 'features/mantenimiento/presentation/procedimientos_page.dart';
import 'features/mantenimiento/presentation/solicitudes_trabajo_page.dart';
import 'features/planta/presentation/planta_page.dart';
import 'features/seguridad/presentation/derechos_tree_page.dart';
import 'features/seguridad/presentation/perfil_derechos_page.dart';
import 'features/seguridad/presentation/perfiles_page.dart';
import 'features/seguridad/presentation/sucursales_page.dart';
import 'features/seguridad/presentation/usuarios_page.dart';

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
	return CustomTransitionPage<void>(
		key: state.pageKey,
		child: child,
		transitionDuration: const Duration(milliseconds: 220),
		reverseTransitionDuration: const Duration(milliseconds: 180),
		transitionsBuilder: (context, animation, secondaryAnimation, child) {
			final curved = CurvedAnimation(
				parent: animation,
				curve: Curves.easeOutCubic,
				reverseCurve: Curves.easeInCubic,
			);
			return FadeTransition(
				opacity: curved,
				child: child,
			);
		},
	);
}

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
			themeMode: ThemeMode.dark,
			scaffoldMessengerKey: rootScaffoldMessengerKey,
			routerConfig: router,
			builder: (context, child) => FcmBootstrap(child: child ?? const SizedBox.shrink()),
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
			final user = auth.session?.usuario;
			final loc = state.matchedLocation;

			if (!isAuth && !loggingIn) return '/login';
			if (isAuth && loggingIn) {
				return user?.esTecnico == true ? '/mis-ot' : '/home';
			}

			if (isAuth && user?.esTecnico == true) {
				const permitidas = {'/mis-ot', '/perfil'};
				if (loc == '/home' || !permitidas.contains(loc)) {
					return '/mis-ot';
				}
			}

			return null;
		},
		routes: [
			GoRoute(
				path: '/login',
				builder: (context, state) => const LoginPage(),
			),
			ShellRoute(
				builder: (context, state, child) {
					return AppShell(
						location: state.uri.path,
						child: child,
					);
				},
				routes: [
					GoRoute(
						path: '/home',
						pageBuilder: (context, state) => _fadePage(state, const HomePage()),
					),
					GoRoute(
						path: '/ot',
						pageBuilder: (context, state) => _fadePage(state, const OtPage()),
					),
					GoRoute(
						path: '/mis-ot',
						pageBuilder: (context, state) => _fadePage(state, const MisOtPage()),
					),
					GoRoute(
						path: '/ot/necesarias',
						pageBuilder: (context, state) =>
								_fadePage(state, const OtNecesariasPage()),
					),
					GoRoute(
						path: '/ot/emitir-no-periodica',
						pageBuilder: (context, state) {
							final q = state.uri.queryParameters;
							return _fadePage(
								state,
								EmitirOtNoPeriodicaPage(
									equipoIdInicial: q['equipoId'],
									procedimientoIdInicial: q['procedimientoId'],
									comentariosInicial: q['comentarios'],
									otReferencia: q['otReferencia'],
								),
							);
						},
					),
					GoRoute(
						path: '/ot/emitir-periodica',
						pageBuilder: (context, state) =>
								_fadePage(state, const EmitirOtPeriodicaPage()),
					),
					GoRoute(
						path: '/solicitudes',
						pageBuilder: (context, state) =>
								_fadePage(state, const SolicitudesTrabajoPage()),
					),
					GoRoute(
						path: '/contadores',
						pageBuilder: (context, state) =>
								_fadePage(state, const ContadoresPage()),
					),
					GoRoute(
						path: '/procedimientos',
						pageBuilder: (context, state) =>
								_fadePage(state, const ProcedimientosPage()),
					),
					GoRoute(
						path: '/planta',
						pageBuilder: (context, state) => _fadePage(state, const PlantaPage()),
					),
					GoRoute(
						path: '/config',
						pageBuilder: (context, state) => _fadePage(state, const ConfigPage()),
					),
					GoRoute(
						path: '/perfil',
						pageBuilder: (context, state) => _fadePage(state, const PerfilPage()),
					),
					GoRoute(
						path: '/usuarios',
						pageBuilder: (context, state) => _fadePage(state, const UsuariosPage()),
					),
					GoRoute(
						path: '/perfiles',
						pageBuilder: (context, state) =>
								_fadePage(state, const PerfilesPage()),
					),
					GoRoute(
						path: '/perfiles/:perfilId/derechos',
						pageBuilder: (context, state) {
							final extra = state.extra;
							return _fadePage(
								state,
								PerfilDerechosPage(
									perfilId: state.pathParameters['perfilId']!,
									perfilNombre: extra is String ? extra : null,
								),
							);
						},
					),
					GoRoute(
						path: '/derechos',
						pageBuilder: (context, state) =>
								_fadePage(state, const DerechosTreePage()),
					),
					GoRoute(
						path: '/sucursales',
						pageBuilder: (context, state) => _fadePage(state, const SucursalesPage()),
					),
				],
			),
		],
	);
});
