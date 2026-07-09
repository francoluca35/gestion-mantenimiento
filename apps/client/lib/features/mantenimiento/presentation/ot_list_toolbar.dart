import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OtListToolbar extends StatelessWidget {
	const OtListToolbar({
		super.key,
		required this.selectedCount,
		required this.totalCount,
		required this.allSelected,
		required this.onToggleSelectAll,
		required this.onClearSelection,
		required this.onReasignar,
		required this.onMotivoPendiente,
		required this.onCambiarEstado,
		required this.onAnular,
		required this.onExportar,
		required this.onExportarFiltradas,
		this.canAnular = false,
		this.enabled = true,
	});

	final int selectedCount;
	final int totalCount;
	final bool allSelected;
	final bool canAnular;
	final bool enabled;
	final VoidCallback onToggleSelectAll;
	final VoidCallback onClearSelection;
	final VoidCallback onReasignar;
	final VoidCallback onMotivoPendiente;
	final VoidCallback onCambiarEstado;
	final VoidCallback onAnular;
	final VoidCallback onExportar;
	final VoidCallback onExportarFiltradas;

	@override
	Widget build(BuildContext context) {
		final hasSelection = selectedCount > 0;

		return Material(
			color: AppColors.cardDark,
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
									side: const BorderSide(color: Colors.white54),
									activeColor: AppColors.brandYellow,
								),
								Expanded(
									child: Text(
										hasSelection
												? '$selectedCount seleccionada${selectedCount == 1 ? '' : 's'}'
												: 'Seleccionar OT',
										style: TextStyle(
											color: hasSelection
													? AppColors.brandYellow
													: Colors.white.withValues(alpha: 0.75),
											fontWeight: FontWeight.w600,
											fontSize: 13,
										),
									),
								),
								if (hasSelection)
									TextButton(
										onPressed: enabled ? onClearSelection : null,
										child: const Text('Limpiar'),
									),
							],
						),
						SingleChildScrollView(
							scrollDirection: Axis.horizontal,
							child: Row(
								children: [
									_ToolbarButton(
										icon: Icons.person_add_alt_1_rounded,
										label: 'Reasignar',
										enabled: enabled && hasSelection,
										onPressed: onReasignar,
									),
									_ToolbarButton(
										icon: Icons.help_outline_rounded,
										label: 'Motivo pend.',
										enabled: enabled && hasSelection,
										onPressed: onMotivoPendiente,
									),
									_ToolbarButton(
										icon: Icons.swap_horiz_rounded,
										label: 'Estado',
										enabled: enabled && hasSelection,
										onPressed: onCambiarEstado,
									),
									if (canAnular)
										_ToolbarButton(
											icon: Icons.cancel_outlined,
											label: 'Anular',
											enabled: enabled && hasSelection,
											danger: true,
											onPressed: onAnular,
										),
									_ToolbarButton(
										icon: Icons.download_rounded,
										label: hasSelection ? 'Exportar sel.' : 'Exportar',
										enabled: enabled,
										onPressed: hasSelection ? onExportar : onExportarFiltradas,
									),
								],
							),
						),
					],
				),
			),
		);
	}
}

class _ToolbarButton extends StatelessWidget {
	const _ToolbarButton({
		required this.icon,
		required this.label,
		required this.onPressed,
		this.enabled = true,
		this.danger = false,
	});

	final IconData icon;
	final String label;
	final VoidCallback onPressed;
	final bool enabled;
	final bool danger;

	@override
	Widget build(BuildContext context) {
		final color = danger ? AppColors.danger : AppColors.accent;

		return Padding(
			padding: const EdgeInsets.only(right: 8),
			child: TextButton.icon(
				onPressed: enabled ? onPressed : null,
				style: TextButton.styleFrom(
					foregroundColor: enabled ? color : Colors.white38,
					padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
				),
				icon: Icon(icon, size: 18),
				label: Text(label, style: const TextStyle(fontSize: 12)),
			),
		);
	}
}
