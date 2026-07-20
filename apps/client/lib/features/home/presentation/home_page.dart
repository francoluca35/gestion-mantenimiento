import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/sika_logo.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class HomePage extends ConsumerStatefulWidget {
	const HomePage({super.key});

	@override
	ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
	Map<String, dynamic>? _resumenOt;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) => _loadResumen());
	}

	Future<void> _loadResumen() async {
		final user = ref.read(authControllerProvider).session?.usuario;
		final canOt =
				user?.tieneDerecho('programacion.ordenes_trabajo.buscar_y_actualizar') == true;

		if (!canOt) return;

		try {
			final now = DateTime.now();
			final desde = DateTime(now.year, now.month, 1);
			final hasta = DateTime(now.year, now.month + 1, 0);
			final query =
					'?fechaDesde=${desde.year}-${desde.month.toString().padLeft(2, '0')}-${desde.day.toString().padLeft(2, '0')}'
					'&fechaHasta=${hasta.year}-${hasta.month.toString().padLeft(2, '0')}-${hasta.day.toString().padLeft(2, '0')}';
			final resumen = await ref.read(apiClientProvider).getJson('ot/resumen$query');
			if (mounted) setState(() => _resumenOt = resumen);
		} catch (_) {}
	}

	@override
	Widget build(BuildContext context) {
		final user = ref.watch(authControllerProvider).session?.usuario;
		final canConfig = user?.tieneDerecho('configuracion.usuarios.listar') == true ||
				user?.esAdministrador == true;
		final canPlanta = user?.tieneDerecho('archivos.equipos.listar') == true ||
				user?.esAdministrador == true;
		final canOt =
				user?.tieneDerecho('programacion.ordenes_trabajo.buscar_y_actualizar') == true ||
				user?.esAdministrador == true;
		final canStock =
				user?.tieneDerecho('stock.materiales_en_stock.ver') == true ||
				user?.esAdministrador == true;
		final canSolicitudesMateriales =
				user?.tieneDerecho('stock.pañol.solicitudes_materiales.ver_pendientes') == true ||
				user?.esAdministrador == true;
		final planta = user?.sucursalNombre ?? 'Sin planta';
		final perfil = user?.perfilNombre ??
				(user?.esAdministrador == true ? 'Administrador' : 'Usuario');

		final otPendientes = _resumenOt?['pendientes'] ?? 0;
		final otEnEjecucion = _resumenOt?['enEjecucion'] ?? 0;

		return LayoutBuilder(
			builder: (context, constraints) {
				final wide = constraints.maxWidth >= 900;

				return ListView(
					padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
					children: [
						_WelcomeBanner(
							nombre: user?.nombreUsuario ?? '',
							perfil: perfil,
							planta: planta,
						),
						const SizedBox(height: 32),
						Text(
							'Accesos rápidos',
							style: Theme.of(context).textTheme.titleLarge?.copyWith(
										fontWeight: FontWeight.w700,
										color: Colors.white,
									),
						),
						const SizedBox(height: 16),
						if (wide)
							IntrinsicHeight(
								child: Row(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										if (canPlanta)
											Expanded(
												child: _ModuleCard(
													title: 'Gestión de equipos',
													subtitle: 'Ubicaciones, sectores y máquinas de tu planta',
													icon: Icons.precision_manufacturing_rounded,
													watermarkIcon: Icons.precision_manufacturing_outlined,
													color: AppColors.brandYellow,
													badge: planta,
													onTap: () => context.go('/planta'),
												),
											),
										if (canPlanta && canOt) const SizedBox(width: 20),
										if (canOt)
											Expanded(
												child: _ModuleCard(
													title: 'Órdenes de trabajo',
													subtitle: 'Emitir, asignar y cerrar OT',
													icon: Icons.assignment_rounded,
													watermarkIcon: Icons.assignment_outlined,
													color: AppColors.accent,
													badge: otPendientes > 0
															? '$otPendientes pendientes'
															: 'Activo',
													onTap: () => context.go('/ot'),
												),
											),
										if (canConfig && (canPlanta || canOt)) const SizedBox(width: 20),
										if (canConfig)
											Expanded(
												child: _ModuleCard(
													title: 'Configuración',
													subtitle: 'Usuarios, perfiles y permisos',
													icon: Icons.settings_rounded,
													watermarkIcon: Icons.settings_outlined,
													color: AppColors.secondaryLight,
													onTap: () => context.go('/config'),
												),
											),
										if (canStock && (canPlanta || canOt || canConfig))
											const SizedBox(width: 20),
										if (canStock)
											Expanded(
												child: _ModuleCard(
													title: 'Stock / Pañol',
													subtitle: 'Materiales, mínimos y reservas',
													icon: Icons.inventory_2_rounded,
													watermarkIcon: Icons.inventory_2_outlined,
													color: AppColors.brandYellow,
													onTap: () => context.go('/stock'),
												),
											),
										if (canSolicitudesMateriales &&
												(canPlanta || canOt || canConfig || canStock))
											const SizedBox(width: 20),
										if (canSolicitudesMateriales)
											Expanded(
												child: _ModuleCard(
													title: 'Solicitudes materiales',
													subtitle: 'Aprobar o rechazar pedidos de OT',
													icon: Icons.shopping_bag_rounded,
													watermarkIcon: Icons.shopping_bag_outlined,
													color: AppColors.accent,
													onTap: () => context.go('/solicitudes-materiales'),
												),
											),
									],
								),
							)
						else
							Column(
								children: [
									if (canPlanta)
										_ModuleCard(
											title: 'Gestión de equipos',
											subtitle: 'Ubicaciones, sectores y máquinas de tu planta',
											icon: Icons.precision_manufacturing_rounded,
											watermarkIcon: Icons.precision_manufacturing_outlined,
											color: AppColors.brandYellow,
											badge: planta,
											onTap: () => context.go('/planta'),
										),
									if (canPlanta && canOt) const SizedBox(height: 16),
									if (canOt)
										_ModuleCard(
											title: 'Órdenes de trabajo',
											subtitle: 'Emitir, asignar y cerrar OT',
											icon: Icons.assignment_rounded,
											watermarkIcon: Icons.assignment_outlined,
											color: AppColors.accent,
											badge: otPendientes > 0
													? '$otPendientes pendientes'
													: 'Activo',
											onTap: () => context.go('/ot'),
										),
									if (canConfig && (canPlanta || canOt)) const SizedBox(height: 16),
									if (canConfig)
										_ModuleCard(
											title: 'Configuración',
											subtitle: 'Usuarios, perfiles y permisos',
											icon: Icons.settings_rounded,
											watermarkIcon: Icons.settings_outlined,
											color: AppColors.secondaryLight,
											onTap: () => context.go('/config'),
										),
									if (canStock && (canPlanta || canOt || canConfig))
										const SizedBox(height: 16),
									if (canStock)
										_ModuleCard(
											title: 'Stock / Pañol',
											subtitle: 'Materiales, mínimos y reservas',
											icon: Icons.inventory_2_rounded,
											watermarkIcon: Icons.inventory_2_outlined,
											color: AppColors.brandYellow,
											onTap: () => context.go('/stock'),
										),
									if (canSolicitudesMateriales &&
											(canPlanta || canOt || canConfig || canStock))
										const SizedBox(height: 16),
									if (canSolicitudesMateriales)
										_ModuleCard(
											title: 'Solicitudes materiales',
											subtitle: 'Aprobar o rechazar pedidos de OT',
											icon: Icons.shopping_bag_rounded,
											watermarkIcon: Icons.shopping_bag_outlined,
											color: AppColors.accent,
											onTap: () => context.go('/solicitudes-materiales'),
										),
								],
							),
						const SizedBox(height: 36),
						Text(
							'Estado del sistema',
							style: Theme.of(context).textTheme.titleLarge?.copyWith(
										fontWeight: FontWeight.w700,
										color: Colors.white,
									),
						),
						const SizedBox(height: 16),
						wide
								? Row(
										children: [
											Expanded(
												child: _StatusCard(
													icon: Icons.shield_outlined,
													label: 'Seguridad',
													value: 'Activo',
													color: AppColors.success,
												),
											),
											const SizedBox(width: 16),
											Expanded(
												child: _StatusCard(
													icon: Icons.factory_outlined,
													label: 'Planta',
													value: 'Activo',
													color: AppColors.success,
												),
											),
											const SizedBox(width: 16),
											Expanded(
												child: _StatusCard(
													icon: Icons.assignment_outlined,
													label: 'OT',
													value: canOt
															? '$otPendientes pend. · $otEnEjecucion activas'
															: 'Sin acceso',
													color: canOt ? AppColors.success : AppColors.secondaryLight,
												),
											),
											const SizedBox(width: 16),
											Expanded(
												child: _StatusCard(
													icon: Icons.inventory_2_outlined,
													label: 'Pañol',
													value: 'Pendiente',
													color: AppColors.warning,
												),
											),
										],
									)
								: Wrap(
										spacing: 12,
										runSpacing: 12,
										children: [
											_StatusCard(
												icon: Icons.shield_outlined,
												label: 'Seguridad',
												value: 'Activo',
												color: AppColors.success,
												compact: true,
											),
											_StatusCard(
												icon: Icons.factory_outlined,
												label: 'Planta',
												value: 'Activo',
												color: AppColors.success,
												compact: true,
											),
											_StatusCard(
												icon: Icons.assignment_outlined,
												label: 'OT',
												value: canOt
														? '$otPendientes pend. · $otEnEjecucion activas'
														: 'Sin acceso',
												color: canOt ? AppColors.success : AppColors.secondaryLight,
												compact: true,
											),
											_StatusCard(
												icon: Icons.inventory_2_outlined,
												label: 'Pañol',
												value: 'Pendiente',
												color: AppColors.warning,
												compact: true,
											),
										],
									),
						const SizedBox(height: 48),
						const Center(
							child: SikaLogo(
								size: 36,
								showTagline: true,
								taglineColor: AppColors.accent,
							),
						),
					],
				);
			},
		);
	}
}

class _WelcomeBanner extends StatelessWidget {
	const _WelcomeBanner({
		required this.nombre,
		required this.perfil,
		required this.planta,
	});

	final String nombre;
	final String perfil;
	final String planta;

	@override
	Widget build(BuildContext context) {
		return ClipRRect(
			borderRadius: BorderRadius.circular(20),
			child: Stack(
				children: [
					Container(
						width: double.infinity,
						padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
						decoration: const BoxDecoration(
							gradient: LinearGradient(
								colors: [AppColors.brandYellow, AppColors.brandRed],
								begin: Alignment.centerLeft,
								end: Alignment.centerRight,
							),
						),
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												'Hola, $nombre',
												style: Theme.of(context).textTheme.headlineMedium?.copyWith(
															color: Colors.white,
															fontWeight: FontWeight.w800,
														),
											),
											const SizedBox(height: 8),
											Text(
												perfil,
												style: TextStyle(
													color: Colors.white.withValues(alpha: 0.92),
													fontSize: 16,
													fontWeight: FontWeight.w500,
												),
											),
											if (planta.isNotEmpty) ...[
												const SizedBox(height: 8),
												Row(
													children: [
														Icon(
															Icons.location_on_outlined,
															size: 16,
															color: Colors.white.withValues(alpha: 0.85),
														),
														const SizedBox(width: 4),
														Text(
															planta,
															style: TextStyle(
																color: Colors.white.withValues(alpha: 0.85),
																fontSize: 14,
																fontWeight: FontWeight.w500,
															),
														),
													],
												),
											],
										],
									),
								),
								const SizedBox(width: 16),
								Container(
									width: 56,
									height: 56,
									decoration: BoxDecoration(
										color: Colors.white.withValues(alpha: 0.2),
										borderRadius: BorderRadius.circular(16),
									),
									child: const Icon(
										Icons.factory_rounded,
										color: Colors.white,
										size: 28,
									),
								),
							],
						),
					),
					Positioned(
						right: 80,
						top: -20,
						bottom: -20,
						child: Opacity(
							opacity: 0.18,
							child: CustomPaint(
								size: const Size(140, 140),
								painter: const _SikaTrianglePainter(),
							),
						),
					),
				],
			),
		);
	}
}

class _SikaTrianglePainter extends CustomPainter {
	const _SikaTrianglePainter();

	@override
	void paint(Canvas canvas, Size size) {
		final path = Path()
				..moveTo(size.width * 0.5, 0)
				..lineTo(size.width, size.height)
				..lineTo(0, size.height)
				..close();
		canvas.drawPath(path, Paint()..color = Colors.white);
	}

	@override
	bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModuleCard extends StatelessWidget {
	const _ModuleCard({
		required this.title,
		required this.subtitle,
		required this.icon,
		required this.watermarkIcon,
		required this.color,
		this.badge,
		this.onTap,
	});

	final String title;
	final String subtitle;
	final IconData icon;
	final IconData watermarkIcon;
	final Color color;
	final String? badge;
	final VoidCallback? onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: AppColors.cardDark,
			borderRadius: BorderRadius.circular(20),
			child: InkWell(
				borderRadius: BorderRadius.circular(20),
				onTap: onTap,
				child: Container(
					constraints: const BoxConstraints(minHeight: 200),
					padding: const EdgeInsets.all(24),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(20),
						border: Border.all(color: const Color(0xFF2E2E2E)),
					),
					child: Stack(
						clipBehavior: Clip.none,
						children: [
							Positioned(
								right: -8,
								bottom: -8,
								child: Icon(
									watermarkIcon,
									size: 120,
									color: Colors.white.withValues(alpha: 0.04),
								),
							),
							Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										children: [
											Container(
												width: 48,
												height: 48,
												decoration: BoxDecoration(
													color: color.withValues(alpha: 0.15),
													borderRadius: BorderRadius.circular(14),
												),
												child: Icon(icon, color: color, size: 26),
											),
											const Spacer(),
											if (badge != null)
												Container(
													padding: const EdgeInsets.symmetric(
														horizontal: 12,
														vertical: 5,
													),
													decoration: BoxDecoration(
														color: color.withValues(alpha: 0.12),
														borderRadius: BorderRadius.circular(999),
														border: Border.all(
															color: color.withValues(alpha: 0.35),
														),
													),
													child: Text(
														badge!,
														style: TextStyle(
															color: color,
															fontSize: 11,
															fontWeight: FontWeight.w700,
														),
													),
												),
										],
									),
									const SizedBox(height: 20),
									Text(
										title,
										style: const TextStyle(
											color: Colors.white,
											fontWeight: FontWeight.w700,
											fontSize: 18,
										),
									),
									const SizedBox(height: 8),
									Text(
										subtitle,
										style: TextStyle(
											color: Colors.white.withValues(alpha: 0.55),
											fontSize: 14,
											height: 1.4,
										),
									),
									const SizedBox(height: 20),
									Row(
										mainAxisSize: MainAxisSize.min,
										children: [
											Text(
												'Abrir',
												style: TextStyle(
													color: color,
													fontWeight: FontWeight.w700,
													fontSize: 14,
												),
											),
											const SizedBox(width: 4),
											Icon(Icons.arrow_forward_rounded, size: 16, color: color),
										],
									),
								],
							),
						],
					),
				),
			),
		);
	}
}

class _StatusCard extends StatelessWidget {
	const _StatusCard({
		required this.icon,
		required this.label,
		required this.value,
		required this.color,
		this.compact = false,
	});

	final IconData icon;
	final String label;
	final String value;
	final Color color;
	final bool compact;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: compact ? 160 : null,
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: AppColors.cardDark,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: const Color(0xFF2E2E2E)),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 22),
					const SizedBox(height: 12),
					Text(
						label,
						style: const TextStyle(
							color: Colors.white,
							fontWeight: FontWeight.w700,
							fontSize: 15,
						),
					),
					const SizedBox(height: 8),
					Row(
						children: [
							Container(
								width: 8,
								height: 8,
								decoration: BoxDecoration(color: color, shape: BoxShape.circle),
							),
							const SizedBox(width: 8),
							Expanded(
								child: Text(
									value,
									style: TextStyle(
										color: color,
										fontWeight: FontWeight.w600,
										fontSize: 13,
									),
								),
							),
						],
					),
				],
			),
		);
	}
}
