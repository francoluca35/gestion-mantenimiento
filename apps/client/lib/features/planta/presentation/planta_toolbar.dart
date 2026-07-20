import 'package:flutter/material.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_colors.dart';

class _ToolbarAction {
	const _ToolbarAction({
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
}

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

	List<_ToolbarAction> _buildActions() {
		final isMaquina = selectionKind == 'maquina';
		final isUbicacion = selectionKind == 'ubicacion';
		final actions = <_ToolbarAction>[];

		if (onBuscar != null) {
			actions.add(_ToolbarAction(
				icon: Icons.search_rounded,
				label: 'Buscar máquina',
				onPressed: onBuscar!,
			));
		}
		if (onImprimir != null) {
			actions.add(_ToolbarAction(
				icon: Icons.print_outlined,
				label: 'Vista previa / Imprimir',
				onPressed: onImprimir!,
			));
		}
		if (onExportar != null) {
			actions.add(_ToolbarAction(
				icon: Icons.download_rounded,
				label: 'Exportar CSV',
				onPressed: onExportar!,
			));
		}
		if (canAgregar && onAgregar != null) {
			actions.add(_ToolbarAction(
				icon: Icons.add_rounded,
				label: 'Agregar',
				highlight: true,
				onPressed: onAgregar!,
			));
		}
		if ((isMaquina || isUbicacion) && canModificar && onModificar != null) {
			actions.add(_ToolbarAction(
				icon: Icons.edit_rounded,
				label: isUbicacion ? 'Editar sector' : 'Editar datos',
				onPressed: onModificar!,
			));
		}
		if ((isMaquina || isUbicacion) && canMover && onMover != null) {
			actions.add(_ToolbarAction(
				icon: Icons.drive_file_move_rounded,
				label: isUbicacion ? 'Mover sector' : 'Mover de sector',
				onPressed: onMover!,
			));
		}
		if (isMaquina && canCopiar && onCopiar != null) {
			actions.add(_ToolbarAction(
				icon: Icons.content_copy_rounded,
				label: 'Copiar',
				onPressed: onCopiar!,
			));
		}
		if (isMaquina && canCortar && onCortar != null) {
			actions.add(_ToolbarAction(
				icon: Icons.content_cut_rounded,
				label: 'Cortar para mover',
				onPressed: onCortar!,
			));
		}
		if (canPegar && onPegar != null) {
			actions.add(_ToolbarAction(
				icon: Icons.content_paste_rounded,
				label: 'Pegar aquí',
				highlight: true,
				onPressed: onPegar!,
			));
		}
		if ((isMaquina || isUbicacion) && canEliminar && onEliminar != null) {
			actions.add(_ToolbarAction(
				icon: Icons.delete_outline_rounded,
				label: isUbicacion ? 'Eliminar sector' : 'Dar de baja',
				danger: true,
				onPressed: onEliminar!,
			));
		}
		actions.add(_ToolbarAction(
			icon: Icons.refresh_rounded,
			label: 'Actualizar',
			onPressed: onRefresh,
		));

		return actions;
	}

	Future<void> _openActionsSheet(
		BuildContext context,
		List<_ToolbarAction> actions,
	) async {
		await showModalBottomSheet<void>(
			context: context,
			showDragHandle: true,
			isScrollControlled: true,
			builder: (ctx) {
				final scheme = Theme.of(ctx).colorScheme;
				return SafeArea(
					child: Padding(
						padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								Text(
									'Acciones de planta',
									style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
												fontWeight: FontWeight.w800,
											),
								),
								const SizedBox(height: 4),
								Text(
									'Elegí qué querés hacer con el mapa o la selección.',
									style: TextStyle(
										fontSize: 13,
										color: scheme.onSurfaceVariant,
									),
								),
								const SizedBox(height: 12),
								ConstrainedBox(
									constraints: BoxConstraints(
										maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
									),
									child: ListView.separated(
										shrinkWrap: true,
										itemCount: actions.length,
										separatorBuilder: (_, __) => const SizedBox(height: 6),
										itemBuilder: (context, index) {
											final action = actions[index];
											final fg = action.danger
													? AppColors.danger
													: scheme.onSurface;
											return Material(
												color: action.highlight
														? AppColors.brandYellow.withValues(alpha: 0.16)
														: action.danger
																? AppColors.danger.withValues(alpha: 0.1)
																: scheme.surfaceContainerHighest,
												borderRadius: BorderRadius.circular(14),
												child: InkWell(
													borderRadius: BorderRadius.circular(14),
													onTap: () {
														Navigator.of(ctx).pop();
														action.onPressed();
													},
													child: Padding(
														padding: const EdgeInsets.symmetric(
															horizontal: 14,
															vertical: 14,
														),
														child: Row(
															children: [
																Icon(action.icon, size: 22, color: fg),
																const SizedBox(width: 12),
																Expanded(
																	child: Text(
																		action.label,
																		style: TextStyle(
																			fontSize: 15,
																			fontWeight: FontWeight.w700,
																			color: fg,
																		),
																	),
																),
																Icon(
																	Icons.chevron_right_rounded,
																	color: scheme.onSurfaceVariant,
																),
															],
														),
													),
												),
											);
										},
									),
								),
							],
						),
					),
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final actions = _buildActions();
		final width = MediaQuery.sizeOf(context).width;
		final isMobile = Breakpoints.isMobile(width);

		return Container(
			padding: EdgeInsets.fromLTRB(isMobile ? 14 : 20, 12, isMobile ? 14 : 20, 12),
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
										if (!isMobile) ...[
											const SizedBox(height: 2),
											Text(
												'Navegá el mapa, consultá historial y mantené la información al día.',
												style: TextStyle(
													fontSize: 12,
													color: scheme.onSurfaceVariant,
												),
											),
										],
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
										style: TextStyle(
											color: scheme.onSurface,
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
								border: Border.all(
									color: AppColors.brandYellow.withValues(alpha: 0.35),
								),
							),
							child: Row(
								children: [
									Icon(
										Icons.content_paste_go_rounded,
										size: 18,
										color: scheme.onSurface,
									),
									const SizedBox(width: 8),
									Expanded(
										child: Text(
											'En portapapeles: $clipboardLabel — elegí dónde pegar',
											style: TextStyle(
												fontSize: 12,
												fontWeight: FontWeight.w600,
												color: scheme.onSurface,
											),
										),
									),
								],
							),
						),
					],
					const SizedBox(height: 10),
					if (isMobile)
						_MobileActionsBar(
							actions: actions,
							onOpenMenu: () => _openActionsSheet(context, actions),
						)
					else
						SingleChildScrollView(
							scrollDirection: Axis.horizontal,
							child: Row(
								children: [
									for (final action in actions)
										_ActionChip(
											icon: action.icon,
											label: action.label,
											highlight: action.highlight,
											danger: action.danger,
											onPressed: action.onPressed,
										),
								],
							),
						),
				],
			),
		);
	}
}

class _MobileActionsBar extends StatelessWidget {
	const _MobileActionsBar({
		required this.actions,
		required this.onOpenMenu,
	});

	final List<_ToolbarAction> actions;
	final VoidCallback onOpenMenu;

	@override
	Widget build(BuildContext context) {
		final primary = actions.where((a) => a.highlight && !a.danger).toList();
		final highlight = primary.isNotEmpty ? primary.first : null;

		return Row(
			children: [
				if (highlight != null) ...[
					Expanded(
						child: _ActionChip(
							icon: highlight.icon,
							label: highlight.label,
							highlight: true,
							onPressed: highlight.onPressed,
							expanded: true,
						),
					),
					const SizedBox(width: 8),
				],
				Expanded(
					flex: highlight != null ? 1 : 1,
					child: _ActionChip(
						icon: Icons.tune_rounded,
						label: 'Acciones (${actions.length})',
						onPressed: onOpenMenu,
						expanded: true,
						emphasized: true,
					),
				),
			],
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
		this.emphasized = false,
		this.expanded = false,
	});

	final IconData icon;
	final String label;
	final VoidCallback onPressed;
	final bool highlight;
	final bool danger;
	final bool emphasized;
	final bool expanded;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isDark = Theme.of(context).brightness == Brightness.dark;

		final Color bg;
		final Color fg;
		final Color border;

		if (danger) {
			bg = AppColors.danger.withValues(alpha: isDark ? 0.18 : 0.1);
			fg = isDark ? const Color(0xFFFF8A8A) : AppColors.danger;
			border = AppColors.danger.withValues(alpha: 0.45);
		} else if (highlight) {
			bg = AppColors.brandYellow;
			fg = AppColors.ink;
			border = AppColors.brandYellow;
		} else if (emphasized) {
			bg = isDark ? AppColors.cardElevated : scheme.surfaceContainerHighest;
			fg = scheme.onSurface;
			border = AppColors.brandYellow.withValues(alpha: 0.55);
		} else {
			bg = isDark ? AppColors.cardElevated : scheme.surfaceContainerHighest;
			fg = scheme.onSurface;
			border = scheme.outlineVariant.withValues(alpha: isDark ? 0.7 : 0.9);
		}

		final child = Material(
			color: bg,
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(12),
				side: BorderSide(color: border),
			),
			child: InkWell(
				onTap: onPressed,
				borderRadius: BorderRadius.circular(12),
				child: Padding(
					padding: EdgeInsets.symmetric(
						horizontal: expanded ? 14 : 12,
						vertical: expanded ? 12 : 9,
					),
					child: Row(
						mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
						mainAxisAlignment:
								expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
						children: [
							Icon(icon, size: 18, color: fg),
							const SizedBox(width: 7),
							if (expanded)
								Flexible(
									child: Text(
										label,
										overflow: TextOverflow.ellipsis,
										style: TextStyle(
											fontSize: 13,
											fontWeight: FontWeight.w700,
											color: fg,
										),
									),
								)
							else
								Text(
									label,
									style: TextStyle(
										fontSize: 13,
										fontWeight: FontWeight.w700,
										color: fg,
									),
								),
							if (emphasized) ...[
								const SizedBox(width: 4),
								Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: fg),
							],
						],
					),
				),
			),
		);

		if (expanded) {
			return SizedBox(width: double.infinity, child: child);
		}
		return Padding(
			padding: const EdgeInsets.only(right: 8),
			child: child,
		);
	}
}
