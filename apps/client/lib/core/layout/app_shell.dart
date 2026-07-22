import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../components/sika_logo.dart';
import '../layout/breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

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
		required bool canStock,
		required bool canSolicitudesMateriales,
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
			if (canStock)
				const AppNavItem(
					id: 'stock',
					label: 'Stock',
					icon: Icons.inventory_2_outlined,
					selectedIcon: Icons.inventory_2_rounded,
					route: '/stock',
				),
			if (canSolicitudesMateriales)
				const AppNavItem(
					id: 'solicitudes-materiales',
					label: 'Mat. pañol',
					icon: Icons.shopping_bag_outlined,
					selectedIcon: Icons.shopping_bag_rounded,
					route: '/solicitudes-materiales',
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
		if (location.startsWith('/solicitudes-materiales')) return 'solicitudes-materiales';
		if (location.startsWith('/stock')) return 'stock';
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

	static const _moreItem = AppNavItem(
		id: 'more',
		label: 'Más',
		icon: Icons.keyboard_arrow_up_rounded,
		selectedIcon: Icons.keyboard_arrow_up_rounded,
		route: '',
	);

	List<AppNavItem> _mobilePrimaryItems({
		required bool isTechnician,
		required bool canBuscarOt,
		required bool canPlanta,
	}) {
		if (isTechnician) {
			return _technicianItems();
		}

		return [
			const AppNavItem(
				id: 'home',
				label: 'Inicio',
				icon: Icons.home_outlined,
				selectedIcon: Icons.home_rounded,
				route: '/home',
			),
			if (canBuscarOt)
				const AppNavItem(
					id: 'buscar-ot',
					label: 'OT',
					icon: Icons.search_rounded,
					selectedIcon: Icons.manage_search_rounded,
					route: '/ot',
				),
			_moreItem,
			if (canPlanta)
				const AppNavItem(
					id: 'equipos',
					label: 'Planta',
					icon: Icons.precision_manufacturing_outlined,
					selectedIcon: Icons.precision_manufacturing_rounded,
					route: '/planta',
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

	List<AppNavItem> _mobileMoreItems(List<AppNavItem> allItems) {
		const primaryIds = {'home', 'buscar-ot', 'equipos', 'perfil', 'more'};
		return allItems.where((item) => !primaryIds.contains(item.id)).toList();
	}

	Future<void> _showMoreMenu(
		BuildContext context, {
		required List<AppNavItem> moreItems,
		required String selectedId,
	}) async {
		if (moreItems.isEmpty) return;

		final route = await showModalBottomSheet<String>(
			context: context,
			backgroundColor:
					Theme.of(context).brightness == Brightness.dark
							? AppColors.cardElevated
							: AppColors.white,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (sheetContext) {
				final scheme = Theme.of(sheetContext).colorScheme;
				final onBg = scheme.onSurface;

				return SafeArea(
					child: Padding(
						padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(
									width: 40,
									height: 4,
									margin: const EdgeInsets.only(bottom: 16),
									decoration: BoxDecoration(
										color: onBg.withValues(alpha: 0.25),
										borderRadius: BorderRadius.circular(2),
									),
								),
								Align(
									alignment: Alignment.centerLeft,
									child: Text(
										'Menú',
										style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
													color: onBg,
													fontWeight: FontWeight.w700,
												),
									),
								),
								const SizedBox(height: 12),
								...moreItems.map((item) {
									final selected = item.id == selectedId;
									return Padding(
										padding: const EdgeInsets.only(bottom: 4),
										child: Material(
											color: selected
													? scheme.primary
													: Colors.transparent,
											borderRadius: BorderRadius.circular(12),
											child: InkWell(
												borderRadius: BorderRadius.circular(12),
												onTap: () => Navigator.of(sheetContext).pop(item.route),
												child: Padding(
													padding: const EdgeInsets.symmetric(
														horizontal: 14,
														vertical: 14,
													),
													child: Row(
														children: [
															Icon(
																selected ? item.selectedIcon : item.icon,
																size: 22,
																color: selected
																		? scheme.onPrimary
																		: onBg.withValues(alpha: 0.85),
															),
															const SizedBox(width: 14),
															Expanded(
																child: Text(
																	item.label,
																	style: TextStyle(
																		fontWeight: selected
																				? FontWeight.w700
																				: FontWeight.w500,
																		color: selected
																				? scheme.onPrimary
																				: onBg.withValues(alpha: 0.9),
																		fontSize: 15,
																	),
																),
															),
															Icon(
																Icons.chevron_right_rounded,
																size: 20,
																color: selected
																		? scheme.onPrimary.withValues(alpha: 0.6)
																		: onBg.withValues(alpha: 0.35),
															),
														],
													),
												),
											),
										),
									);
								}),
							],
						),
					),
				);
			},
		);

		if (route != null && context.mounted) {
			_go(context, route);
		}
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
		final canStock =
				user?.tieneDerecho('stock.materiales_en_stock.ver') == true ||
				user?.esAdministrador == true;
		final canSolicitudesMateriales =
				user?.tieneDerecho('stock.pañol.solicitudes_materiales.ver_pendientes') == true ||
				user?.esAdministrador == true;
		final canContadores =
				user?.tieneDerecho('archivos.equipos.listar') == true ||
				user?.esAdministrador == true;
		final canOtNecesarias =
				user?.tieneDerecho('programacion.ordenes_trabajo.emitir_periodica') == true ||
				user?.esAdministrador == true;
		final isTechnician = user?.esTecnico == true;
		final isPanolero = user?.esPanolero == true;

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
						canStock: canStock,
						canSolicitudesMateriales: canSolicitudesMateriales,
						canConfig: canConfig,
					);
		final mobileItems = _mobilePrimaryItems(
			isTechnician: isTechnician,
			canBuscarOt: canBuscarOt,
			canPlanta: canPlanta,
		);
		final moreItems = _mobileMoreItems(items);
		final selectedId = _selectedId();
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final pageBg =
				isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
		final navBg = isDark ? AppColors.black : AppColors.white;
		final moreSelected = moreItems.any((item) => item.id == selectedId);

		if (isTechnician || isPanolero) {
			return Scaffold(
				backgroundColor: isPanolero ? AppColors.backgroundLight : pageBg,
				body: SafeArea(child: child),
			);
		}

		if (isMobile) {
			final mobileIndex = moreSelected
					? mobileItems.indexWhere((item) => item.id == 'more')
					: mobileItems.indexWhere((item) => item.id == selectedId);
			final navIndex = mobileIndex >= 0 ? mobileIndex : 0;

			return Scaffold(
				backgroundColor: pageBg,
				// bottom: false — la NavigationBar ya respeta el notch inferior
				body: SafeArea(bottom: false, child: child),
				bottomNavigationBar: NavigationBar(
					selectedIndex: navIndex,
					onDestinationSelected: (index) {
						if (index >= mobileItems.length) return;
						final item = mobileItems[index];
						if (item.id == 'more') {
							_showMoreMenu(
								context,
								moreItems: moreItems,
								selectedId: selectedId,
							);
							return;
						}
						_go(context, item.route);
					},
					destinations: mobileItems
							.map(
								(item) => NavigationDestination(
									icon: item.id == 'more'
											? const Icon(Icons.keyboard_arrow_up_rounded, size: 28)
											: Icon(item.icon),
									selectedIcon: item.id == 'more'
											? const Icon(Icons.keyboard_arrow_up_rounded, size: 28)
											: Icon(item.selectedIcon),
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
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final borderColor = isDark
				? Colors.white.withValues(alpha: 0.08)
				: const Color(0xFFE8E0F0);

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
								Padding(
									padding: EdgeInsets.fromLTRB(
										_collapsed ? 12 : 20,
										20,
										_collapsed ? 12 : 20,
										4,
									),
									child: InkWell(
										onTap: widget.onHome,
										borderRadius: BorderRadius.circular(8),
										child: _collapsed
												? const Center(
														child: SikaLogo(size: 28, compact: true),
													)
												: _SidebarBrand(isDark: isDark),
									),
								),
								Padding(
									padding: const EdgeInsets.only(bottom: 10),
									child: Center(
										child: _ThemeToggleIcon(isDark: isDark),
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
											Divider(color: borderColor),
											if (!_collapsed && widget.userName.isNotEmpty) ...[
												Padding(
													padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
													child: Align(
														alignment: Alignment.centerLeft,
														child: Text(
															widget.userName.toUpperCase(),
															maxLines: 1,
															overflow: TextOverflow.ellipsis,
															style: TextStyle(
																color: isDark
																		? AppColors.brandPurple
																		: AppColors.brandPurpleDark,
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
																	color: isDark
																			? Colors.white.withValues(alpha: 0.85)
																			: AppColors.ink,
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
																	color: isDark
																			? Colors.white.withValues(alpha: 0.55)
																			: AppColors.secondary,
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

class _ThemeToggleIcon extends ConsumerWidget {
	const _ThemeToggleIcon({required this.isDark});

	final bool isDark;

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final fg = isDark
				? Colors.white.withValues(alpha: 0.85)
				: AppColors.ink.withValues(alpha: 0.75);
		final border = isDark
				? Colors.white.withValues(alpha: 0.14)
				: const Color(0xFFE4DCEF);

		return Tooltip(
			message: isDark ? 'Modo claro' : 'Modo oscuro',
			child: Material(
				color: Colors.transparent,
				shape: CircleBorder(side: BorderSide(color: border)),
				child: InkWell(
					customBorder: const CircleBorder(),
					onTap: () =>
							ref.read(themeControllerProvider.notifier).toggleLightDark(),
					child: Padding(
						padding: const EdgeInsets.all(8),
						child: AnimatedSwitcher(
							duration: const Duration(milliseconds: 250),
							transitionBuilder: (child, anim) => RotationTransition(
								turns: Tween(begin: 0.75, end: 1.0).animate(anim),
								child: FadeTransition(opacity: anim, child: child),
							),
							child: Icon(
								isDark
										? Icons.light_mode_outlined
										: Icons.dark_mode_outlined,
								key: ValueKey(isDark),
								size: 18,
								color: fg,
							),
						),
					),
				),
			),
		);
	}
}

class _SidebarBrand extends StatelessWidget {
	const _SidebarBrand({required this.isDark});

	final bool isDark;

	@override
	Widget build(BuildContext context) {
		return const Center(
			child: SikaLogo(size: 110, compact: true),
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
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final fgColor = selected
				? AppColors.onPrimary
				: (isDark
						? Colors.white.withValues(alpha: 0.82)
						: AppColors.ink.withValues(alpha: 0.82));

		final tile = Material(
			color: selected
					? (isDark ? AppColors.brandPurple : AppColors.brandPurpleDark)
					: Colors.transparent,
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
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final lineColor =
				isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E0F0);
		final buttonBg = isDark ? AppColors.cardElevated : AppColors.white;

		return SizedBox(
			width: 20,
			child: Stack(
				clipBehavior: Clip.none,
				children: [
					Positioned.fill(
						child: VerticalDivider(width: 1, color: lineColor),
					),
					Positioned(
						left: -13,
						top: 30,
						child: Tooltip(
							message: collapsed ? 'Expandir menú' : 'Colapsar menú',
							child: AnimatedContainer(
								duration: const Duration(milliseconds: 200),
								decoration: BoxDecoration(
									color: buttonBg,
									shape: BoxShape.circle,
									border: Border.all(
										color: AppColors.brandPurple.withValues(alpha: 0.45),
									),
									boxShadow: [
										BoxShadow(
											color: Colors.black.withValues(
												alpha: isDark ? 0.4 : 0.08,
											),
											blurRadius: 8,
											offset: const Offset(0, 2),
										),
									],
								),
								child: Material(
									color: Colors.transparent,
									shape: const CircleBorder(),
									child: InkWell(
										customBorder: const CircleBorder(),
										onTap: onToggle,
										child: Padding(
											padding: const EdgeInsets.all(5),
											child: AnimatedRotation(
												duration: const Duration(milliseconds: 220),
												curve: Curves.easeOutCubic,
												turns: collapsed ? 0.5 : 0,
												child: Icon(
													Icons.chevron_left_rounded,
													size: 16,
													color: isDark
															? AppColors.brandPurple
															: AppColors.brandPurpleDark,
												),
											),
										),
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
