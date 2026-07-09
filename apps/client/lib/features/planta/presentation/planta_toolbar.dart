import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Barra de acciones contextual — lenguaje claro para operadores de planta.
class PlantaToolbar extends StatelessWidget {
	const PlantaToolbar({
		super.key,
		required this.plantaNombre,
		required this.onRefresh,
		this.sucursales = const [],
		this.sucursalId,
		this.onSucursalChanged,
		this.selectionKind,
		this.clipboardLabel,
		this.canAgregar = false,
		this.onAgregar,
		this.canModificar = false,
		this.onModificar,
		this.canEliminar = false,
		this.onEliminar,
		this.canMover = false,
		this.onMover,
		this.canCopiar = false,
		this.onCopiar,
		this.canCortar = false,
		this.onCortar,
		this.canPegar = false,
		this.onPegar,
		this.onBuscar,
		this.onImprimir,
		this.onExportar,
	});

	final String plantaNombre;
	final VoidCallback onRefresh;
	final List<Map<String, dynamic>> sucursales;
	final String? sucursalId;
	final ValueChanged<String?>? onSucursalChanged;
	final String? selectionKind;
	final String? clipboardLabel;
	final bool canAgregar;
	final VoidCallback? onAgregar;
	final bool canModificar;
	final VoidCallback? onModificar;
	final bool canEliminar;
	final VoidCallback? onEliminar;
	final bool canMover;
	final VoidCallback? onMover;
	final bool canCopiar;
	final VoidCallback? onCopiar;
	final bool canCortar;
	final VoidCallback? onCortar;
	final bool canPegar;
	final VoidCallback? onPegar;
	final VoidCallback? onBuscar;
	final VoidCallback? onImprimir;
	final VoidCallback? onExportar;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isMaquina = selectionKind == 'maquina';
		final isUbicacion = selectionKind == 'ubicacion';

		return Container(
			padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
			decoration: BoxDecoration(
				color: scheme.surface,
				border: Border(
					bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
				),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Row(
						children: [
							Icon(Icons.factory_outlined, color: AppColors.brandYellow, size: 22),
							const SizedBox(width: 10),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'Planta y equipos',
											style: Theme.of(context).textTheme.titleMedium?.copyWith(
														fontWeight: FontWeight.w800,
													),
										),
										const SizedBox(height: 2),
										Text(
											'Navegá el mapa, consultá historial y mantené la información al día.',
											style: TextStyle(
												fontSize: 12,
												color: scheme.onSurfaceVariant,
											),
										),
									],
								),
							),
							if (sucursales.isNotEmpty && onSucursalChanged != null)
								DropdownButtonHideUnderline(
									child: DropdownButton<String>(
										value: sucursalId,
										items: sucursales
												.map(
													(s) => DropdownMenuItem(
														value: s['id'] as String,
														child: Text(s['nombre'] as String),
													),
												)
												.toList(),
										onChanged: onSucursalChanged,
									),
								)
							else
								Container(
									padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
									decoration: BoxDecoration(
										color: AppColors.brandYellow.withValues(alpha: 0.12),
										borderRadius: BorderRadius.circular(999),
										border: Border.all(
											color: AppColors.brandYellow.withValues(alpha: 0.35),
										),
									),
									child: Text(
										plantaNombre,
										style: const TextStyle(
											color: AppColors.ink,
											fontWeight: FontWeight.w700,
											fontSize: 12,
										),
									),
								),
						],
					),
					if (clipboardLabel != null) ...[
						const SizedBox(height: 8),
						Container(
							padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
							decoration: BoxDecoration(
								color: AppColors.brandYellow.withValues(alpha: 0.1),
								borderRadius: BorderRadius.circular(10),
							),
							child: Row(
								children: [
									const Icon(Icons.content_paste_go_rounded, size: 18),
									const SizedBox(width: 8),
									Expanded(
										child: Text(
											'En portapapeles: $clipboardLabel — elegí dónde pegar',
											style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
										),
									),
								],
							),
						),
					],
					const SizedBox(height: 10),
					SingleChildScrollView(
						scrollDirection: Axis.horizontal,
						child: Row(
							children: [
								if (onBuscar != null)
									_ActionChip(
										icon: Icons.search_rounded,
										label: 'Buscar máquina',
										onPressed: onBuscar!,
									),
								if (onImprimir != null)
									_ActionChip(
										icon: Icons.print_outlined,
										label: 'Vista previa / Imprimir',
										onPressed: onImprimir!,
									),
								if (onExportar != null)
									_ActionChip(
										icon: Icons.download_rounded,
										label: 'Exportar CSV',
										onPressed: onExportar!,
									),
								if (canAgregar && onAgregar != null)
									_ActionChip(
										icon: Icons.add_rounded,
										label: 'Agregar',
										highlight: true,
										onPressed: onAgregar!,
									),
								if ((isMaquina || isUbicacion) && canModificar && onModificar != null)
									_ActionChip(
										icon: Icons.edit_rounded,
										label: isUbicacion ? 'Editar sector' : 'Editar datos',
										onPressed: onModificar!,
									),
								if ((isMaquina || isUbicacion) && canMover && onMover != null)
									_ActionChip(
										icon: Icons.drive_file_move_rounded,
										label: isUbicacion ? 'Mover sector' : 'Mover de sector',
										onPressed: onMover!,
									),
								if (isMaquina && canCopiar && onCopiar != null)
									_ActionChip(
										icon: Icons.content_copy_rounded,
										label: 'Copiar',
										onPressed: onCopiar!,
									),
								if (isMaquina && canCortar && onCortar != null)
									_ActionChip(
										icon: Icons.content_cut_rounded,
										label: 'Cortar para mover',
										onPressed: onCortar!,
									),
								if (canPegar && onPegar != null)
									_ActionChip(
										icon: Icons.content_paste_rounded,
										label: 'Pegar aquí',
										highlight: true,
										onPressed: onPegar!,
									),
								if ((isMaquina || isUbicacion) && canEliminar && onEliminar != null)
									_ActionChip(
										icon: Icons.delete_outline_rounded,
										label: isUbicacion ? 'Eliminar sector' : 'Dar de baja',
										danger: true,
										onPressed: onEliminar!,
									),
								_ActionChip(
									icon: Icons.refresh_rounded,
									label: 'Actualizar',
									onPressed: onRefresh,
								),
							],
						),
					),
				],
			),
		);
	}
}

class _ActionChip extends StatelessWidget {
	const _ActionChip({
		required this.icon,
		required this.label,
		required this.onPressed,
		this.highlight = false,
		this.danger = false,
	});

	final IconData icon;
	final String label;
	final VoidCallback onPressed;
	final bool highlight;
	final bool danger;

	@override
	Widget build(BuildContext context) {
		final bg = danger
				? AppColors.danger.withValues(alpha: 0.1)
				: highlight
						? AppColors.brandYellow.withValues(alpha: 0.18)
						: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
		final fg = danger ? AppColors.danger : AppColors.ink;

		return Padding(
			padding: const EdgeInsets.only(right: 8),
			child: Material(
				color: bg,
				borderRadius: BorderRadius.circular(999),
				child: InkWell(
					onTap: onPressed,
					borderRadius: BorderRadius.circular(999),
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
						child: Row(
							mainAxisSize: MainAxisSize.min,
							children: [
								Icon(icon, size: 16, color: fg),
								const SizedBox(width: 6),
								Text(
									label,
									style: TextStyle(
										fontSize: 12,
										fontWeight: FontWeight.w600,
										color: fg,
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
