import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../components/sika_logo.dart';
import '../layout/breakpoints.dart';
import '../layout/shell_back_scope.dart';
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
		required bool canMisOt,
		required bool canEmitirNoPeriodica,
		required bool canSolicitudes,
		required bool canContadores,
		required bool canOtNecesarias,
		required bool canStock,
		required bool canSolicitudesMateriales,
		required bool canCompras,
		required bool canIndicadores,
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
			if (canMisOt)
				const AppNavItem(
					id: 'mis-ot',
					label: 'Mis OT',
					icon: Icons.assignment_outlined,
					selectedIcon: Icons.assignment_rounded,
					route: '/mis-ot',
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
			if (canIndicadores)
				const AppNavItem(
					id: 'indicadores',
					label: 'Indicadores',
					icon: Icons.insights_outlined,
					selectedIcon: Icons.insights_rounded,
					route: '/indicadores',
				),
			if (canBuscarOt)
				const AppNavItem(
					id: 'graficos',
					label: 'Gráficos OT',
					icon: Icons.bar_chart_outlined,
					selectedIcon: Icons.bar_chart_rounded,
					route: '/ot/graficos',
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
			if (canCompras)
				const AppNavItem(
					id: 'compras',
					label: 'Compras',
					icon: Icons.local_shipping_outlined,
					selectedIcon: Icons.local_shipping_rounded,
					route: '/compras',
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
		if (location.startsWith('/indicadores')) return 'indicadores';
		if (location.startsWith('/compras')) return 'compras';
		if (location.startsWith('/ot/graficos')) return 'graficos';
		if (location.startsWith('/ot/gantt')) return 'buscar-ot';
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

	static const _moreItem = AppNavItem(
		id: 'more',
		label: 'Más',
		icon: Icons.apps_rounded,
		selectedIcon: Icons.apps_rounded,
		route: '',
	);

	List<AppNavItem> _mobilePrimaryItems({
		required bool preferMisOt,
		required bool canBuscarOt,
		required bool canMisOt,
		required bool canSolicitudes,
		required bool canSolicitudesMateriales,
		required bool canIndicadores,
		required bool canPlanta,
	}) {
		// Slot operativo: bandejas del día a día (supervisor/jefe) antes que planta.
		final AppNavItem? opsSlot = canSolicitudes
				? const AppNavItem(
						id: 'solicitudes',
						label: 'Solic.',
						icon: Icons.campaign_outlined,
						selectedIcon: Icons.campaign_rounded,
						route: '/solicitudes',
					)
				: canSolicitudesMateriales
						? const AppNavItem(
								id: 'solicitudes-materiales',
								label: 'Pañol',
								icon: Icons.shopping_bag_outlined,
								selectedIcon: Icons.shopping_bag_rounded,
								route: '/solicitudes-materiales',
							)
						: canIndicadores
								? const AppNavItem(
										id: 'indicadores',
										label: 'Indica.',
										icon: Icons.insights_outlined,
										selectedIcon: Icons.insights_rounded,
										route: '/indicadores',
									)
								: canPlanta
										? const AppNavItem(
												id: 'equipos',
												label: 'Planta',
												icon: Icons.precision_manufacturing_outlined,
												selectedIcon: Icons.precision_manufacturing_rounded,
												route: '/planta',
											)
										: null;

		return [
			const AppNavItem(
				id: 'home',
				label: 'Inicio',
				icon: Icons.home_outlined,
				selectedIcon: Icons.home_rounded,
				route: '/home',
			),
			if (preferMisOt && canMisOt)
				const AppNavItem(
					id: 'mis-ot',
					label: 'Mis OT',
					icon: Icons.assignment_outlined,
					selectedIcon: Icons.assignment_rounded,
					route: '/mis-ot',
				)
			else if (canBuscarOt)
				const AppNavItem(
					id: 'buscar-ot',
					label: 'OT',
					icon: Icons.search_rounded,
					selectedIcon: Icons.manage_search_rounded,
					route: '/ot',
				),
			_moreItem,
			if (opsSlot != null) opsSlot,
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
		const primaryIds = {
			'home',
			'buscar-ot',
			'mis-ot',
			'solicitudes',
			'solicitudes-materiales',
			'indicadores',
			'equipos',
			'perfil',
			'more',
		};
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
			isScrollControlled: true,
			useSafeArea: true,
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
				final media = MediaQuery.of(sheetContext);
				final maxHeight = (media.size.height - media.padding.top) * 0.82;

				return ConstrainedBox(
					constraints: BoxConstraints(maxHeight: maxHeight),
					child: Padding(
						padding: EdgeInsets.fromLTRB(
							16,
							8,
							16,
							8 + media.viewPadding.bottom,
						),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(
									width: 40,
									height: 4,
									margin: const EdgeInsets.only(bottom: 12),
									decoration: BoxDecoration(
										color: onBg.withValues(alpha: 0.25),
										borderRadius: BorderRadius.circular(2),
									),
								),
								Align(
									alignment: Alignment.centerLeft,
									child: Padding(
										padding: const EdgeInsets.only(bottom: 8),
										child: Text(
											'Menú',
											style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
														color: onBg,
														fontWeight: FontWeight.w700,
													),
										),
									),
								),
								Flexible(
									child: ListView.separated(
										shrinkWrap: true,
										physics: const ClampingScrollPhysics(),
										itemCount: moreItems.length,
										separatorBuilder: (_, __) => const SizedBox(height: 2),
										itemBuilder: (context, index) {
											final item = moreItems[index];
											final selected = item.id == selectedId;
											return Material(
												color: selected ? scheme.primary : Colors.transparent,
												borderRadius: BorderRadius.circular(12),
												child: InkWell(
													borderRadius: BorderRadius.circular(12),
													onTap: () =>
															Navigator.of(sheetContext).pop(item.route),
													child: Padding(
														padding: const EdgeInsets.symmetric(
															horizontal: 14,
															vertical: 12,
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
											);
										},
									),
								),
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
		final canCompras =
				user?.tieneDerecho('stock.ordenes_compra.buscar_y_actualizar') == true ||
				user?.tieneDerecho('stock.ordenes_compra.emitir') == true ||
				user?.esAdministrador == true;
		final canIndicadores =
				user?.tieneDerecho('analisis.trabajos.indices_gestion') == true ||
				user?.tieneDerecho('programacion.ordenes_trabajo.buscar_y_actualizar') == true ||
				user?.esAdministrador == true;
		final canMisOt =
				user?.esTecnico == true ||
				user?.tieneDerecho('programacion.ordenes_trabajo.buscar_y_actualizar') == true ||
				user?.esAdministrador == true;
		final preferMisOt = user?.esTecnico == true;
		final homeRoute = preferMisOt
				? '/mis-ot'
				: user?.esPanolero == true
						? '/panol'
						: '/home';

		final width = MediaQuery.sizeOf(context).width;
		final isMobile = width < Breakpoints.tablet;

		final items = _items(
			canPlanta: canPlanta,
			canProcedimientos: canProcedimientos,
			canBuscarOt: canBuscarOt,
			canMisOt: canMisOt,
			canEmitirNoPeriodica: canEmitirNoPeriodica,
			canSolicitudes: canSolicitudes,
			canContadores: canContadores,
			canOtNecesarias: canOtNecesarias,
			canStock: canStock,
			canSolicitudesMateriales: canSolicitudesMateriales,
			canCompras: canCompras,
			canIndicadores: canIndicadores,
			canConfig: canConfig,
		);
		final mobileItems = _mobilePrimaryItems(
			preferMisOt: preferMisOt,
			canBuscarOt: canBuscarOt,
			canMisOt: canMisOt,
			canSolicitudes: canSolicitudes,
			canSolicitudesMateriales: canSolicitudesMateriales,
			canIndicadores: canIndicadores,
			canPlanta: canPlanta,
		);
		final moreItems = _mobileMoreItems(items);
		final selectedId = _selectedId();
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final pageBg =
				isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
		final navBg = isDark ? AppColors.black : AppColors.white;
		final moreSelected = moreItems.any((item) => item.id == selectedId);

		Widget wrapBack(Widget body) {
			return ShellBackScope(
				location: location,
				homeRoute: homeRoute,
				child: body,
			);
		}

		if (isMobile) {
			final mobileIndex = moreSelected
					? mobileItems.indexWhere((item) => item.id == 'more')
					: mobileItems.indexWhere((item) => item.id == selectedId);
			final navIndex = mobileIndex >= 0 ? mobileIndex : 0;

			return Scaffold(
				backgroundColor: pageBg,
				body: SafeArea(bottom: false, child: wrapBack(child)),
				bottomNavigationBar: _MobileBottomNav(
					items: mobileItems,
					selectedIndex: navIndex,
					onSelected: (index) {
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
						onHome: () => _go(context, homeRoute),
						onLogout: () => _logout(context, ref),
						userName: user?.nombreUsuario ?? '',
						perfilNombre: user?.perfilNombre ??
								(user?.esAdministrador == true ? 'Administrador' : ''),
						sucursalNombre: user?.sucursalNombre ?? '',
					),
					Expanded(child: wrapBack(child)),
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

/// Bottom nav mobile con "Más" destacado (círculo de marca, sin flotar sobre el contenido).
class _MobileBottomNav extends StatelessWidget {
	const _MobileBottomNav({
		required this.items,
		required this.selectedIndex,
		required this.onSelected,
	});

	final List<AppNavItem> items;
	final int selectedIndex;
	final ValueChanged<int> onSelected;

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final bg = isDark ? AppColors.black : AppColors.white;
		final border = isDark
				? Colors.white.withValues(alpha: 0.08)
				: const Color(0xFFE8E0F0);
		final muted = isDark
				? Colors.white.withValues(alpha: 0.55)
				: AppColors.ink.withValues(alpha: 0.55);
		final selected = AppColors.brandPurple;

		return Material(
			color: bg,
			elevation: 0,
			child: SafeArea(
				top: false,
				child: Container(
					height: 68,
					decoration: BoxDecoration(
						border: Border(top: BorderSide(color: border)),
					),
					padding: const EdgeInsets.symmetric(horizontal: 4),
					child: Row(
						children: [
							for (var i = 0; i < items.length; i++)
								Expanded(
									child: _MobileNavSlot(
										item: items[i],
										selected: i == selectedIndex && items[i].id != 'more',
										accent: selected,
										muted: muted,
										onTap: () => onSelected(i),
									),
								),
						],
					),
				),
			),
		);
	}
}

class _MobileNavSlot extends StatelessWidget {
	const _MobileNavSlot({
		required this.item,
		required this.selected,
		required this.accent,
		required this.muted,
		required this.onTap,
	});

	final AppNavItem item;
	final bool selected;
	final Color accent;
	final Color muted;
	final VoidCallback onTap;

	bool get _isMore => item.id == 'more';

	@override
	Widget build(BuildContext context) {
		final color = selected || _isMore ? accent : muted;

		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(16),
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					if (_isMore)
						Container(
							width: 42,
							height: 42,
							decoration: BoxDecoration(
								color: accent,
								borderRadius: BorderRadius.circular(14),
								boxShadow: [
									BoxShadow(
										color: accent.withValues(alpha: 0.28),
										blurRadius: 10,
										offset: const Offset(0, 3),
									),
								],
							),
							child: const Icon(
								Icons.apps_rounded,
								color: Colors.white,
								size: 22,
							),
						)
					else
						AnimatedContainer(
							duration: const Duration(milliseconds: 180),
							padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
							decoration: BoxDecoration(
								color: selected
										? accent.withValues(alpha: 0.12)
										: Colors.transparent,
								borderRadius: BorderRadius.circular(18),
							),
							child: Icon(
								selected ? item.selectedIcon : item.icon,
								color: color,
								size: 24,
							),
						),
					const SizedBox(height: 4),
					Text(
						item.label,
						maxLines: 1,
						overflow: TextOverflow.ellipsis,
						style: TextStyle(
							fontSize: 11,
							fontWeight: selected || _isMore ? FontWeight.w700 : FontWeight.w500,
							color: color,
							height: 1.1,
						),
					),
				],
			),
		);
	}
}
