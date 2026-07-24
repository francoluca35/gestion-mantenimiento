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
		this.onImprimir,
		this.onImprimirPdf,
		this.onGantt,
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
	final VoidCallback? onImprimir;
	final VoidCallback? onImprimirPdf;
	final VoidCallback? onGantt;

	@override
	Widget build(BuildContext context) {
		final hasSelection = selectedCount > 0;
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final bg = isDark ? AppColors.cardDark : AppColors.surfaceMuted;
		final fg = isDark ? Colors.white : AppColors.ink;
		final muted = isDark
				? Colors.white.withValues(alpha: 0.75)
				: AppColors.ink.withValues(alpha: 0.55);
		final checkSide = isDark ? Colors.white54 : AppColors.ink.withValues(alpha: 0.35);
		final disabledFg = isDark ? Colors.white38 : AppColors.ink.withValues(alpha: 0.28);

		return Material(
			color: bg,
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
									side: BorderSide(color: checkSide),
									activeColor: AppColors.brandYellow,
								),
								Expanded(
									child: Text(
										hasSelection
												? '$selectedCount seleccionada${selectedCount == 1 ? '' : 's'}'
												: 'Seleccionar OT',
										style: TextStyle(
											color: hasSelection ? AppColors.brandYellow : muted,
											fontWeight: FontWeight.w600,
											fontSize: 13,
										),
									),
								),
								if (hasSelection)
									TextButton(
										onPressed: enabled ? onClearSelection : null,
										child: Text('Limpiar', style: TextStyle(color: fg)),
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
										disabledColor: disabledFg,
										onPressed: onReasignar,
									),
									_ToolbarButton(
										icon: Icons.help_outline_rounded,
										label: 'Motivo pend.',
										enabled: enabled && hasSelection,
										disabledColor: disabledFg,
										onPressed: onMotivoPendiente,
									),
									_ToolbarButton(
										icon: Icons.swap_horiz_rounded,
										label: 'Estado',
										enabled: enabled && hasSelection,
										disabledColor: disabledFg,
										onPressed: onCambiarEstado,
									),
									if (canAnular)
										_ToolbarButton(
											icon: Icons.cancel_outlined,
											label: 'Anular',
											enabled: enabled && hasSelection,
											danger: true,
											disabledColor: disabledFg,
											onPressed: onAnular,
										),
									if (onImprimirPdf != null)
										_ToolbarButton(
											icon: Icons.picture_as_pdf_outlined,
											label: 'PDF selección',
											enabled: enabled && hasSelection,
											disabledColor: disabledFg,
											onPressed: onImprimirPdf!,
										),
									if (onImprimir != null)
										_ToolbarButton(
											icon: Icons.print_outlined,
											label: hasSelection ? 'Imprimir sel.' : 'Vista previa',
											enabled: enabled,
											disabledColor: disabledFg,
											onPressed: onImprimir!,
										),
									_ToolbarButton(
										icon: Icons.download_rounded,
										label: hasSelection ? 'Exportar sel.' : 'Exportar',
										enabled: enabled,
										disabledColor: disabledFg,
										onPressed: hasSelection ? onExportar : onExportarFiltradas,
									),
									if (onGantt != null)
										_ToolbarButton(
											icon: Icons.view_timeline_rounded,
											label: 'Gantt',
											enabled: enabled,
											disabledColor: disabledFg,
											onPressed: onGantt!,
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
		required this.disabledColor,
		this.enabled = true,
		this.danger = false,
	});

	final IconData icon;
	final String label;
	final VoidCallback onPressed;
	final Color disabledColor;
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
					foregroundColor: enabled ? color : disabledColor,
					padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
				),
				icon: Icon(icon, size: 18),
				label: Text(label, style: const TextStyle(fontSize: 12)),
			),
		);
	}
}
