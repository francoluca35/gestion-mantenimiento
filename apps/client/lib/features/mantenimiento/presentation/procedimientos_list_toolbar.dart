import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProcedimientosListToolbar extends StatelessWidget {
	const ProcedimientosListToolbar({
		super.key,
		required this.selectedCount,
		required this.totalCount,
		required this.allSelected,
		required this.onToggleSelectAll,
		required this.onClearSelection,
		required this.onExportar,
		required this.onExportarFiltrados,
		this.onModificar,
		this.onEliminar,
		this.onAsociar,
		this.canModificar = false,
		this.canEliminar = false,
		this.canAsociar = false,
		this.enabled = true,
	});

	final int selectedCount;
	final int totalCount;
	final bool allSelected;
	final bool enabled;
	final bool canModificar;
	final bool canEliminar;
	final bool canAsociar;
	final VoidCallback onToggleSelectAll;
	final VoidCallback onClearSelection;
	final VoidCallback onExportar;
	final VoidCallback onExportarFiltrados;
	final VoidCallback? onModificar;
	final VoidCallback? onEliminar;
	final VoidCallback? onAsociar;

	@override
	Widget build(BuildContext context) {
		final hasSelection = selectedCount > 0;
		final singleSelection = selectedCount == 1;
		const accent = Color(0xFF0F766E);

		return Padding(
			padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Row(
						children: [
							Checkbox(
								value: allSelected && totalCount > 0,
								tristate: true,
								onChanged: enabled && totalCount > 0
										? (_) => onToggleSelectAll()
										: null,
								activeColor: accent,
							),
							Expanded(
								child: Text(
									hasSelection
											? '$selectedCount seleccionado${selectedCount == 1 ? '' : 's'}'
											: 'Seleccionar procedimientos',
									style: TextStyle(
										fontSize: 13,
										fontWeight: FontWeight.w600,
										color: hasSelection ? accent : AppColors.mutedText,
									),
								),
							),
							if (hasSelection)
								TextButton(onPressed: onClearSelection, child: const Text('Limpiar')),
						],
					),
					SingleChildScrollView(
						scrollDirection: Axis.horizontal,
						child: Row(
							children: [
								if (singleSelection && canModificar && onModificar != null)
									TextButton.icon(
										onPressed: enabled ? onModificar : null,
										icon: const Icon(Icons.edit_rounded, size: 18),
										label: const Text('Modificar'),
									),
								if (hasSelection && canEliminar && onEliminar != null)
									TextButton.icon(
										onPressed: enabled ? onEliminar : null,
										icon: const Icon(Icons.delete_outline_rounded, size: 18),
										label: const Text('Eliminar'),
									),
								if (singleSelection && canAsociar && onAsociar != null)
									TextButton.icon(
										onPressed: enabled ? onAsociar : null,
										icon: const Icon(Icons.link_rounded, size: 18),
										label: const Text('Asociar'),
									),
								TextButton.icon(
									onPressed: enabled
											? (hasSelection ? onExportar : onExportarFiltrados)
											: null,
									icon: const Icon(Icons.download_rounded, size: 18),
									label: Text(hasSelection ? 'Exportar sel.' : 'Exportar listado'),
								),
							],
						),
					),
				],
			),
		);
	}
}
