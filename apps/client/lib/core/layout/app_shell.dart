import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../theme/app_colors.dart';

class AppNavItem {
	const AppNavItem({
		required this.id,
		required this.label,
		required this.icon,
		required this.selectedIcon,
		required this.route,
	});

	final String id;
	final String label;
	final IconData icon;
	final IconData selectedIcon;
	final String route;
}

class AppShell extends ConsumerWidget {
	const AppShell({
		super.key,
		required this.location,
		required this.child,
	});

	final String location;
	final Widget child;

	bool get _isHome => location == '/home';

	List<AppNavItem> _items({
		required bool canPlanta,
		required bool canConfig,
	}) {
		return [
			const AppNavItem(
				id: 'home',
				label: 'Inicio',
				icon: Icons.home_outlined,
				selectedIcon: Icons.home_rounded,
				route: '/home',
			),
			const AppNavItem(
				id: 'ot',
				label: 'Mis OT',
				icon: Icons.assignment_outlined,
				selectedIcon: Icons.assignment_rounded,
				route: '/ot',
			),
			if (canPlanta)
				const AppNavItem(
					id: 'equipos',
					label: 'Equipos',
					icon: Icons.precision_manufacturing_outlined,
					selectedIcon: Icons.precision_manufacturing_rounded,
					route: '/planta',
				),
			if (canConfig)
				const AppNavItem(
					id: 'config',
					label: 'Config',
					icon: Icons.settings_outlined,
					selectedIcon: Icons.settings_rounded,
					route: '/config',
				),
			const AppNavItem(
				id: 'perfil',
				label: 'Perfil',
				icon: Icons.person_outline,
				selectedIcon: Icons.person_rounded,
				route: '/perfil',
			),
		];
	}

	String _selectedId() {
		if (location.startsWith('/planta')) return 'equipos';
		if (location.startsWith('/usuarios') ||
				location.startsWith('/perfiles') ||
				location.startsWith('/sucursales') ||
				location.startsWith('/config')) {
			return 'config';
		}
		if (location.startsWith('/perfil')) return 'perfil';
		if (location.startsWith('/ot')) return 'ot';
		return 'home';
	}

	void _go(BuildContext context, String route) {
		if (location == route) return;
		context.go(route);
	}

	Future<void> _logout(BuildContext context, WidgetRef ref) async {
		await ref.read(authControllerProvider.notifier).logout();
		if (context.mounted) context.go('/login');
	}

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final user = ref.watch(authControllerProvider).session?.usuario;
		final canConfig = user?.tieneDerecho('configuracion.usuarios.listar') == true ||
				user?.esAdministrador == true;
		final canPlanta = user?.tieneDerecho('archivos.equipos.listar') == true ||
				user?.esAdministrador == true;
		final items = _items(canPlanta: canPlanta, canConfig: canConfig);
		final selectedId = _selectedId();
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final pageBg = isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9);
		final navBg = isDark ? const Color(0xFF111827) : Colors.white;
		final scheme = Theme.of(context).colorScheme;

		return Scaffold(
			backgroundColor: pageBg,
			body: AnimatedSwitcher(
				duration: const Duration(milliseconds: 280),
				switchInCurve: Curves.easeOutCubic,
				switchOutCurve: Curves.easeInCubic,
				transitionBuilder: (child, animation) {
					return FadeTransition(opacity: animation, child: child);
				},
				child: _isHome
						? KeyedSubtree(
								key: const ValueKey('shell-sidebar'),
								child: Row(
									children: [
										_Sidebar(
											navBg: navBg,
											items: items,
											selectedId: selectedId,
											onNavigate: (route) => _go(context, route),
											onLogout: () => _logout(context, ref),
											userName: user?.nombreUsuario ?? '',
										),
										VerticalDivider(
											width: 1,
											color: scheme.outlineVariant.withValues(alpha: 0.35),
										),
										Expanded(
											child: AnimatedSwitcher(
												duration: const Duration(milliseconds: 220),
												switchInCurve: Curves.easeOutCubic,
												child: KeyedSubtree(
													key: ValueKey(location),
													child: child,
												),
											),
										),
									],
								),
							)
						: KeyedSubtree(
								key: const ValueKey('shell-top'),
								child: Column(
									children: [
										_TopNav(
											navBg: navBg,
											items: items,
											selectedId: selectedId,
											onNavigate: (route) => _go(context, route),
											onLogout: () => _logout(context, ref),
										),
										Expanded(
											child: AnimatedSwitcher(
												duration: const Duration(milliseconds: 220),
												switchInCurve: Curves.easeOutCubic,
												child: KeyedSubtree(
													key: ValueKey(location),
													child: child,
												),
											),
										),
									],
								),
							),
			),
		);
	}
}

class _Sidebar extends StatelessWidget {
	const _Sidebar({
		required this.navBg,
		required this.items,
		required this.selectedId,
		required this.onNavigate,
		required this.onLogout,
		required this.userName,
	});

	final Color navBg;
	final List<AppNavItem> items;
	final String selectedId;
	final ValueChanged<String> onNavigate;
	final VoidCallback onLogout;
	final String userName;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return SizedBox(
			width: 260,
			child: Material(
				color: navBg,
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Padding(
							padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										'SIKA',
										style: Theme.of(context).textTheme.titleLarge?.copyWith(
													fontWeight: FontWeight.w800,
													color: AppColors.primary,
												),
									),
									const SizedBox(height: 4),
									Text(
										'Mantenimiento',
										style: Theme.of(context).textTheme.bodySmall?.copyWith(
													color: scheme.onSurfaceVariant,
												),
									),
								],
							),
						),
						Expanded(
							child: ListView(
								padding: const EdgeInsets.symmetric(horizontal: 12),
								children: items.map((item) {
									final selected = item.id == selectedId;
									return Padding(
										padding: const EdgeInsets.only(bottom: 6),
										child: Material(
											color: selected
													? AppColors.primary.withValues(alpha: 0.12)
													: Colors.transparent,
											borderRadius: BorderRadius.circular(12),
											child: InkWell(
												borderRadius: BorderRadius.circular(12),
												onTap: () => onNavigate(item.route),
												child: Padding(
													padding: const EdgeInsets.symmetric(
														horizontal: 14,
														vertical: 12,
													),
													child: Row(
														children: [
															Icon(
																selected ? item.selectedIcon : item.icon,
																size: 20,
																color: selected
																		? AppColors.primary
																		: scheme.onSurfaceVariant,
															),
															const SizedBox(width: 12),
															Expanded(
																child: Text(
																	item.label,
																	style: TextStyle(
																		fontWeight:
																				selected ? FontWeight.w700 : FontWeight.w500,
																		color: selected ? AppColors.primary : null,
																	),
																),
															),
														],
													),
												),
											),
										),
									);
								}).toList(),
							),
						),
						Padding(
							padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
							child: Column(
								children: [
									Divider(
										color: scheme.outlineVariant.withValues(alpha: 0.4),
									),
									if (userName.isNotEmpty) ...[
										Padding(
											padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
											child: Align(
												alignment: Alignment.centerLeft,
												child: Text(
													userName,
													style: Theme.of(context).textTheme.bodySmall?.copyWith(
																color: scheme.onSurfaceVariant,
																fontWeight: FontWeight.w500,
															),
												),
											),
										),
									],
									Material(
										color: Colors.transparent,
										borderRadius: BorderRadius.circular(12),
										child: InkWell(
											borderRadius: BorderRadius.circular(12),
											onTap: onLogout,
											child: Padding(
												padding: const EdgeInsets.symmetric(
													horizontal: 14,
													vertical: 12,
												),
												child: Row(
													children: [
														Icon(
															Icons.logout_rounded,
															size: 20,
															color: scheme.error,
														),
														const SizedBox(width: 12),
														Text(
															'Cerrar sesión',
															style: TextStyle(
																fontWeight: FontWeight.w600,
																color: scheme.error,
															),
														),
													],
												),
											),
										),
									),
								],
							),
						),
					],
				),
			),
		);
	}
}

class _TopNav extends StatelessWidget {
	const _TopNav({
		required this.navBg,
		required this.items,
		required this.selectedId,
		required this.onNavigate,
		required this.onLogout,
	});

	final Color navBg;
	final List<AppNavItem> items;
	final String selectedId;
	final ValueChanged<String> onNavigate;
	final VoidCallback onLogout;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Material(
			color: navBg,
			child: SafeArea(
				bottom: false,
				child: Container(
					height: 72,
					padding: const EdgeInsets.symmetric(horizontal: 16),
					decoration: BoxDecoration(
						border: Border(
							bottom: BorderSide(
								color: scheme.outlineVariant.withValues(alpha: 0.35),
							),
						),
					),
					child: Row(
						children: [
							Text(
								'SIKA',
								style: Theme.of(context).textTheme.titleMedium?.copyWith(
											fontWeight: FontWeight.w800,
											color: AppColors.primary,
										),
							),
							const SizedBox(width: 20),
							Expanded(
								child: SingleChildScrollView(
									scrollDirection: Axis.horizontal,
									child: Row(
										children: items.map((item) {
											final selected = item.id == selectedId;
											return Padding(
												padding: const EdgeInsets.only(right: 10),
												child: _SquareNavButton(
													label: item.label,
													icon: selected ? item.selectedIcon : item.icon,
													selected: selected,
													onTap: () => onNavigate(item.route),
												),
											);
										}).toList(),
									),
								),
							),
							const SizedBox(width: 8),
							IconButton(
								tooltip: 'Cerrar sesión',
								onPressed: onLogout,
								icon: Icon(Icons.logout_rounded, color: scheme.error),
							),
						],
					),
				),
			),
		);
	}
}

class _SquareNavButton extends StatelessWidget {
	const _SquareNavButton({
		required this.label,
		required this.icon,
		required this.selected,
		required this.onTap,
	});

	final String label;
	final IconData icon;
	final bool selected;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Material(
			color: selected
					? AppColors.primary.withValues(alpha: 0.12)
					: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
			borderRadius: BorderRadius.circular(14),
			child: InkWell(
				borderRadius: BorderRadius.circular(14),
				onTap: onTap,
				child: AnimatedContainer(
					duration: const Duration(milliseconds: 180),
					curve: Curves.easeOutCubic,
					width: 76,
					height: 56,
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(
								icon,
								size: 20,
								color: selected ? AppColors.primary : scheme.onSurfaceVariant,
							),
							const SizedBox(height: 4),
							Text(
								label,
								maxLines: 1,
								overflow: TextOverflow.ellipsis,
								style: TextStyle(
									fontSize: 11,
									fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
									color: selected ? AppColors.primary : scheme.onSurfaceVariant,
								),
							),
						],
					),
				),
			),
		);
	}
}
