import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../components/sika_logo.dart';
import '../layout/breakpoints.dart';
import '../theme/app_colors.dart';

class AppNavItem {
	const AppNavItem({
		required this.id,
		required this.label,
		required this.icon,
		required this.selectedIcon,
		required this.route,
		this.groupEnd = false,
	});

	final String id;
	final String label;
	final IconData icon;
	final IconData selectedIcon;
	final String route;
	final bool groupEnd;
}

class AppShell extends ConsumerWidget {
	const AppShell({
		super.key,
		required this.location,
		required this.child,
	});

	final String location;
	final Widget child;

	static const sidebarExpandedWidth = 272.0;
	static const sidebarCollapsedWidth = 72.0;

	List<AppNavItem> _items({
		required bool canPlanta,
		required bool canProcedimientos,
		required bool canBuscarOt,
		required bool canEmitirNoPeriodica,
		required bool canSolicitudes,
		required bool canContadores,
		required bool canOtNecesarias,
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
			if (canProcedimientos)
				const AppNavItem(
					id: 'procedimientos',
					label: 'Procedimientos',
					icon: Icons.description_outlined,
					selectedIcon: Icons.description_rounded,
					route: '/procedimientos',
				),
			if (canPlanta)
				const AppNavItem(
					id: 'equipos',
					label: 'Equipos',
					icon: Icons.precision_manufacturing_outlined,
					selectedIcon: Icons.precision_manufacturing_rounded,
					route: '/planta',
				),
			if (canBuscarOt)
				const AppNavItem(
					id: 'buscar-ot',
					label: 'Buscar OT',
					icon: Icons.search_rounded,
					selectedIcon: Icons.manage_search_rounded,
					route: '/ot',
				),
			if (canEmitirNoPeriodica)
				const AppNavItem(
					id: 'emitir-no-periodica',
					label: 'OT no periódica',
					icon: Icons.assignment_outlined,
					selectedIcon: Icons.assignment_rounded,
					route: '/ot/emitir-no-periodica',
				),
			if (canSolicitudes)
				const AppNavItem(
					id: 'solicitudes',
					label: 'Solicitudes',
					icon: Icons.campaign_outlined,
					selectedIcon: Icons.campaign_rounded,
					route: '/solicitudes',
				),
			if (canContadores)
				const AppNavItem(
					id: 'contadores',
					label: 'Contadores',
					icon: Icons.speed_outlined,
					selectedIcon: Icons.speed_rounded,
					route: '/contadores',
				),
			if (canOtNecesarias)
				const AppNavItem(
					id: 'ot-necesarias',
					label: 'OT necesarias',
					icon: Icons.pending_actions_outlined,
					selectedIcon: Icons.pending_actions_rounded,
					route: '/ot/necesarias',
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
		if (location.startsWith('/mis-ot')) return 'mis-ot';
		if (location.startsWith('/ot/necesarias')) return 'ot-necesarias';
		if (location.startsWith('/ot/emitir-no-periodica')) return 'emitir-no-periodica';
		if (location.startsWith('/ot/emitir-periodica')) return 'emitir-no-periodica';
		if (location.startsWith('/procedimientos')) return 'procedimientos';
		if (location.startsWith('/planta')) return 'equipos';
		if (location.startsWith('/solicitudes')) return 'solicitudes';
		if (location.startsWith('/contadores')) return 'contadores';
		if (location.startsWith('/usuarios') ||
				location.startsWith('/perfiles') ||
				location.startsWith('/sucursales') ||
				location.startsWith('/config')) {
			return 'config';
		}
		if (location.startsWith('/perfil')) return 'perfil';
		if (location.startsWith('/ot')) return 'buscar-ot';
		if (location.startsWith('/home')) return 'home';
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

	List<AppNavItem> _technicianItems({bool includePerfil = true}) {
		return [
			const AppNavItem(
				id: 'mis-ot',
				label: 'Mis OT',
				icon: Icons.assignment_outlined,
				selectedIcon: Icons.assignment_rounded,
				route: '/mis-ot',
			),
			if (includePerfil)
				const AppNavItem(
					id: 'perfil',
					label: 'Perfil',
					icon: Icons.person_outline,
					selectedIcon: Icons.person_rounded,
					route: '/perfil',
				),
		];
	}

	List<AppNavItem> _mobileItems({
		required bool isTechnician,
		required bool canBuscarOt,
		required bool canSolicitudes,
		required bool canPlanta,
	}) {
		if (isTechnician) {
			return _technicianItems();
		}

		final items = <AppNavItem>[
			const AppNavItem(
				id: 'home',
				label: 'Inicio',
				icon: Icons.home_outlined,
				selectedIcon: Icons.home_rounded,
				route: '/home',
			),
		];

		if (canBuscarOt) {
			items.add(
				const AppNavItem(
					id: 'buscar-ot',
					label: 'OT',
					icon: Icons.search_rounded,
					selectedIcon: Icons.manage_search_rounded,
					route: '/ot',
				),
			);
		}
		if (canSolicitudes) {
			items.add(
				const AppNavItem(
					id: 'solicitudes',
					label: 'Solicitudes',
					icon: Icons.campaign_outlined,
					selectedIcon: Icons.campaign_rounded,
					route: '/solicitudes',
				),
			);
		}
		if (canPlanta) {
			items.add(
				const AppNavItem(
					id: 'equipos',
					label: 'Planta',
					icon: Icons.precision_manufacturing_outlined,
					selectedIcon: Icons.precision_manufacturing_rounded,
					route: '/planta',
				),
			);
		}

		items.add(
			const AppNavItem(
				id: 'perfil',
				label: 'Perfil',
				icon: Icons.person_outline,
				selectedIcon: Icons.person_rounded,
				route: '/perfil',
			),
		);

		if (items.length > 5) {
			return [...items.sublist(0, 3), items.last];
		}
		return items;
	}

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final user = ref.watch(authControllerProvider).session?.usuario;
		final canConfig = user?.tieneDerecho('configuracion.usuarios.listar') == true ||
				user?.esAdministrador == true;
		final canPlanta = user?.tieneDerecho('archivos.equipos.listar') == true ||
				user?.esAdministrador == true;
		final canProcedimientos =
				user?.tieneDerecho('archivos.procedimientos.listar') == true ||
				user?.esAdministrador == true;
		final canBuscarOt =
				user?.tieneDerecho('programacion.ordenes_trabajo.buscar_y_actualizar') == true ||
				user?.esAdministrador == true;
		final canEmitirNoPeriodica =
				user?.tieneDerecho('programacion.ordenes_trabajo.emitir_no_periodica') == true ||
				user?.esAdministrador == true;
		final canSolicitudes =
				user?.tieneDerecho('programacion.solicitudes_trabajo.listar') == true ||
				user?.esAdministrador == true;
		final canContadores =
				user?.tieneDerecho('archivos.equipos.listar') == true ||
				user?.esAdministrador == true;
		final canOtNecesarias =
				user?.tieneDerecho('programacion.ordenes_trabajo.emitir_periodica') == true ||
				user?.esAdministrador == true;
		final isTechnician = user?.esTecnico == true;

		final width = MediaQuery.sizeOf(context).width;
		final isMobile = width < Breakpoints.tablet;

		final items = isTechnician
				? _technicianItems(includePerfil: !isMobile)
				: _items(
						canPlanta: canPlanta,
						canProcedimientos: canProcedimientos,
						canBuscarOt: canBuscarOt,
						canEmitirNoPeriodica: canEmitirNoPeriodica,
						canSolicitudes: canSolicitudes,
						canContadores: canContadores,
						canOtNecesarias: canOtNecesarias,
						canConfig: canConfig,
					);
		final mobileItems = _mobileItems(
			isTechnician: isTechnician,
			canBuscarOt: canBuscarOt,
			canSolicitudes: canSolicitudes,
			canPlanta: canPlanta,
		);
		final selectedId = _selectedId();
		final pageBg = AppColors.backgroundDark;
		final navBg = AppColors.black;

		if (isTechnician) {
			return Scaffold(
				backgroundColor: pageBg,
				body: child,
			);
		}

		if (isMobile) {
			final mobileIndex = mobileItems.indexWhere((item) => item.id == selectedId);
			final navIndex = mobileIndex >= 0 ? mobileIndex : 0;

			return Scaffold(
				backgroundColor: AppColors.backgroundDark,
				body: child,
				bottomNavigationBar: NavigationBar(
					selectedIndex: navIndex,
					onDestinationSelected: (index) {
						if (index < mobileItems.length) {
							_go(context, mobileItems[index].route);
						}
					},
					destinations: mobileItems
							.map(
								(item) => NavigationDestination(
									icon: Icon(item.icon),
									selectedIcon: Icon(item.selectedIcon),
									label: item.label,
								),
							)
							.toList(),
				),
			);
		}

		return Scaffold(
			backgroundColor: pageBg,
			body: Row(
				children: [
					_Sidebar(
						navBg: navBg,
						items: items,
						selectedId: selectedId,
						onNavigate: (route) => _go(context, route),
						onHome: () => _go(
							context,
							isTechnician ? '/mis-ot' : '/home',
						),
						onLogout: () => _logout(context, ref),
						userName: user?.nombreUsuario ?? '',
						perfilNombre: user?.perfilNombre ??
								(user?.esAdministrador == true ? 'Administrador' : ''),
						sucursalNombre: user?.sucursalNombre ?? '',
					),
					Expanded(child: child),
				],
			),
		);
	}
}

class _Sidebar extends StatefulWidget {
	const _Sidebar({
		required this.navBg,
		required this.items,
		required this.selectedId,
		required this.onNavigate,
		required this.onHome,
		required this.onLogout,
		required this.userName,
		required this.perfilNombre,
		required this.sucursalNombre,
	});

	final Color navBg;
	final List<AppNavItem> items;
	final String selectedId;
	final ValueChanged<String> onNavigate;
	final VoidCallback onHome;
	final VoidCallback onLogout;
	final String userName;
	final String perfilNombre;
	final String sucursalNombre;

	@override
	State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
	bool _collapsed = false;

	void _toggle() => setState(() => _collapsed = !_collapsed);

	@override
	Widget build(BuildContext context) {
		final width = _collapsed
				? AppShell.sidebarCollapsedWidth
				: AppShell.sidebarExpandedWidth;

		return Row(
			children: [
				AnimatedContainer(
					duration: const Duration(milliseconds: 220),
					curve: Curves.easeOutCubic,
					width: width,
					child: Material(
						color: widget.navBg,
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								Container(
									color: AppColors.brandYellow,
									padding: EdgeInsets.fromLTRB(
										_collapsed ? 12 : 20,
										20,
										_collapsed ? 12 : 20,
										16,
									),
									child: InkWell(
										onTap: widget.onHome,
										borderRadius: BorderRadius.circular(8),
										child: _collapsed
												? const Center(
														child: SikaLogo(size: 28, compact: true),
													)
												: const SikaLogo(
														size: 44,
														showTagline: true,
													),
									),
								),
								Expanded(
									child: ListView(
										padding: EdgeInsets.fromLTRB(
											_collapsed ? 8 : 10,
											12,
											_collapsed ? 8 : 10,
											8,
										),
										children: widget.items.map((item) {
											final selected = item.id == widget.selectedId;
											return _NavTile(
												item: item,
												selected: selected,
												collapsed: _collapsed,
												onTap: () => widget.onNavigate(item.route),
											);
										}).toList(),
									),
								),
								Padding(
									padding: EdgeInsets.fromLTRB(
										_collapsed ? 8 : 12,
										8,
										_collapsed ? 8 : 12,
										16,
									),
									child: Column(
										children: [
											Divider(
												color: Colors.white.withValues(alpha: 0.1),
											),
											if (!_collapsed && widget.userName.isNotEmpty) ...[
												Padding(
													padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
													child: Align(
														alignment: Alignment.centerLeft,
														child: Text(
															widget.userName.toUpperCase(),
															maxLines: 1,
															overflow: TextOverflow.ellipsis,
															style: const TextStyle(
																color: AppColors.brandYellow,
																fontWeight: FontWeight.w800,
																fontSize: 12,
																letterSpacing: 0.3,
															),
														),
													),
												),
												if (widget.perfilNombre.isNotEmpty)
													Padding(
														padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
														child: Align(
															alignment: Alignment.centerLeft,
															child: Text(
																widget.perfilNombre,
																maxLines: 1,
																overflow: TextOverflow.ellipsis,
																style: TextStyle(
																	color: Colors.white.withValues(alpha: 0.85),
																	fontSize: 12,
																	fontWeight: FontWeight.w500,
																),
															),
														),
													),
												if (widget.sucursalNombre.isNotEmpty)
													Padding(
														padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
														child: Align(
															alignment: Alignment.centerLeft,
															child: Text(
																widget.sucursalNombre,
																maxLines: 1,
																overflow: TextOverflow.ellipsis,
																style: TextStyle(
																	color: Colors.white.withValues(alpha: 0.55),
																	fontSize: 11,
																	fontWeight: FontWeight.w500,
																),
															),
														),
													),
											],
											_NavActionTile(
												label: 'Cerrar sesión',
												icon: Icons.logout_rounded,
												collapsed: _collapsed,
												onTap: widget.onLogout,
											),
										],
									),
								),
							],
						),
					),
				),
				_SidebarCollapseHandle(
					collapsed: _collapsed,
					onToggle: _toggle,
				),
			],
		);
	}
}

class _NavTile extends StatelessWidget {
	const _NavTile({
		required this.item,
		required this.selected,
		required this.collapsed,
		required this.onTap,
	});

	final AppNavItem item;
	final bool selected;
	final bool collapsed;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final icon = selected ? item.selectedIcon : item.icon;
		final fgColor = selected ? AppColors.ink : Colors.white.withValues(alpha: 0.82);

		final tile = Material(
			color: selected ? AppColors.brandYellow : Colors.transparent,
			borderRadius: BorderRadius.circular(12),
			child: InkWell(
				borderRadius: BorderRadius.circular(12),
				onTap: onTap,
				child: Padding(
					padding: EdgeInsets.symmetric(
						horizontal: collapsed ? 0 : 14,
						vertical: 11,
					),
					child: collapsed
							? Center(child: Icon(icon, size: 22, color: fgColor))
							: Row(
									children: [
										Icon(icon, size: 20, color: fgColor),
										const SizedBox(width: 12),
										Expanded(
											child: Text(
												item.label,
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
												style: TextStyle(
													fontWeight:
															selected ? FontWeight.w700 : FontWeight.w500,
													color: fgColor,
													fontSize: 14,
												),
											),
										),
									],
								),
				),
			),
		);

		return Padding(
			padding: const EdgeInsets.only(bottom: 4),
			child: collapsed
					? Tooltip(message: item.label, child: tile)
					: tile,
		);
	}
}

class _SidebarCollapseHandle extends StatelessWidget {
	const _SidebarCollapseHandle({
		required this.collapsed,
		required this.onToggle,
	});

	final bool collapsed;
	final VoidCallback onToggle;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: 20,
			child: Stack(
				clipBehavior: Clip.none,
				children: [
					const Positioned.fill(
						child: VerticalDivider(
							width: 1,
							color: Color(0xFF2A2A2A),
						),
					),
					Positioned(
						left: -14,
						top: 28,
						child: Material(
							color: AppColors.brandYellow,
							shape: const CircleBorder(),
							elevation: 2,
							child: InkWell(
								customBorder: const CircleBorder(),
								onTap: onToggle,
								child: Padding(
									padding: const EdgeInsets.all(6),
									child: Icon(
										collapsed
												? Icons.chevron_right_rounded
												: Icons.chevron_left_rounded,
										size: 18,
										color: AppColors.ink,
									),
								),
							),
						),
					),
				],
			),
		);
	}
}

class _NavActionTile extends StatelessWidget {
	const _NavActionTile({
		required this.label,
		required this.icon,
		required this.collapsed,
		required this.onTap,
	});

	final String label;
	final IconData icon;
	final bool collapsed;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		const color = AppColors.accent;

		final tile = Material(
			color: Colors.transparent,
			borderRadius: BorderRadius.circular(12),
			child: InkWell(
				borderRadius: BorderRadius.circular(12),
				onTap: onTap,
				child: Padding(
					padding: EdgeInsets.symmetric(
						horizontal: collapsed ? 0 : 14,
						vertical: 12,
					),
					child: collapsed
							? Center(child: Icon(icon, size: 22, color: color))
							: Row(
									children: [
										Icon(icon, size: 20, color: color),
										const SizedBox(width: 12),
										Text(
											label,
											style: const TextStyle(
												fontWeight: FontWeight.w600,
												color: color,
												fontSize: 14,
											),
										),
									],
								),
				),
			),
		);

		return collapsed ? Tooltip(message: label, child: tile) : tile;
	}
}
