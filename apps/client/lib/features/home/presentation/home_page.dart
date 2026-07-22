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
					padding: EdgeInsets.fromLTRB(
						wide ? 32 : 16,
						wide ? 28 : 16,
						wide ? 32 : 16,
						wide ? 40 : 24,
					),
					children: [
						_WelcomeBanner(
							nombre: user?.nombreUsuario ?? '',
							perfil: perfil,
							planta: planta,
						),
						const SizedBox(height: 32),
						const _SectionTitle(
							label: 'Accesos rápidos',
							color: AppColors.brandPurple,
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
													color: AppColors.brandGreenDark,
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
											color: AppColors.brandGreenDark,
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
						const _SectionTitle(
							label: 'Estado del sistema',
							color: AppColors.brandGreen,
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
						_BrandFooter(wide: wide),
					],
				);
			},
		);
	}
}

class _BrandFooter extends StatelessWidget {
	const _BrandFooter({required this.wide});

	final bool wide;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		final brand = Row(
			mainAxisSize: MainAxisSize.min,
			children: [
				const SikaLogo(size: 32, compact: true),
				const SizedBox(width: 12),
				Text.rich(
					const TextSpan(
						style: TextStyle(
							fontSize: 11,
							fontWeight: FontWeight.w800,
							letterSpacing: 0.8,
						),
						children: [
							TextSpan(
								text: 'MANTENIMIENTO',
								style: TextStyle(color: AppColors.brandPurple),
							),
							TextSpan(text: '  ·  '),
							TextSpan(
								text: 'STOCK',
								style: TextStyle(color: AppColors.brandGreenDark),
							),
							TextSpan(text: '  ·  '),
							TextSpan(
								text: 'EFICIENCIA',
								style: TextStyle(color: AppColors.brandOrange),
							),
						],
					),
				),
			],
		);

		final tagline = Text(
			'GESTIÓN INTELIGENTE · RESULTADOS GLOBALES',
			style: TextStyle(
				color: scheme.onSurface.withValues(alpha: 0.4),
				fontSize: 10.5,
				fontWeight: FontWeight.w600,
				letterSpacing: 1,
			),
		);

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: scheme.outline),
			),
			child: wide
					? Row(
							children: [
								brand,
								const Spacer(),
								tagline,
							],
						)
					: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								brand,
								const SizedBox(height: 10),
								tagline,
							],
						),
		);
	}
}

class _SectionTitle extends StatelessWidget {
	const _SectionTitle({required this.label, required this.color});

	final String label;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				Container(
					width: 4,
					height: 20,
					decoration: BoxDecoration(
						color: color,
						borderRadius: BorderRadius.circular(2),
					),
				),
				const SizedBox(width: 10),
				Text(
					label,
					style: Theme.of(context).textTheme.titleLarge?.copyWith(
								fontWeight: FontWeight.w700,
							),
				),
			],
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
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final fg = isDark ? Colors.white : AppColors.ink;

		final gradient = isDark
				? const LinearGradient(
						colors: [
							Color(0xFF3A0A52),
							Color(0xFF2A0838),
							Color(0xFF3D0E14),
						],
						begin: Alignment.centerLeft,
						end: Alignment.centerRight,
					)
				: const LinearGradient(
						colors: [
							Color(0xFFF3D9FF),
							Color(0xFFF8EAFB),
							Color(0xFFFFE8DE),
						],
						begin: Alignment.centerLeft,
						end: Alignment.centerRight,
					);

		return ClipRRect(
			borderRadius: BorderRadius.circular(20),
			child: Container(
				width: double.infinity,
				padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
				decoration: BoxDecoration(gradient: gradient),
				child: Row(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									if (planta.isNotEmpty) ...[
										Row(
											children: [
												Icon(
													Icons.location_on_outlined,
													size: 15,
													color: AppColors.brandOrange,
												),
												const SizedBox(width: 4),
												Text(
													planta,
													style: TextStyle(
														color: fg.withValues(alpha: 0.75),
														fontSize: 12.5,
														fontWeight: FontWeight.w700,
														letterSpacing: 0.6,
													),
												),
											],
										),
										const SizedBox(height: 10),
									],
									Text.rich(
										TextSpan(
											style: Theme.of(context)
													.textTheme
													.headlineMedium
													?.copyWith(
														color: fg,
														fontWeight: FontWeight.w800,
													),
											children: [
												const TextSpan(text: 'Hola, '),
												TextSpan(
													text: nombre,
													style: TextStyle(
														color: isDark
																? AppColors.brandPurple
																: AppColors.brandPurpleDark,
													),
												),
											],
										),
									),
									const SizedBox(height: 8),
									Text(
										'$perfil · Panel de control',
										style: TextStyle(
											color: fg.withValues(alpha: 0.65),
											fontSize: 15,
											fontWeight: FontWeight.w500,
										),
									),
								],
							),
						),
						const SizedBox(width: 16),
						const SikaLogo(size: 84, compact: true),
					],
				),
			),
		);
	}
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
		final scheme = Theme.of(context).colorScheme;
		final isDark = scheme.brightness == Brightness.dark;

		return Container(
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: scheme.outline),
			),
			clipBehavior: Clip.antiAlias,
			child: Material(
				color: Colors.transparent,
				child: InkWell(
					onTap: onTap,
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							Container(height: 3, color: color),
							Container(
								constraints: const BoxConstraints(minHeight: 196),
								padding: const EdgeInsets.all(24),
								child: Stack(
									clipBehavior: Clip.none,
									children: [
										Positioned(
											right: -8,
											bottom: -8,
											child: Icon(
												watermarkIcon,
												size: 120,
												color: scheme.onSurface.withValues(alpha: 0.04),
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
																color: color.withValues(
																	alpha: isDark ? 0.15 : 0.1,
																),
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
													style: TextStyle(
														color: scheme.onSurface,
														fontWeight: FontWeight.w700,
														fontSize: 18,
													),
												),
												const SizedBox(height: 8),
												Text(
													subtitle,
													style: TextStyle(
														color: scheme.onSurface.withValues(alpha: 0.55),
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
														Icon(
															Icons.arrow_forward_rounded,
															size: 16,
															color: color,
														),
													],
												),
											],
										),
									],
								),
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
		final scheme = Theme.of(context).colorScheme;

		return Container(
			width: compact ? 160 : null,
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: scheme.outline),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Icon(icon, color: scheme.onSurface.withValues(alpha: 0.7), size: 22),
					const SizedBox(height: 12),
					Text(
						label,
						style: TextStyle(
							color: scheme.onSurface,
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
