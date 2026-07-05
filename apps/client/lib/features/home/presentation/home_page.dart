import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class HomePage extends ConsumerWidget {
	const HomePage({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final user = ref.watch(authControllerProvider).session?.usuario;
		final canConfig = user?.tieneDerecho('configuracion.usuarios.listar') == true ||
				user?.esAdministrador == true;
		final canPlanta = user?.tieneDerecho('archivos.equipos.listar') == true ||
				user?.esAdministrador == true;
		final planta = user?.sucursalNombre ?? 'Sin planta';
		final perfil = user?.perfilNombre ??
				(user?.esAdministrador == true ? 'Administrador' : 'Usuario');

		return ListView(
			padding: const EdgeInsets.all(24),
			children: [
				_WelcomeBanner(
					nombre: user?.nombreUsuario ?? '',
					perfil: perfil,
					planta: planta,
				),
				const SizedBox(height: 24),
				Text(
					'Accesos rápidos',
					style: Theme.of(context).textTheme.titleMedium?.copyWith(
								fontWeight: FontWeight.w700,
							),
				),
				const SizedBox(height: 12),
				LayoutBuilder(
					builder: (context, constraints) {
						final wide = constraints.maxWidth >= 900;
						final cards = <Widget>[
							if (canPlanta)
								_ModuleCard(
									title: 'Gestión de equipos',
									subtitle: 'Ubicaciones, sectores y máquinas de tu planta',
									icon: Icons.precision_manufacturing_rounded,
									color: AppColors.primary,
									badge: planta,
									onTap: () => context.go('/planta'),
								),
							_ModuleCard(
								title: 'Órdenes de trabajo',
								subtitle: 'Emitir, asignar y cerrar OT — próximo módulo',
								icon: Icons.assignment_rounded,
								color: const Color(0xFF7C3AED),
								badge: 'Próximamente',
								onTap: () => context.go('/ot'),
							),
							if (canConfig)
								_ModuleCard(
									title: 'Configuración',
									subtitle: 'Usuarios, perfiles y permisos',
									icon: Icons.settings_rounded,
									color: AppColors.secondary,
									onTap: () => context.go('/config'),
								),
						];

						if (wide) {
							return Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: cards
										.map(
											(card) => Expanded(
												child: Padding(
													padding: const EdgeInsets.only(right: 12),
													child: card,
												),
											),
										)
										.toList(),
							);
						}

						return Column(
							children: cards
									.map(
										(card) => Padding(
											padding: const EdgeInsets.only(bottom: 12),
											child: card,
										),
									)
									.toList(),
						);
					},
				),
				const SizedBox(height: 24),
				Text(
					'Estado del sistema',
					style: Theme.of(context).textTheme.titleMedium?.copyWith(
								fontWeight: FontWeight.w700,
							),
				),
				const SizedBox(height: 12),
				const Wrap(
					spacing: 12,
					runSpacing: 12,
					children: [
						_StatusPill(label: 'Seguridad', value: 'Activo', color: AppColors.success),
						_StatusPill(label: 'Planta', value: 'Activo', color: AppColors.success),
						_StatusPill(label: 'OT', value: 'Pendiente', color: AppColors.warning),
						_StatusPill(label: 'Pañol', value: 'Pendiente', color: AppColors.secondary),
					],
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
		return Container(
			padding: const EdgeInsets.all(24),
			decoration: BoxDecoration(
				gradient: const LinearGradient(
					colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
				borderRadius: BorderRadius.circular(20),
			),
			child: Row(
				children: [
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Hola, $nombre',
									style: Theme.of(context).textTheme.headlineSmall?.copyWith(
												color: Colors.white,
												fontWeight: FontWeight.w700,
											),
								),
								const SizedBox(height: 8),
								Text(
									perfil,
									style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
								),
								if (planta.isNotEmpty) ...[
									const SizedBox(height: 4),
									Text(
										planta,
										style: TextStyle(
											color: Colors.white.withValues(alpha: 0.7),
											fontSize: 13,
										),
									),
								],
							],
						),
					),
					Container(
						width: 56,
						height: 56,
						decoration: BoxDecoration(
							color: Colors.white.withValues(alpha: 0.15),
							borderRadius: BorderRadius.circular(16),
						),
						child: const Icon(Icons.factory_rounded, color: Colors.white, size: 28),
					),
				],
			),
		);
	}
}

class _ModuleCard extends StatelessWidget {
	const _ModuleCard({
		required this.title,
		required this.subtitle,
		required this.icon,
		required this.color,
		this.badge,
		this.onTap,
	});

	final String title;
	final String subtitle;
	final IconData icon;
	final Color color;
	final String? badge;
	final VoidCallback? onTap;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: Theme.of(context).colorScheme.surface,
			borderRadius: BorderRadius.circular(20),
			child: InkWell(
				borderRadius: BorderRadius.circular(20),
				onTap: onTap,
				child: Container(
					padding: const EdgeInsets.all(20),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(20),
						border: Border.all(
							color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
						),
					),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Container(
										width: 44,
										height: 44,
										decoration: BoxDecoration(
											color: color.withValues(alpha: 0.12),
											borderRadius: BorderRadius.circular(12),
										),
										child: Icon(icon, color: color),
									),
									const Spacer(),
									if (badge != null)
										Container(
											padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
											decoration: BoxDecoration(
												color: color.withValues(alpha: 0.1),
												borderRadius: BorderRadius.circular(999),
											),
											child: Text(
												badge!,
												style: TextStyle(
													color: color,
													fontSize: 11,
													fontWeight: FontWeight.w600,
												),
											),
										),
								],
							),
							const SizedBox(height: 16),
							Text(
								title,
								style: Theme.of(context).textTheme.titleMedium?.copyWith(
											fontWeight: FontWeight.w700,
										),
							),
							const SizedBox(height: 6),
							Text(
								subtitle,
								style: Theme.of(context).textTheme.bodySmall?.copyWith(
											color: Theme.of(context).colorScheme.onSurfaceVariant,
										),
							),
							const SizedBox(height: 16),
							Row(
								children: [
									Text(
										'Abrir',
										style: TextStyle(color: color, fontWeight: FontWeight.w600),
									),
									const SizedBox(width: 4),
									Icon(Icons.arrow_forward_rounded, size: 16, color: color),
								],
							),
						],
					),
				),
			),
		);
	}
}

class _StatusPill extends StatelessWidget {
	const _StatusPill({
		required this.label,
		required this.value,
		required this.color,
	});

	final String label;
	final String value;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surface,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(
					color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
				),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(
						width: 8,
						height: 8,
						decoration: BoxDecoration(color: color, shape: BoxShape.circle),
					),
					const SizedBox(width: 8),
					Text('$label · ', style: const TextStyle(fontWeight: FontWeight.w500)),
					Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
				],
			),
		);
	}
}
