import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';

/// Componentes visuales compartidos — Planta / Equipos (Sprint 2).
abstract final class PlantaUi {
	static const accentTeal = Color(0xFF0F766E);

	static String formatDate(dynamic value) {
		if (value == null) return '—';
		final parsed = DateTime.tryParse(value.toString());
		if (parsed == null) return value.toString();
		return DateFormat('dd/MM/yyyy').format(parsed);
	}

	static String tipoMantenimientoLabel(String? tipo) {
		return switch (tipo) {
			'preventivo' => 'Preventivo',
			'preventivo_no_periodico' => 'No periódico',
			'correctivo' => 'Correctivo',
			'predictivo' => 'Predictivo',
			'mejora' => 'Mejora',
			_ => tipo ?? '—',
		};
	}

	static Color tipoMantenimientoColor(String? tipo) {
		return switch (tipo) {
			'preventivo' => accentTeal,
			'preventivo_no_periodico' => const Color(0xFF0369A1),
			'correctivo' => AppColors.warning,
			'predictivo' => AppColors.brandRed,
			'mejora' => AppColors.success,
			_ => AppColors.secondary,
		};
	}

	static String periodicidadCorta(Map<String, dynamic>? proc) {
		if (proc == null) return '';
		final tipo = proc['periodicidadTipo'] as String?;
		final valor = proc['periodicidadValor'];
		if (tipo == 'tiempo' && valor != null) return 'Cada $valor días';
		if (tipo == 'contador' && valor != null) return 'Cada $valor u. contador';
		return 'Sin periodicidad';
	}
}

class PlantaSectionCard extends StatelessWidget {
	const PlantaSectionCard({
		super.key,
		required this.title,
		this.subtitle,
		this.trailing,
		required this.child,
	});

	final String title;
	final String? subtitle;
	final Widget? trailing;
	final Widget child;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											title,
											style: Theme.of(context).textTheme.titleSmall?.copyWith(
														fontWeight: FontWeight.w700,
													),
										),
										if (subtitle != null) ...[
											const SizedBox(height: 4),
											Text(
												subtitle!,
												style: TextStyle(
													fontSize: 13,
													color: scheme.onSurfaceVariant,
													height: 1.35,
												),
											),
										],
									],
								),
							),
							if (trailing != null) trailing!,
						],
					),
					const SizedBox(height: 14),
					child,
				],
			),
		);
	}
}

class PlantaEmptyState extends StatelessWidget {
	const PlantaEmptyState({
		super.key,
		required this.icon,
		required this.title,
		this.message,
		this.action,
	});

	final IconData icon;
	final String title;
	final String? message;
	final Widget? action;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(
						width: 52,
						height: 52,
						decoration: BoxDecoration(
							color: AppColors.brandYellow.withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(14),
						),
						child: Icon(icon, color: AppColors.brandYellow, size: 26),
					),
					const SizedBox(height: 12),
					Text(
						title,
						textAlign: TextAlign.center,
						style: Theme.of(context).textTheme.titleSmall?.copyWith(
									fontWeight: FontWeight.w700,
								),
					),
					if (message != null) ...[
						const SizedBox(height: 6),
						Text(
							message!,
							textAlign: TextAlign.center,
							style: TextStyle(
								fontSize: 13,
								color: scheme.onSurfaceVariant,
								height: 1.4,
							),
						),
					],
					if (action != null) ...[
						const SizedBox(height: 14),
						action!,
					],
				],
			),
		);
	}
}

class PlantaInfoPill extends StatelessWidget {
	const PlantaInfoPill({
		super.key,
		required this.label,
		required this.value,
		this.icon,
		this.color,
	});

	final String label;
	final String value;
	final IconData? icon;
	final Color? color;

	@override
	Widget build(BuildContext context) {
		final accent = color ?? PlantaUi.accentTeal;

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
			decoration: BoxDecoration(
				color: accent.withValues(alpha: 0.08),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: accent.withValues(alpha: 0.2)),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					if (icon != null) ...[
						Icon(icon, size: 18, color: accent),
						const SizedBox(width: 8),
					],
					Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								label,
								style: TextStyle(
									fontSize: 11,
									color: Theme.of(context).colorScheme.onSurfaceVariant,
								),
							),
							const SizedBox(height: 2),
							Text(
								value,
								style: TextStyle(
									fontWeight: FontWeight.w700,
									fontSize: 14,
									color: accent,
								),
							),
						],
					),
				],
			),
		);
	}
}

class PlantaTipoChip extends StatelessWidget {
	const PlantaTipoChip({super.key, required this.tipo});

	final String? tipo;

	@override
	Widget build(BuildContext context) {
		final color = PlantaUi.tipoMantenimientoColor(tipo);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				PlantaUi.tipoMantenimientoLabel(tipo),
				style: TextStyle(
					fontSize: 11,
					fontWeight: FontWeight.w700,
					color: color,
				),
			),
		);
	}
}

class PlantaProcTile extends StatelessWidget {
	const PlantaProcTile({
		super.key,
		required this.codigo,
		required this.nombre,
		this.tipo,
		this.subtitle,
		this.trailing,
	});

	final dynamic codigo;
	final String nombre;
	final String? tipo;
	final String? subtitle;
	final Widget? trailing;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Padding(
			padding: const EdgeInsets.only(bottom: 8),
			child: Material(
				color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
				borderRadius: BorderRadius.circular(12),
				child: Padding(
					padding: const EdgeInsets.all(12),
					child: Row(
						children: [
							Container(
								width: 40,
								height: 40,
								decoration: BoxDecoration(
									color: PlantaUi.tipoMantenimientoColor(tipo).withValues(alpha: 0.15),
									borderRadius: BorderRadius.circular(10),
								),
								child: Center(
									child: Text(
										'$codigo',
										style: TextStyle(
											fontWeight: FontWeight.w800,
											fontSize: 12,
											color: PlantaUi.tipoMantenimientoColor(tipo),
										),
									),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											nombre,
											style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
											maxLines: 2,
											overflow: TextOverflow.ellipsis,
										),
										if (subtitle != null) ...[
											const SizedBox(height: 4),
											Text(
												subtitle!,
												style: TextStyle(
													fontSize: 12,
													color: scheme.onSurfaceVariant,
												),
											),
										],
									],
								),
							),
							if (tipo != null) PlantaTipoChip(tipo: tipo),
							if (trailing != null) ...[
								const SizedBox(width: 8),
								trailing!,
							],
						],
					),
				),
			),
		);
	}
}

class PlantaHistorialTile extends StatelessWidget {
	const PlantaHistorialTile({
		super.key,
		required this.titulo,
		this.subtitulo,
		this.fecha,
		this.estado,
	});

	final String titulo;
	final String? subtitulo;
	final String? fecha;
	final String? estado;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Padding(
			padding: const EdgeInsets.only(bottom: 10),
			child: IntrinsicHeight(
				child: Row(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Column(
							children: [
								Container(
									width: 10,
									height: 10,
									margin: const EdgeInsets.only(top: 4),
									decoration: BoxDecoration(
										color: PlantaUi.accentTeal,
										shape: BoxShape.circle,
										border: Border.all(
											color: PlantaUi.accentTeal.withValues(alpha: 0.3),
											width: 3,
										),
									),
								),
								Expanded(
									child: Container(
										width: 2,
										margin: const EdgeInsets.only(top: 4),
										color: scheme.outlineVariant.withValues(alpha: 0.4),
									),
								),
							],
						),
						const SizedBox(width: 12),
						Expanded(
							child: Padding(
								padding: const EdgeInsets.only(bottom: 8),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Row(
											children: [
												Expanded(
													child: Text(
														titulo,
														style: const TextStyle(
															fontWeight: FontWeight.w700,
															fontSize: 13,
														),
													),
												),
												if (fecha != null)
													Text(
														fecha!,
														style: TextStyle(
															fontSize: 11,
															color: scheme.onSurfaceVariant,
														),
													),
											],
										),
										if (subtitulo != null && subtitulo!.isNotEmpty) ...[
											const SizedBox(height: 4),
											Text(
												subtitulo!,
												style: TextStyle(
													fontSize: 12,
													color: scheme.onSurfaceVariant,
													height: 1.35,
												),
											),
										],
										if (estado != null) ...[
											const SizedBox(height: 6),
											Text(
												estado!,
												style: const TextStyle(
													fontSize: 11,
													fontWeight: FontWeight.w600,
													color: AppColors.success,
												),
											),
										],
									],
								),
							),
						),
					],
				),
			),
		);
	}
}
