import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/sika_logo.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

String _humanizeLabel(String raw) {
	final cleaned = raw.replaceAll('_', ' ').trim();
	if (cleaned.isEmpty) return raw;
	return cleaned
			.split(RegExp(r'\s+'))
			.map((word) {
				if (word.isEmpty) return word;
				return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
			})
			.join(' ');
}

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
		final canSolicitudes =
				user?.tieneDerecho('programacion.solicitudes_trabajo.listar') == true ||
				user?.esAdministrador == true;
		final canCompras =
				user?.tieneDerecho('stock.ordenes_compra.buscar_y_actualizar') == true ||
				user?.tieneDerecho('stock.ordenes_compra.emitir') == true ||
				user?.esAdministrador == true;
		final canIndicadores = canOt;
		final canMisOt = canOt || user?.esTecnico == true;

		final planta = _humanizeLabel(user?.sucursalNombre ?? 'Sin planta');
		final perfil = _humanizeLabel(
			user?.perfilNombre ??
					(user?.esAdministrador == true ? 'Administrador' : 'Usuario'),
		);

		final otPendientes = (_resumenOt?['pendientes'] is int)
				? _resumenOt!['pendientes'] as int
				: 0;
		final otEnEjecucion = (_resumenOt?['enEjecucion'] is int)
				? _resumenOt!['enEjecucion'] as int
				: 0;
		final otRealizadas = (_resumenOt?['realizadas'] is int)
				? _resumenOt!['realizadas'] as int
				: 0;
		final solicitudesPendientes = (_resumenOt?['solicitudesPendientes'] is int)
				? _resumenOt!['solicitudesPendientes'] as int
				: 0;
		final cumplimientoPct = (_resumenOt?['cumplimientoPct'] is int)
				? _resumenOt!['cumplimientoPct'] as int
				: 0;
		final otSemana = (_resumenOt?['otSemana'] is int) ? _resumenOt!['otSemana'] as int : 0;
		final otMes = (_resumenOt?['otMes'] is int) ? _resumenOt!['otMes'] as int : 0;
		final otAnio = (_resumenOt?['otAnio'] is int) ? _resumenOt!['otAnio'] as int : 0;

		final modules = <_QuickLink>[
			if (canMisOt)
				_QuickLink(
					title: 'Mis OT',
					subtitle: 'Trabajos asignados a vos',
					icon: Icons.engineering_rounded,
					color: AppColors.accent,
					route: '/mis-ot',
				),
			if (canPlanta)
				_QuickLink(
					title: 'Equipos',
					subtitle: 'Planta, sectores y máquinas',
					icon: Icons.precision_manufacturing_rounded,
					color: AppColors.brandPurple,
					route: '/planta',
				),
			if (canOt)
				_QuickLink(
					title: 'Órdenes de trabajo',
					subtitle: otPendientes > 0
							? '$otPendientes pendientes este mes'
							: 'Emitir, asignar y cerrar',
					icon: Icons.assignment_rounded,
					color: AppColors.accent,
					route: '/ot',
					badge: otPendientes > 0 ? '$otPendientes' : null,
				),
			if (canIndicadores)
				_QuickLink(
					title: 'Indicadores',
					subtitle: 'Semana, mes, bandejas y carga',
					icon: Icons.insights_rounded,
					color: AppColors.brandPurpleDark,
					route: '/indicadores',
				),
			if (canSolicitudes)
				_QuickLink(
					title: 'Solicitudes de trabajo',
					subtitle: 'Conformidad y emisión',
					icon: Icons.campaign_rounded,
					color: AppColors.brandOrange,
					route: '/solicitudes',
				),
			if (canStock)
				_QuickLink(
					title: 'Stock / Pañol',
					subtitle: 'Materiales y reservas',
					icon: Icons.inventory_2_rounded,
					color: AppColors.brandGreenDark,
					route: user?.esPanolero == true ? '/panol' : '/stock',
				),
			if (canSolicitudesMateriales)
				_QuickLink(
					title: 'Pedidos materiales',
					subtitle: 'Aprobar o rechazar',
					icon: Icons.shopping_bag_rounded,
					color: AppColors.brandOrange,
					route: '/solicitudes-materiales',
				),
			if (canCompras)
				_QuickLink(
					title: 'Compras',
					subtitle: 'Proveedores y órdenes de compra',
					icon: Icons.local_shipping_rounded,
					color: AppColors.secondary,
					route: '/compras',
				),
			if (canConfig)
				_QuickLink(
					title: 'Configuración',
					subtitle: 'Usuarios, perfiles y permisos',
					icon: Icons.settings_rounded,
					color: AppColors.secondary,
					route: '/config',
				),
		];

		final isDark = Theme.of(context).brightness == Brightness.dark;
		final pageBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

		return ColoredBox(
			color: pageBg,
			child: LayoutBuilder(
				builder: (context, constraints) {
					final wide = constraints.maxWidth >= 960;
					final pad = wide ? 40.0 : 20.0;

					return ListView(
						padding: EdgeInsets.fromLTRB(pad, wide ? 36 : 20, pad, wide ? 48 : 28),
						children: [
							_HomeHeader(
								perfil: perfil,
								planta: planta,
								wide: wide,
							),
							if (canOt) ...[
								SizedBox(height: wide ? 28 : 22),
								_OpsPanel(
									semana: otSemana,
									mes: otMes,
									anio: otAnio,
									pendientes: otPendientes,
									enEjecucion: otEnEjecucion,
									realizadas: otRealizadas,
									cumplimientoPct: cumplimientoPct,
									solicitudes: canSolicitudes ? solicitudesPendientes : null,
									onOpenOt: () => context.go('/ot'),
									onOpenGraficos: () => context.go('/indicadores'),
									onOpenSolicitudes: canSolicitudes
											? () => context.go('/solicitudes')
											: null,
								),
							],
							SizedBox(height: wide ? 36 : 28),
							Text(
								'Módulos',
								style: Theme.of(context).textTheme.titleMedium?.copyWith(
											fontWeight: FontWeight.w800,
											letterSpacing: -0.2,
										),
							),
							const SizedBox(height: 14),
							_QuickLinksGrid(links: modules, wide: wide),
						],
					);
				},
			),
		);
	}
}

class _HomeHeader extends StatelessWidget {
	const _HomeHeader({
		required this.perfil,
		required this.planta,
		required this.wide,
	});

	final String perfil;
	final String planta;
	final bool wide;

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final fg = isDark ? Colors.white : AppColors.ink;
		final muted = fg.withValues(alpha: 0.55);
		final logoSize = wide ? 96.0 : 80.0;

		return Row(
			crossAxisAlignment: CrossAxisAlignment.center,
			children: [
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								planta,
								style: Theme.of(context).textTheme.headlineMedium?.copyWith(
											color: fg,
											fontWeight: FontWeight.w800,
											letterSpacing: -0.6,
											height: 1.15,
										),
							),
							const SizedBox(height: 6),
							Text(
								perfil,
								style: TextStyle(
									color: muted,
									fontSize: 15,
									fontWeight: FontWeight.w600,
								),
							),
						],
					),
				),
				const SizedBox(width: 16),
				SikaLogo(size: logoSize, compact: true),
			],
		);
	}
}

class _OpsPanel extends StatelessWidget {
	const _OpsPanel({
		required this.semana,
		required this.mes,
		required this.anio,
		required this.pendientes,
		required this.enEjecucion,
		required this.realizadas,
		required this.cumplimientoPct,
		required this.solicitudes,
		required this.onOpenOt,
		required this.onOpenGraficos,
		required this.onOpenSolicitudes,
	});

	final int semana;
	final int mes;
	final int anio;
	final int pendientes;
	final int enEjecucion;
	final int realizadas;
	final int cumplimientoPct;
	final int? solicitudes;
	final VoidCallback onOpenOt;
	final VoidCallback onOpenGraficos;
	final VoidCallback? onOpenSolicitudes;

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final scheme = Theme.of(context).colorScheme;
		final border = isDark ? AppColors.cardBorder : const Color(0xFFE2E6EC);
		final muted = scheme.onSurface.withValues(alpha: 0.52);

		return Container(
			width: double.infinity,
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
						child: Row(
							children: [
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												'CONTROL OPERATIVO',
												style: TextStyle(
													fontSize: 11,
													fontWeight: FontWeight.w800,
													letterSpacing: 0.9,
													color: muted,
												),
											),
											const SizedBox(height: 2),
											Text(
												'Órdenes de trabajo programadas',
												style: TextStyle(
													fontSize: 14,
													fontWeight: FontWeight.w700,
													color: scheme.onSurface,
												),
											),
										],
									),
								),
								TextButton(
									onPressed: onOpenOt,
									child: const Text('Ver OT'),
								),
							],
						),
					),
					Divider(height: 1, color: border),
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
						child: Row(
							children: [
								Expanded(
									child: _PeriodCell(
										label: 'SEMANA',
										value: '$semana',
										onTap: onOpenOt,
									),
								),
								Container(width: 1, height: 52, color: border),
								Expanded(
									child: _PeriodCell(
										label: 'MES',
										value: '$mes',
										onTap: onOpenOt,
										emphasize: true,
									),
								),
								Container(width: 1, height: 52, color: border),
								Expanded(
									child: _PeriodCell(
										label: 'AÑO',
										value: '$anio',
										onTap: onOpenOt,
									),
								),
							],
						),
					),
					Divider(height: 1, color: border),
					Padding(
						padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
						child: Wrap(
							spacing: 18,
							runSpacing: 10,
							crossAxisAlignment: WrapCrossAlignment.center,
							children: [
								_StatusChip(
									label: 'Pendientes',
									value: '$pendientes',
									color: AppColors.accent,
									onTap: onOpenOt,
								),
								_StatusChip(
									label: 'En curso',
									value: '$enEjecucion',
									color: AppColors.brandPurple,
									onTap: onOpenOt,
								),
								_StatusChip(
									label: 'Cerradas',
									value: '$realizadas',
									color: AppColors.brandGreen,
									onTap: onOpenOt,
								),
								_StatusChip(
									label: 'Cumplimiento',
									value: '$cumplimientoPct%',
									color: AppColors.brandPurpleDark,
									onTap: onOpenGraficos,
								),
								if (solicitudes != null && onOpenSolicitudes != null)
									_StatusChip(
										label: 'Solicitudes',
										value: '$solicitudes',
										color: const Color(0xFF38BDF8),
										onTap: onOpenSolicitudes!,
									),
							],
						),
					),
				],
			),
		);
	}
}

class _PeriodCell extends StatelessWidget {
	const _PeriodCell({
		required this.label,
		required this.value,
		required this.onTap,
		this.emphasize = false,
	});

	final String label;
	final String value;
	final VoidCallback onTap;
	final bool emphasize;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(8),
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
				child: Column(
					children: [
						Text(
							label,
							style: TextStyle(
								fontSize: 11,
								fontWeight: FontWeight.w700,
								letterSpacing: 0.6,
								color: scheme.onSurface.withValues(alpha: 0.45),
							),
						),
						const SizedBox(height: 4),
						Text(
							value,
							style: TextStyle(
								fontSize: emphasize ? 30 : 26,
								fontWeight: FontWeight.w800,
								height: 1,
								letterSpacing: -0.8,
								color: scheme.onSurface,
							),
						),
					],
				),
			),
		);
	}
}

class _StatusChip extends StatelessWidget {
	const _StatusChip({
		required this.label,
		required this.value,
		required this.color,
		required this.onTap,
	});

	final String label;
	final String value;
	final Color color;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(6),
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
				child: RichText(
					text: TextSpan(
						children: [
							TextSpan(
								text: '$label  ',
								style: TextStyle(
									fontSize: 12,
									fontWeight: FontWeight.w600,
									color: color.withValues(alpha: 0.85),
								),
							),
							TextSpan(
								text: value,
								style: TextStyle(
									fontSize: 13,
									fontWeight: FontWeight.w800,
									color: color,
								),
							),
						],
					),
				),
			),
		);
	}
}

class _QuickLink {
	const _QuickLink({
		required this.title,
		required this.subtitle,
		required this.icon,
		required this.color,
		required this.route,
		this.badge,
	});

	final String title;
	final String subtitle;
	final IconData icon;
	final Color color;
	final String route;
	final String? badge;
}

class _QuickLinksGrid extends StatelessWidget {
	const _QuickLinksGrid({required this.links, required this.wide});

	final List<_QuickLink> links;
	final bool wide;

	@override
	Widget build(BuildContext context) {
		if (links.isEmpty) {
			return Text(
				'Sin módulos disponibles para tu perfil.',
				style: TextStyle(
					color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
				),
			);
		}

		if (!wide) {
			return Column(
				children: [
					for (var i = 0; i < links.length; i++) ...[
						if (i > 0) const SizedBox(height: 10),
						_QuickLinkTile(link: links[i]),
					],
				],
			);
		}

		return LayoutBuilder(
			builder: (context, c) {
				final cols = c.maxWidth >= 1100 ? 3 : 2;
				return GridView.builder(
					shrinkWrap: true,
					physics: const NeverScrollableScrollPhysics(),
					itemCount: links.length,
					gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
						crossAxisCount: cols,
						mainAxisExtent: 96,
						crossAxisSpacing: 12,
						mainAxisSpacing: 12,
					),
					itemBuilder: (context, i) => _QuickLinkTile(link: links[i]),
				);
			},
		);
	}
}

class _QuickLinkTile extends StatelessWidget {
	const _QuickLinkTile({required this.link});

	final _QuickLink link;

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final scheme = Theme.of(context).colorScheme;

		return Material(
			color: scheme.surface,
			borderRadius: BorderRadius.circular(16),
			child: InkWell(
				onTap: () => context.go(link.route),
				borderRadius: BorderRadius.circular(16),
				child: Container(
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(16),
						border: Border.all(
							color: isDark ? AppColors.cardBorder : const Color(0xFFE8E0F0),
						),
					),
					child: Row(
						children: [
							Container(
								width: 44,
								height: 44,
								decoration: BoxDecoration(
									color: link.color.withValues(alpha: isDark ? 0.18 : 0.1),
									borderRadius: BorderRadius.circular(12),
								),
								child: Icon(link.icon, color: link.color, size: 22),
							),
							const SizedBox(width: 14),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Row(
											children: [
												Flexible(
													child: Text(
														link.title,
														maxLines: 1,
														overflow: TextOverflow.ellipsis,
														style: TextStyle(
															fontWeight: FontWeight.w700,
															fontSize: 15,
															color: scheme.onSurface,
														),
													),
												),
												if (link.badge != null) ...[
													const SizedBox(width: 8),
													Container(
														padding: const EdgeInsets.symmetric(
															horizontal: 8,
															vertical: 2,
														),
														decoration: BoxDecoration(
															color: AppColors.accent.withValues(alpha: 0.12),
															borderRadius: BorderRadius.circular(999),
														),
														child: Text(
															link.badge!,
															style: const TextStyle(
																color: AppColors.accent,
																fontSize: 11,
																fontWeight: FontWeight.w800,
															),
														),
													),
												],
											],
										),
										const SizedBox(height: 3),
										Text(
											link.subtitle,
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: TextStyle(
												fontSize: 13,
												color: scheme.onSurface.withValues(alpha: 0.5),
											),
										),
									],
								),
							),
							Icon(
								Icons.chevron_right_rounded,
								color: scheme.onSurface.withValues(alpha: 0.28),
							),
						],
					),
				),
			),
		);
	}
}
