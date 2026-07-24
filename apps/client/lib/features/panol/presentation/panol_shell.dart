import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/shell_back_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/application/auth_controller.dart';
import 'panol_ui.dart';

class PanolShell extends ConsumerWidget {
	const PanolShell({
		super.key,
		required this.location,
		required this.child,
	});

	final String location;
	final Widget child;

	static const _tabs = [
		_PanolTab(
			id: 'inicio',
			label: 'Inicio',
			caption: 'Principal',
			icon: Icons.home_outlined,
			selectedIcon: Icons.home_rounded,
			route: '/panol',
		),
		_PanolTab(
			id: 'dashboard',
			label: 'Dashboard',
			caption: 'Pedidos',
			icon: Icons.dashboard_outlined,
			selectedIcon: Icons.dashboard_rounded,
			route: '/panol/dashboard',
		),
		_PanolTab(
			id: 'pedidos',
			label: 'Pedidos',
			caption: 'Gestión',
			icon: Icons.receipt_long_outlined,
			selectedIcon: Icons.receipt_long_rounded,
			route: '/panol/pedidos',
		),
		_PanolTab(
			id: 'stock',
			label: 'Stock',
			caption: 'Inventario',
			icon: Icons.inventory_2_outlined,
			selectedIcon: Icons.inventory_2_rounded,
			route: '/panol/stock',
		),
		_PanolTab(
			id: 'seguimiento',
			label: 'Seguimiento',
			caption: 'Movimientos',
			icon: Icons.timeline_outlined,
			selectedIcon: Icons.timeline_rounded,
			route: '/panol/seguimiento',
		),
	];

	String get _selectedId {
		if (location == '/panol' || location == '/panol/') return 'inicio';
		if (location.startsWith('/panol/dashboard')) return 'dashboard';
		if (location.startsWith('/panol/pedidos') ||
				location.startsWith('/solicitudes-materiales')) {
			return 'pedidos';
		}
		if (location.startsWith('/panol/seguimiento')) return 'seguimiento';
		if (location.startsWith('/panol/stock')) return 'stock';
		return 'inicio';
	}

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final user = ref.watch(authControllerProvider).session?.usuario;
		final ui = PanolUi.of(context);
		final width = MediaQuery.sizeOf(context).width;
		final isWide = width >= Breakpoints.tablet;
		final selectedId = _selectedId;
		final isHome = selectedId == 'inicio';
		final isDark = Theme.of(context).brightness == Brightness.dark;

		void go(String route) {
			if (location == route) return;
			context.go(route);
		}

		Future<void> logout() async {
			await ref.read(authControllerProvider.notifier).logout();
			if (context.mounted) context.go('/login');
		}

		final topBar = Container(
			height: 64,
			padding: const EdgeInsets.symmetric(horizontal: 20),
			decoration: BoxDecoration(
				color: ui.surface,
				border: Border(bottom: BorderSide(color: ui.border)),
			),
			child: SafeArea(
				bottom: false,
				child: Row(
					children: [
						const ShellBackButton(),
						const SizedBox(width: 4),
						InkWell(
							onTap: () => go('/panol'),
							borderRadius: BorderRadius.circular(8),
							child: Padding(
								padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
								child: Row(
									children: [
										const SizedBox(
											width: 10,
											height: 10,
											child: DecoratedBox(
												decoration: BoxDecoration(
													color: AppColors.brandYellow,
													shape: BoxShape.circle,
												),
											),
										),
										const SizedBox(width: 10),
										Text(
											'Pañol',
											style: TextStyle(
												color: ui.ink,
												fontWeight: FontWeight.w800,
												fontSize: 18,
												letterSpacing: -0.3,
											),
										),
									],
								),
							),
						),
						const SizedBox(width: 10),
						Container(
							padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
							decoration: BoxDecoration(
								color: ui.softYellow,
								borderRadius: BorderRadius.circular(6),
							),
							child: Text(
								(user?.sucursalNombre ?? 'Operaciones').toUpperCase(),
								style: TextStyle(
									fontSize: 10,
									fontWeight: FontWeight.w700,
									letterSpacing: 0.6,
									color: ui.isDark
											? AppColors.brandYellow
											: const Color(0xFF8A6200),
								),
							),
						),
						const Spacer(),
						IconButton(
							tooltip: isDark ? 'Tema claro' : 'Tema oscuro',
							onPressed: () {
								ref.read(themeControllerProvider.notifier).setMode(
											isDark ? ThemeMode.light : ThemeMode.dark,
										);
							},
							icon: Icon(
								isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
								color: ui.ink,
							),
						),
						const SizedBox(width: 4),
						PopupMenuButton<String>(
							tooltip: 'Cuenta',
							onSelected: (value) {
								if (value == 'home') context.go('/home');
								if (value == 'compras') context.go('/compras');
								if (value == 'perfil') context.go('/perfil');
								if (value == 'logout') logout();
							},
							itemBuilder: (context) => const [
								PopupMenuItem(value: 'home', child: Text('Inicio app')),
								PopupMenuItem(value: 'compras', child: Text('Compras')),
								PopupMenuItem(value: 'perfil', child: Text('Perfil')),
								PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
							],
							child: Container(
								padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
								decoration: BoxDecoration(
									color: ui.chipBg,
									borderRadius: BorderRadius.circular(999),
									border: Border.all(color: ui.border),
								),
								child: Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										CircleAvatar(
											radius: 13,
											backgroundColor: PanolUi.rail,
											child: Text(
												(user?.nombreUsuario ?? 'P')
														.substring(0, 1)
														.toUpperCase(),
												style: const TextStyle(
													color: AppColors.brandYellow,
													fontWeight: FontWeight.w800,
													fontSize: 12,
												),
											),
										),
										const SizedBox(width: 8),
										Text(
											user?.nombreUsuario ?? 'pañol',
											style: TextStyle(
												fontWeight: FontWeight.w600,
												fontSize: 13,
												color: ui.ink,
											),
										),
										const SizedBox(width: 4),
										Icon(Icons.expand_more, size: 18, color: ui.muted),
									],
								),
							),
						),
					],
				),
			),
		);

		final rail = Container(
			width: 220,
			color: PanolUi.rail,
			child: SafeArea(
				right: false,
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Padding(
							padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									const Text(
										'OPERACIÓN',
										style: TextStyle(
											color: PanolUi.railText,
											fontSize: 11,
											fontWeight: FontWeight.w700,
											letterSpacing: 1.1,
										),
									),
									const SizedBox(height: 6),
									Text(
										user?.perfilNombre ?? 'Pañolero',
										style: const TextStyle(
											color: Colors.white,
											fontWeight: FontWeight.w700,
											fontSize: 15,
										),
									),
								],
							),
						),
						const SizedBox(height: 12),
						for (final tab in _tabs)
							_RailItem(
								tab: tab,
								selected: tab.id == selectedId,
								onTap: () => go(tab.route),
							),
						const Spacer(),
					],
				),
			),
		);

		final mobileTabs = _tabs.where((t) => t.id != 'dashboard').toList();
		final mobileIndex = mobileTabs
				.indexWhere((t) => t.id == selectedId)
				.clamp(0, mobileTabs.length - 1);
		final showBottomNav = !isWide && !isHome;

		return ShellBackScope(
			location: location,
			homeRoute: '/panol',
			child: Scaffold(
			backgroundColor: ui.canvas,
			body: IconTheme(
				data: IconThemeData(color: ui.ink),
				child: DefaultTextStyle(
					style: TextStyle(
						color: ui.ink,
						fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
					),
					child: Column(
						children: [
							topBar,
							Expanded(
								child: isWide
										? Row(
												children: [
													rail,
													Expanded(child: child),
												],
											)
										: child,
							),
						],
					),
				),
			),
			bottomNavigationBar: !showBottomNav
					? null
					: Container(
							decoration: const BoxDecoration(
								color: PanolUi.rail,
								border: Border(top: BorderSide(color: Color(0xFF2A2F38))),
							),
							child: NavigationBarTheme(
								data: NavigationBarThemeData(
									labelTextStyle: WidgetStateProperty.resolveWith((states) {
										final selected = states.contains(WidgetState.selected);
										return TextStyle(
											fontSize: 12,
											fontWeight: FontWeight.w600,
											color: selected
													? AppColors.brandYellow
													: PanolUi.railText,
										);
									}),
									iconTheme: WidgetStateProperty.resolveWith((states) {
										final selected = states.contains(WidgetState.selected);
										return IconThemeData(
											color: selected
													? AppColors.brandYellow
													: PanolUi.railText,
										);
									}),
								),
								child: NavigationBar(
									height: 68,
									backgroundColor: PanolUi.rail,
									indicatorColor: AppColors.brandYellow.withValues(alpha: 0.18),
									selectedIndex: mobileIndex,
									labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
									onDestinationSelected: (index) => go(mobileTabs[index].route),
									destinations: [
										for (final tab in mobileTabs)
											NavigationDestination(
												icon: Icon(tab.icon),
												selectedIcon: Icon(tab.selectedIcon),
												label: tab.label,
											),
									],
								),
							),
						),
			),
		);
	}
}

class _PanolTab {
	const _PanolTab({
		required this.id,
		required this.label,
		required this.caption,
		required this.icon,
		required this.selectedIcon,
		required this.route,
	});

	final String id;
	final String label;
	final String caption;
	final IconData icon;
	final IconData selectedIcon;
	final String route;
}

class _RailItem extends StatelessWidget {
	const _RailItem({
		required this.tab,
		required this.selected,
		required this.onTap,
	});

	final _PanolTab tab;
	final bool selected;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
			child: Material(
				color: selected ? PanolUi.railElevated : Colors.transparent,
				borderRadius: BorderRadius.circular(12),
				child: InkWell(
					onTap: onTap,
					borderRadius: BorderRadius.circular(12),
					child: AnimatedContainer(
						duration: const Duration(milliseconds: 180),
						padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
						decoration: BoxDecoration(
							borderRadius: BorderRadius.circular(12),
							border: Border(
								left: BorderSide(
									width: 3,
									color: selected ? AppColors.brandYellow : Colors.transparent,
								),
							),
						),
						child: Row(
							children: [
								Icon(
									selected ? tab.selectedIcon : tab.icon,
									color: selected ? AppColors.brandYellow : PanolUi.railText,
									size: 22,
								),
								const SizedBox(width: 12),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												tab.label,
												style: TextStyle(
													color: selected ? Colors.white : const Color(0xFFD1D5DB),
													fontWeight: FontWeight.w700,
													fontSize: 14,
												),
											),
											Text(
												tab.caption,
												style: const TextStyle(
													color: PanolUi.railText,
													fontSize: 11,
												),
											),
										],
									),
								),
							],
						),
					),
				),
			),
		);
	}
}
