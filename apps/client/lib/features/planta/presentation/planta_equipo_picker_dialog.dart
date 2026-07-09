import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
enum _PickerNodeKind { empresa, planta, ubicacion, equipo }

class _PickerNode {
	const _PickerNode({
		required this.id,
		required this.label,
		required this.kind,
		required this.activo,
		this.subtitle,
		this.children = const [],
		this.raw,
	});

	final String id;
	final String label;
	final _PickerNodeKind kind;
	final bool activo;
	final String? subtitle;
	final List<_PickerNode> children;
	final Map<String, dynamic>? raw;
}

enum PlantaPickerTargetTipo { equipo, ubicacion, planta }

class PlantaEquipoPickerResult {
	const PlantaEquipoPickerResult({
		required this.tipo,
		this.equipoId,
		this.ubicacionId,
		this.sucursalId,
		this.emitirPrimeraOt = false,
		this.fechaProgramacion,
		this.tecnicoAsignadoId,
		this.imprimirOt = false,
	});

	final PlantaPickerTargetTipo tipo;
	final String? equipoId;
	final String? ubicacionId;
	final String? sucursalId;
	final bool emitirPrimeraOt;
	final String? fechaProgramacion;
	final String? tecnicoAsignadoId;
	final bool imprimirOt;
	List<String> get equipoIds =>
			tipo == PlantaPickerTargetTipo.equipo && equipoId != null ? [equipoId!] : [];
}

Future<PlantaEquipoPickerResult?> showPlantaEquipoPickerDialog({
	required BuildContext context,
	required WidgetRef ref,
	Set<String> excludedEquipoIds = const {},
	Set<String> asociadosUbicacionIds = const {},
	bool plantaYaAsociada = false,
	bool showEmitirPrimeraOt = false,
	bool allowScopeSelection = false,
}) {
	return showDialog<PlantaEquipoPickerResult>(
		context: context,
		builder: (context) => _PlantaEquipoPickerDialog(
			ref: ref,
			excludedEquipoIds: excludedEquipoIds,
			asociadosUbicacionIds: asociadosUbicacionIds,
			plantaYaAsociada: plantaYaAsociada,
			showEmitirPrimeraOt: showEmitirPrimeraOt,
			allowScopeSelection: allowScopeSelection,
		),
	);
}

class _PlantaEquipoPickerDialog extends ConsumerStatefulWidget {
	const _PlantaEquipoPickerDialog({
		required this.ref,
		required this.excludedEquipoIds,
		required this.asociadosUbicacionIds,
		required this.plantaYaAsociada,
		required this.showEmitirPrimeraOt,
		required this.allowScopeSelection,
	});

	final WidgetRef ref;
	final Set<String> excludedEquipoIds;
	final Set<String> asociadosUbicacionIds;
	final bool plantaYaAsociada;
	final bool showEmitirPrimeraOt;
	final bool allowScopeSelection;

	@override
	ConsumerState<_PlantaEquipoPickerDialog> createState() =>
			_PlantaEquipoPickerDialogState();
}

class _PlantaEquipoPickerDialogState
		extends ConsumerState<_PlantaEquipoPickerDialog> {
	static const _empresaNombre = 'SIKA';

	String? _sucursalId;
	String? _plantaNombre;
	List<Map<String, dynamic>> _ubicacionesTree = [];
	List<Map<String, dynamic>> _equipos = [];
	_PickerNode? _selectedNode;
	String _search = '';
	bool _loading = true;
	bool _emitirPrimeraOt = false;
	bool _imprimirOt = false;
	DateTime _fechaProgramacion = DateTime.now();
	String? _tecnicoId;
	List<Map<String, dynamic>> _tecnicos = [];
	String? _error;

	@override
	void initState() {
		super.initState();
		_emitirPrimeraOt = widget.showEmitirPrimeraOt;
		WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
	}

	Future<void> _bootstrap() async {
		setState(() {
			_loading = true;
			_error = null;
		});

		try {
			final user = ref.read(authControllerProvider).session?.usuario;
			if (user?.sucursalId == null) {
				throw Exception('Tu usuario no tiene planta asignada.');
			}

			_sucursalId = user!.sucursalId;
			_plantaNombre = user.sucursalNombre ?? 'PLANTA';

			final api = ref.read(apiClientProvider);
			final query = '?sucursalId=$_sucursalId';
			final tree = await api.getList('ubicaciones/tree$query');
			final equipos = await api.getList('equipos$query');
			var tecnicos = <Map<String, dynamic>>[];
			if (widget.showEmitirPrimeraOt) {
				try {
					tecnicos =
							(await api.getList('ot/tecnicos?sucursalId=$_sucursalId'))
									.cast<Map<String, dynamic>>();
				} catch (_) {
					tecnicos = [];
				}
			}

			if (!mounted) return;
			setState(() {
				_ubicacionesTree = tree.cast<Map<String, dynamic>>();
				_equipos = equipos.cast<Map<String, dynamic>>();
				_tecnicos = tecnicos;
				_selectedNode = _buildExplorerTree();
			});
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	_PickerNode _buildExplorerTree() {
		return _PickerNode(
			id: 'empresa',
			label: _empresaNombre,
			kind: _PickerNodeKind.empresa,
			activo: true,
			children: [
				_PickerNode(
					id: 'planta:$_sucursalId',
					label: _plantaNombre ?? 'PLANTA',
					kind: _PickerNodeKind.planta,
					activo: true,
					children: _ubicacionesTree.map(_mapUbicacionNode).toList(),
				),
			],
		);
	}

	_PickerNode _mapUbicacionNode(Map<String, dynamic> node) {
		final childrenUbic = (node['children'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>();
		final id = node['id'] as String;
		final equipos = _equipos
				.where((e) => e['ubicacionId'] == id)
				.map(_mapEquipoNode)
				.toList();

		return _PickerNode(
			id: 'ubicacion:$id',
			label: node['nombre'] as String,
			kind: _PickerNodeKind.ubicacion,
			activo: node['activa'] as bool? ?? true,
			children: [...childrenUbic.map(_mapUbicacionNode), ...equipos],
			raw: node,
		);
	}

	_PickerNode _mapEquipoNode(Map<String, dynamic> equipo) {
		final id = equipo['id'] as String;
		final operativo = (equipo['activo'] as bool? ?? true) &&
				!(equipo['fueraDeServicio'] as bool? ?? false);

		return _PickerNode(
			id: 'equipo:$id',
			label: equipo['nombre'] as String,
			subtitle: equipo['codigo'] as String?,
			kind: _PickerNodeKind.equipo,
			activo: operativo,
			raw: equipo,
		);
	}

	List<_PickerNode> _filterTree(_PickerNode node) {
		if (_search.trim().isEmpty) return [node];
		final query = _search.trim().toLowerCase();

		_PickerNode? filter(_PickerNode current) {
			final childMatches = current.children
					.map(filter)
					.whereType<_PickerNode>()
					.toList();
			final selfMatch = current.label.toLowerCase().contains(query) ||
					(current.subtitle?.toLowerCase().contains(query) ?? false);
			if (selfMatch || childMatches.isNotEmpty) {
				return _PickerNode(
					id: current.id,
					label: current.label,
					subtitle: current.subtitle,
					kind: current.kind,
					activo: current.activo,
					children: childMatches,
					raw: current.raw,
				);
			}
			return null;
		}

		final result = filter(node);
		return result == null ? [] : [result];
	}

	List<_PickerNode> _equiposEnNodo(_PickerNode node) {
		final result = <_PickerNode>[];
		void walk(_PickerNode current) {
			for (final child in current.children) {
				if (child.kind == _PickerNodeKind.equipo) {
					result.add(child);
				} else {
					walk(child);
				}
			}
		}

		if (node.kind == _PickerNodeKind.equipo) {
			return [node];
		}
		walk(node);
		return result;
	}

	bool _yaEnEsteProcedimiento(String equipoId) =>
			widget.allowScopeSelection && widget.excludedEquipoIds.contains(equipoId);

	bool _ubicacionYaAsociada(String ubicacionId) =>
			widget.allowScopeSelection && widget.asociadosUbicacionIds.contains(ubicacionId);

	bool get _hasValidSelection {
		final node = _selectedNode;
		if (node == null) return false;
		if (node.kind == _PickerNodeKind.equipo) return node.activo;
		if (widget.allowScopeSelection) {
			return node.kind == _PickerNodeKind.ubicacion ||
					node.kind == _PickerNodeKind.planta;
		}
		return false;
	}

	String _estadoEquipoLabel(String equipoId, {required bool operativo}) {
		if (!operativo) return 'No disponible';
		if (_yaEnEsteProcedimiento(equipoId)) return 'Ya en este procedimiento';
		return 'Disponible';
	}

	PlantaEquipoPickerResult? _buildResult() {
		final node = _selectedNode;
		if (node == null || !_hasValidSelection) return null;

		return switch (node.kind) {
			_PickerNodeKind.equipo => PlantaEquipoPickerResult(
					tipo: PlantaPickerTargetTipo.equipo,
					equipoId: node.id.replaceFirst('equipo:', ''),
					emitirPrimeraOt:
							widget.showEmitirPrimeraOt ? _emitirPrimeraOt : false,
					fechaProgramacion: _emitirPrimeraOt
							? _formatApiDate(_fechaProgramacion)
							: null,
					tecnicoAsignadoId: _emitirPrimeraOt ? _tecnicoId : null,
					imprimirOt: _emitirPrimeraOt && _imprimirOt,
				),
			_PickerNodeKind.ubicacion => PlantaEquipoPickerResult(
					tipo: PlantaPickerTargetTipo.ubicacion,
					ubicacionId: node.id.replaceFirst('ubicacion:', ''),
				),
			_PickerNodeKind.planta => PlantaEquipoPickerResult(
					tipo: PlantaPickerTargetTipo.planta,
					sucursalId: _sucursalId,
				),
			_ => null,
		};
	}

	String _footerLabel() {
		final node = _selectedNode;
		if (node == null || !_hasValidSelection) {
			return widget.allowScopeSelection
					? 'Seleccioná un equipo, sector o la planta'
					: 'Seleccioná un equipo del mapa';
		}

		return switch (node.kind) {
			_PickerNodeKind.equipo => 'Equipo seleccionado',
			_PickerNodeKind.ubicacion => 'Sector seleccionado: ${node.label}',
			_PickerNodeKind.planta => 'Planta seleccionada: ${node.label}',
			_ => '',
		};
	}

	void _selectNode(_PickerNode node) {
		setState(() => _selectedNode = node);
	}

	String _formatApiDate(DateTime date) {
		return '${date.year.toString().padLeft(4, '0')}-'
				'${date.month.toString().padLeft(2, '0')}-'
				'${date.day.toString().padLeft(2, '0')}';
	}

	Future<void> _pickFechaProgramacion() async {
		final picked = await showDatePicker(
			context: context,
			initialDate: _fechaProgramacion,
			firstDate: DateTime(2020),
			lastDate: DateTime(2035),
		);
		if (picked != null) setState(() => _fechaProgramacion = picked);
	}

	Widget _buildEmitirOtOptions(BuildContext context) {
		if (!widget.showEmitirPrimeraOt) return const SizedBox.shrink();
		final node = _selectedNode;
		if (node?.kind != _PickerNodeKind.equipo) return const SizedBox.shrink();

		final dateFmt = DateFormat('dd/MM/yyyy');

		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				const Divider(height: 1),
				Padding(
					padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
					child: SwitchListTile(
						contentPadding: EdgeInsets.zero,
						title: const Text('Emitir primera OT'),
						subtitle: const Text(
							'Genera la OT periódica al asociar el equipo',
							style: TextStyle(fontSize: 12),
						),
						value: _emitirPrimeraOt,
						onChanged: (value) => setState(() => _emitirPrimeraOt = value),
					),
				),
				if (_emitirPrimeraOt) ...[
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 20),
						child: ListTile(
							contentPadding: EdgeInsets.zero,
							title: const Text('Fecha programación'),
							subtitle: Text(dateFmt.format(_fechaProgramacion)),
							trailing: const Icon(Icons.calendar_today_rounded),
							onTap: _pickFechaProgramacion,
						),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
						child: DropdownButtonFormField<String?>(
							value: _tecnicoId,
							isExpanded: true,
							decoration: const InputDecoration(
								labelText: 'Técnico (opcional)',
								isDense: true,
								border: OutlineInputBorder(),
							),
							items: [
								const DropdownMenuItem(value: null, child: Text('Sin asignar')),
								..._tecnicos.map(
									(t) => DropdownMenuItem(
										value: t['id'] as String,
										child: Text(t['nombreUsuario'] as String),
									),
								),
							],
							onChanged: (v) => setState(() => _tecnicoId = v),
						),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
						child: SwitchListTile(
							contentPadding: EdgeInsets.zero,
							title: const Text('Imprimir OT emitida'),
							subtitle: const Text(
								'Abre la vista de impresión al confirmar',
								style: TextStyle(fontSize: 12),
							),
							value: _imprimirOt,
							onChanged: (value) => setState(() => _imprimirOt = value),
						),
					),
				],
			],
		);
	}

	String _breadcrumb(_PickerNode node) {
		return switch (node.kind) {
			_PickerNodeKind.empresa => _empresaNombre,
			_PickerNodeKind.planta => '$_empresaNombre › ${node.label}',
			_PickerNodeKind.ubicacion => '$_empresaNombre › $_plantaNombre › ${node.label}',
			_PickerNodeKind.equipo => () {
					final ubicacion = _ubicacionDeEquipo(node.raw?['ubicacionId'] as String?);
					if (ubicacion == null) {
						return '$_empresaNombre › $_plantaNombre › ${node.label}';
					}
					return '$_empresaNombre › $_plantaNombre › $ubicacion › ${node.label}';
				}(),
		};
	}

	String? _ubicacionDeEquipo(String? ubicacionId) {
		if (ubicacionId == null) return null;
		String? find(List<Map<String, dynamic>> nodes) {
			for (final node in nodes) {
				if (node['id'] == ubicacionId) return node['nombre'] as String;
				final child = find(
					(node['children'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
				);
				if (child != null) return child;
			}
			return null;
		}

		return find(_ubicacionesTree);
	}

	Widget _buildPreviewPanel(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final selected = _selectedNode;

		if (selected == null) {
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(
							Icons.map_outlined,
							size: 48,
							color: scheme.onSurfaceVariant,
						),
						const SizedBox(height: 12),
						const Text('Navegá el mapa de la planta'),
						const SizedBox(height: 4),
						Text(
							'Seleccioná un sector o un equipo para asociar',
							style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
						),
					],
				),
			);
		}

		if (selected.kind == _PickerNodeKind.equipo) {
			final equipo = selected.raw ?? {};
			final equipoId = equipo['id'] as String;
			final yaEnEste = _yaEnEsteProcedimiento(equipoId);
			final ubicacion = _ubicacionDeEquipo(equipo['ubicacionId'] as String?);

			return Padding(
				padding: const EdgeInsets.all(20),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Text(
							_breadcrumb(selected),
							style: Theme.of(context).textTheme.bodySmall?.copyWith(
										color: scheme.onSurfaceVariant,
									),
						),
						const SizedBox(height: 12),
						Text(
							'${equipo['codigo'] ?? ''} — ${equipo['nombre'] ?? selected.label}',
							style: Theme.of(context).textTheme.titleLarge?.copyWith(
										fontWeight: FontWeight.w700,
									),
						),
						if (ubicacion != null) ...[
							const SizedBox(height: 8),
							_InfoLine(icon: Icons.place_outlined, label: 'Ubicación', value: ubicacion),
						],
						const SizedBox(height: 8),
						_InfoLine(
							icon: Icons.precision_manufacturing_outlined,
							label: 'Estado',
							value: _estadoEquipoLabel(equipoId, operativo: selected.activo),
						),
						const Spacer(),
						if (!selected.activo)
							Text(
								'El equipo está inactivo o fuera de servicio.',
								style: TextStyle(color: scheme.error, fontSize: 13),
							)
						else if (yaEnEste)
							Text(
								'Ya está en este procedimiento. Podés reconfirmar la asociación '
								'o asociar otros procedimientos al mismo equipo.',
								style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
							)
						else if (widget.showEmitirPrimeraOt)
							Text(
								'Al asociar, el trabajo preventivo aparecerá en '
								'OT necesarias para asignar técnico, descargar PDF o activar.',
								style: TextStyle(
									color: scheme.onSurfaceVariant,
									fontSize: 13,
								),
							),
					],
				),
			);
		}

		if (widget.allowScopeSelection &&
				(selected.kind == _PickerNodeKind.ubicacion ||
						selected.kind == _PickerNodeKind.planta)) {
			final yaAsociado = selected.kind == _PickerNodeKind.planta
					? widget.plantaYaAsociada
					: _ubicacionYaAsociada(selected.id.replaceFirst('ubicacion:', ''));
			final icon = selected.kind == _PickerNodeKind.planta
					? Icons.factory_rounded
					: Icons.folder_rounded;

			return Padding(
				padding: const EdgeInsets.all(20),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Text(
							_breadcrumb(selected),
							style: Theme.of(context).textTheme.bodySmall?.copyWith(
										color: scheme.onSurfaceVariant,
									),
						),
						const SizedBox(height: 20),
						Icon(icon, size: 56, color: AppColors.primary),
						const SizedBox(height: 16),
						Text(
							selected.label,
							style: Theme.of(context).textTheme.headlineSmall?.copyWith(
										fontWeight: FontWeight.w700,
									),
						),
						const SizedBox(height: 12),
						Text(
							selected.kind == _PickerNodeKind.planta
									? 'El procedimiento se asociará a toda la planta, '
											'sin incluir equipos individuales.'
									: 'El procedimiento se asociará a este sector, '
											'sin incluir equipos individuales.',
							style: TextStyle(
								color: scheme.onSurfaceVariant,
								fontSize: 14,
								height: 1.4,
							),
						),
						const Spacer(),
						if (yaAsociado)
							Text(
								'Ya está asociado a este procedimiento. Podés reconfirmar.',
								style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
							),
					],
				),
			);
		}

		final equipos = _equiposEnNodo(selected);

		return Padding(
			padding: const EdgeInsets.all(20),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Text(
						_breadcrumb(selected),
						style: Theme.of(context).textTheme.bodySmall?.copyWith(
									color: scheme.onSurfaceVariant,
								),
					),
					const SizedBox(height: 12),
					Text(
						selected.label,
						style: Theme.of(context).textTheme.titleLarge?.copyWith(
									fontWeight: FontWeight.w700,
								),
					),
					const SizedBox(height: 16),
					if (equipos.isEmpty)
						Expanded(
							child: Center(
								child: Text(
									selected.kind == _PickerNodeKind.planta
											? 'Esta planta no tiene equipos cargados'
											: 'Este sector no tiene equipos',
									style: TextStyle(color: scheme.onSurfaceVariant),
								),
							),
						)
					else ...[
						Text(
							'Equipos en este sector',
							style: Theme.of(context).textTheme.titleSmall?.copyWith(
										fontWeight: FontWeight.w700,
									),
						),
						const SizedBox(height: 8),
						Expanded(
							child: ListView.separated(
								itemCount: equipos.length,
								separatorBuilder: (_, __) => const SizedBox(height: 6),
								itemBuilder: (context, index) {
									final equipo = equipos[index];
									final id = equipo.id.replaceFirst('equipo:', '');
									final isSelected = _selectedNode?.id == equipo.id;

									return Material(
										color: isSelected
												? AppColors.primary.withValues(alpha: 0.1)
												: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
										borderRadius: BorderRadius.circular(12),
										child: ListTile(
											enabled: equipo.activo,
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(12),
											),
											leading: Icon(
												Icons.precision_manufacturing_outlined,
												color: equipo.activo
														? AppColors.primary
														: scheme.onSurfaceVariant,
											),
											title: Text(
												'${equipo.subtitle ?? ''} — ${equipo.label}',
												style: TextStyle(
													fontWeight:
															isSelected ? FontWeight.w700 : FontWeight.w500,
													color: equipo.activo ? null : scheme.onSurfaceVariant,
												),
											),
											subtitle: Text(
												_estadoEquipoLabel(id, operativo: equipo.activo),
											),
											trailing: isSelected
													? const Icon(Icons.check_circle_rounded,
															color: AppColors.primary)
													: null,
											onTap: equipo.activo ? () => _selectNode(equipo) : null,
										),
									);
								},
							),
						),
					],
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final explorerBg = AppColors.explorerPanel;
		final size = MediaQuery.sizeOf(context);
		final dialogWidth = size.width >= 900 ? 860.0 : size.width * 0.94;
		final dialogHeight = size.height >= 700 ? 580.0 : size.height * 0.82;

		return Dialog(
			insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
			child: SizedBox(
				width: dialogWidth,
				height: dialogHeight,
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Padding(
							padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
							child: Row(
								children: [
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(
													widget.allowScopeSelection
															? 'Asociar equipo o sector'
															: 'Asociar equipo',
													style: Theme.of(context)
															.textTheme
															.titleLarge
															?.copyWith(fontWeight: FontWeight.w800),
												),
												const SizedBox(height: 2),
												Text(
													widget.allowScopeSelection
															? 'Mapa de planta — seleccioná equipo, sector o planta'
															: 'Mapa de planta — ${_plantaNombre ?? ''}',
													style: TextStyle(
														color: scheme.onSurfaceVariant,
														fontSize: 13,
													),
												),
											],
										),
									),
									IconButton(
										onPressed: () => Navigator.pop(context),
										icon: const Icon(Icons.close_rounded),
									),
								],
							),
						),
						const Divider(height: 1),
						Expanded(
							child: _loading
									? const Center(child: CircularProgressIndicator())
									: _error != null
											? Center(child: Text(_error!))
											: LayoutBuilder(
													builder: (context, constraints) {
														final stacked = constraints.maxWidth < 640;
														final root = _buildExplorerTree();
														final visible = _filterTree(root);
														final explorer = Material(
															color: explorerBg,
															child: Column(
																crossAxisAlignment:
																		CrossAxisAlignment.stretch,
																children: [
																	Padding(
																		padding: const EdgeInsets.fromLTRB(
																			16,
																			14,
																			16,
																			8,
																		),
																		child: Text(
																			'Mapa de la planta',
																			style: Theme.of(context)
																					.textTheme
																					.titleSmall
																					?.copyWith(
																						fontWeight:
																								FontWeight.w700,
																					),
																		),
																	),
																	Padding(
																		padding: const EdgeInsets.symmetric(
																			horizontal: 16,
																		),
																		child: TextField(
																			onChanged: (value) =>
																					setState(() => _search = value),
																			decoration: InputDecoration(
																				hintText:
																						'Buscar sector o equipo...',
																				prefixIcon: const Icon(
																					Icons.search,
																					size: 20,
																				),
																				isDense: true,
																				filled: true,
																				fillColor: isDark
																						? Colors.white
																								.withValues(alpha: 0.06)
																						: const Color(0xFFF8FAFC),
																				border: OutlineInputBorder(
																					borderRadius:
																							BorderRadius.circular(12),
																					borderSide: BorderSide.none,
																				),
																			),
																		),
																	),
																	const SizedBox(height: 8),
																	Expanded(
																		child: visible.isEmpty
																				? const Center(
																						child: Text('Sin resultados'),
																					)
																				: ListView(
																						padding:
																								const EdgeInsets.fromLTRB(
																							8,
																							0,
																							8,
																							12,
																						),
																						children: visible
																								.map(
																									(node) =>
																											_PickerExplorerTile(
																										node: node,
																										selectedId:
																											_selectedNode?.id,
																										depth: 0,
																										onSelect: _selectNode,
																									),
																								)
																								.toList(),
																					),
																	),
																],
															),
														);

														final preview = _buildPreviewPanel(context);

														if (stacked) {
															return Column(
																children: [
																	Expanded(flex: 5, child: explorer),
																	const Divider(height: 1),
																	Expanded(flex: 4, child: preview),
																],
															);
														}

														return Row(
															children: [
																SizedBox(width: 320, child: explorer),
																VerticalDivider(
																	width: 1,
																	color: scheme.outlineVariant
																			.withValues(alpha: 0.35),
																),
																Expanded(child: preview),
															],
														);
													},
												),
						),
						const Divider(height: 1),
						_buildEmitirOtOptions(context),
						Padding(
							padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
							child: Row(
								children: [
									Expanded(
										child: Text(
											_footerLabel(),
											style: TextStyle(
												color: scheme.onSurfaceVariant,
												fontSize: 13,
											),
										),
									),
									TextButton(
										onPressed: () => Navigator.pop(context),
										child: const Text('Cancelar'),
									),
									const SizedBox(width: 8),
									FilledButton(
										onPressed: !_hasValidSelection
												? null
												: () {
														final result = _buildResult();
														if (result != null) {
															Navigator.pop(context, result);
														}
													},
										child: const Text('Asociar'),
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

class _PickerExplorerTile extends StatelessWidget {
	const _PickerExplorerTile({
		required this.node,
		required this.selectedId,
		required this.depth,
		required this.onSelect,
	});

	final _PickerNode node;
	final String? selectedId;
	final int depth;
	final void Function(_PickerNode node) onSelect;

	IconData get _icon {
		return switch (node.kind) {
			_PickerNodeKind.empresa => Icons.apartment_rounded,
			_PickerNodeKind.planta => Icons.factory_rounded,
			_PickerNodeKind.ubicacion => Icons.folder_rounded,
			_PickerNodeKind.equipo => Icons.precision_manufacturing_rounded,
		};
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final selected = selectedId == node.id;
		final disabled = node.kind == _PickerNodeKind.equipo && !node.activo;

		return Column(
			children: [
				Material(
					color: selected
							? AppColors.primary.withValues(alpha: 0.12)
							: Colors.transparent,
					borderRadius: BorderRadius.circular(10),
					child: InkWell(
						borderRadius: BorderRadius.circular(10),
						onTap: disabled ? null : () => onSelect(node),
						child: Padding(
							padding: EdgeInsets.fromLTRB(8.0 + depth * 14, 8, 8, 8),
							child: Row(
								children: [
									Icon(
										_icon,
										size: 18,
										color: disabled
												? scheme.onSurfaceVariant.withValues(alpha: 0.5)
												: scheme.onSurfaceVariant,
									),
									const SizedBox(width: 8),
									if (node.kind == _PickerNodeKind.equipo)
										Container(
											width: 8,
											height: 8,
											decoration: BoxDecoration(
												shape: BoxShape.circle,
												color: node.activo
														? AppColors.success
														: AppColors.warning,
											),
										),
									if (node.kind == _PickerNodeKind.equipo)
										const SizedBox(width: 8),
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(
													node.label,
													style: TextStyle(
														fontWeight:
																selected ? FontWeight.w700 : FontWeight.w500,
														fontSize: 13,
														color: disabled
																? scheme.onSurfaceVariant
																: null,
													),
												),
												if (node.subtitle != null)
													Text(
														node.subtitle!,
														style: TextStyle(
															fontSize: 11,
															color: scheme.onSurfaceVariant,
														),
													),
											],
										),
									),
								],
							),
						),
					),
				),
				...node.children.map(
					(child) => _PickerExplorerTile(
						node: child,
						selectedId: selectedId,
						depth: depth + 1,
						onSelect: onSelect,
					),
				),
			],
		);
	}
}

class _InfoLine extends StatelessWidget {
	const _InfoLine({
		required this.icon,
		required this.label,
		required this.value,
	});

	final IconData icon;
	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
				const SizedBox(width: 8),
				Text(
					'$label: ',
					style: TextStyle(
						color: Theme.of(context).colorScheme.onSurfaceVariant,
						fontSize: 13,
					),
				),
				Expanded(
					child: Text(
						value,
						style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
					),
				),
			],
		);
	}
}
