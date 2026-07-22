import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/collapsible_panel.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../planta/presentation/planta_map_panel.dart';
import 'ot_emitir_accion_dialog.dart';
import 'ot_pdf.dart';

class OtNecesariasPage extends ConsumerStatefulWidget {
	const OtNecesariasPage({super.key});

	@override
	ConsumerState<OtNecesariasPage> createState() => _OtNecesariasPageState();
}

class _OtNecesariasPageState extends ConsumerState<OtNecesariasPage> {
	static final _dateFormat = DateFormat('dd/MM/yyyy');
	static const _accent = AppColors.accent;
	static const _mapExpandedWidth = 300.0;
	static const _mapCollapsedWidth = 0.0;

	List<Map<String, dynamic>> _items = [];
	List<Map<String, dynamic>> _tecnicos = [];
	final Set<String> _seleccionados = {};
	final Map<String, DateTime> _fechasProgramacion = {};
	final Map<String, String?> _tecnicoPorItem = {};

	DateTime _necesariasAl = DateTime.now();
	String? _filtroEquipoId;
	String? _filtroSectorId;
	PlantaMapSelection? _mapSelection;
	String? _highlightEquipoId;
	bool _showMapaMobile = false;
	bool _mapCollapsed = false;
	bool _loading = true;
	bool _emitiendo = false;
	String? _error;

	AuthUser? get _user => ref.read(authControllerProvider).session?.usuario;

	bool get _canEmitir =>
			_user?.tieneDerecho('programacion.ordenes_trabajo.emitir_periodica') ==
					true ||
			_user?.esAdministrador == true;

	String _toApiDate(DateTime date) {
		return '${date.year.toString().padLeft(4, '0')}-'
				'${date.month.toString().padLeft(2, '0')}-'
				'${date.day.toString().padLeft(2, '0')}';
	}

	String _itemKey(Map<String, dynamic> item) {
		return '${item['procedimientoId']}_${item['equipo']?['id']}';
	}

	@override
	void initState() {
		super.initState();
		final now = DateTime.now();
		_necesariasAl = DateTime(now.year, now.month + 1, 0);
		WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
	}

	Future<void> _bootstrap() async {
		setState(() {
			_loading = true;
			_error = null;
		});

		try {
			if (_user?.sucursalId == null) {
				throw Exception('Tu usuario no tiene planta asignada.');
			}

			final api = ref.read(apiClientProvider);
			final sucursalId = _user!.sucursalId!;
			final tecnicos = (await api.getList('ot/tecnicos?sucursalId=$sucursalId'))
					.cast<Map<String, dynamic>>();

			if (!mounted) return;
			setState(() => _tecnicos = tecnicos);

			await _cargarNecesarias();
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	Future<void> _cargarNecesarias() async {
		setState(() {
			_loading = true;
			_error = null;
		});

		try {
			final params = <String>[
				'necesariasAl=${_toApiDate(_necesariasAl)}',
			];
			if (_filtroEquipoId != null) params.add('equipoId=$_filtroEquipoId');
			if (_filtroSectorId != null) {
				params.add('sectorResponsableId=$_filtroSectorId');
			}

			final response = await ref
					.read(apiClientProvider)
					.getJson('ot/necesarias?${params.join('&')}');
			final items = (response['items'] as List<dynamic>? ?? [])
					.cast<Map<String, dynamic>>();

			if (!mounted) return;

			final fechas = <String, DateTime>{};
			for (final item in items) {
				final key = _itemKey(item);
				fechas[key] = _fechasProgramacion[key] ?? _necesariasAl;
			}

			setState(() {
				_items = items;
				_fechasProgramacion
					..clear()
					..addAll(fechas);
				_seleccionados.removeWhere(
					(key) => !items.any((item) => _itemKey(item) == key),
				);
			});
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	void _aplicarFiltroMapa([PlantaMapSelection? selection]) {
		final sel = selection ?? _mapSelection;
		setState(() {
			if (sel == null) {
				_filtroEquipoId = null;
				_filtroSectorId = null;
			} else {
				_mapSelection = sel;
				switch (sel.scope) {
					case PlantaMapScope.planta:
						_filtroEquipoId = null;
						_filtroSectorId = null;
					case PlantaMapScope.ubicacion:
						_filtroEquipoId = null;
						_filtroSectorId = sel.ubicacionId;
					case PlantaMapScope.equipo:
						_filtroEquipoId = sel.equipoId;
						_filtroSectorId = null;
						_highlightEquipoId = sel.equipoId;
				}
			}
		});
		_cargarNecesarias();
	}

	void _onMapSelectionChanged(PlantaMapSelection sel) {
		String? newEquipo;
		String? newSector;
		switch (sel.scope) {
			case PlantaMapScope.planta:
				newEquipo = null;
				newSector = null;
			case PlantaMapScope.ubicacion:
				newEquipo = null;
				newSector = sel.ubicacionId;
			case PlantaMapScope.equipo:
				newEquipo = sel.equipoId;
				newSector = null;
		}

		final sinCambio =
				_filtroEquipoId == newEquipo && _filtroSectorId == newSector;

		setState(() {
			_mapSelection = sel;
			_filtroEquipoId = newEquipo;
			_filtroSectorId = newSector;
			_highlightEquipoId =
					sel.scope == PlantaMapScope.equipo ? sel.equipoId : null;
		});

		if (!sinCambio) _cargarNecesarias();
	}

	Future<void> _pickNecesariasAl() async {
		final picked = await showDatePicker(
			context: context,
			initialDate: _necesariasAl,
			firstDate: DateTime(2020),
			lastDate: DateTime(2100),
		);
		if (picked == null) return;
		setState(() => _necesariasAl = picked);
		await _cargarNecesarias();
	}

	Future<void> _pickFechaItem(String key) async {
		final picked = await showDatePicker(
			context: context,
			initialDate: _fechasProgramacion[key] ?? DateTime.now(),
			firstDate: DateTime(2020),
			lastDate: DateTime(2100),
		);
		if (picked == null) return;
		setState(() => _fechasProgramacion[key] = picked);
	}

	Future<void> _emitirSeleccionadas() async {
		if (_seleccionados.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Seleccioná al menos un trabajo')),
			);
			return;
		}

		final previewItems = _items
				.where((item) => _seleccionados.contains(_itemKey(item)))
				.toList();

		await _emitirItems(previewItems);
	}

	Future<void> _activarItem(Map<String, dynamic> item) async {
		await _emitirItems([item]);
	}

	Future<void> _emitirItems(List<Map<String, dynamic>> previewItems) async {
		if (previewItems.isEmpty) return;

		final confirmed = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Vista previa de emisión'),
				content: SizedBox(
					width: 480,
					child: SingleChildScrollView(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: previewItems.map((item) {
								final key = _itemKey(item);
								final equipo = item['equipo'] as Map<String, dynamic>;
								return Padding(
									padding: const EdgeInsets.only(bottom: 12),
									child: Text(
										'• ${item['procedimientoCodigo']} — ${equipo['codigo']}\n'
										'  Programada: ${_dateFormat.format(_fechasProgramacion[key]!)}\n'
										'  Recibe: ${_tecnicoPorItem[key] != null ? _nombreTecnico(_tecnicoPorItem[key]!) : 'Sin asignar'}',
									),
								);
							}).toList(),
						),
					),
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Confirmar emisión'),
					),
				],
			),
		);

		if (confirmed != true) return;

		final tieneRecibe = previewItems.any(
			(item) => _tecnicoPorItem[_itemKey(item)] != null,
		);

		final accion = await showOtEmitirAccionDialog(
			context,
			tieneRecibe: tieneRecibe,
			recibeNombre: tieneRecibe ? 'los técnicos asignados' : null,
		);
		if (accion == null) return;

		setState(() => _emitiendo = true);
		try {
			final items = previewItems
					.map(
						(item) {
							final key = _itemKey(item);
							final tecnicoId = _tecnicoPorItem[key];
							return {
								'procedimientoId': item['procedimientoId'],
								'equipoId': item['equipo']['id'],
								'fechaProgramacion':
										_toApiDate(_fechasProgramacion[key]!),
								if (tecnicoId != null) 'tecnicoAsignadoId': tecnicoId,
								if (tecnicoId != null)
									'notificarAsignacion': notificarSegunAccion(accion),
							};
						},
					)
					.toList();

			final result = await ref.read(apiClientProvider).postJson(
						'ot/necesarias/emitir',
						{'items': items},
					);

			if (!mounted) return;

			if (generarPdfSegunAccion(accion)) {
				final ordenes = (result['ordenes'] as List?)
						?.cast<Map<String, dynamic>>() ??
						[];
				await abrirPdfOtList(
					ref,
					ordenes.map((ot) => ot['id'] as String).toList(),
				);
			}

			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(
						'${result['total'] ?? items.length} OT activadas. '
						'Ya están en Buscar OT.',
					),
					action: SnackBarAction(
						label: 'Buscar OT',
						onPressed: () => context.go('/ot'),
					),
				),
			);

			setState(() => _seleccionados.clear());
			await _cargarNecesarias();

			if (mounted) context.go('/ot');
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		} finally {
			if (mounted) setState(() => _emitiendo = false);
		}
	}

	void _toggleTodos(bool? value) {
		setState(() {
			if (value == true) {
				_seleccionados.addAll(_items.map(_itemKey));
			} else {
				_seleccionados.clear();
			}
		});
	}

	String _nombreTecnico(String id) {
		final t = _tecnicos.cast<Map<String, dynamic>?>().firstWhere(
					(x) => x?['id'] == id,
					orElse: () => null,
				);
		return t?['nombreUsuario'] as String? ?? id;
	}

	Widget _buildContent(ColorScheme scheme) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Padding(
					padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
					child: Row(
						children: [
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'OT necesarias de emitir',
											style: Theme.of(context)
													.textTheme
													.titleLarge
													?.copyWith(fontWeight: FontWeight.w800),
										),
										const SizedBox(height: 4),
										Text(
											'Preventivas asociadas — programá al fin de mes, '
											'asigná técnico o descargá PDF y activá',
											style: TextStyle(
												color: scheme.onSurfaceVariant,
												fontSize: 13,
											),
										),
									],
								),
							),
							if (_canEmitir && _seleccionados.isNotEmpty)
								FilledButton.icon(
									style: FilledButton.styleFrom(backgroundColor: _accent),
									onPressed: _emitiendo ? null : _emitirSeleccionadas,
									icon: _emitiendo
											? const SizedBox(
													width: 16,
													height: 16,
													child: CircularProgressIndicator(
														strokeWidth: 2,
														color: Colors.white,
													),
												)
											: const Icon(Icons.check_circle_rounded, size: 18),
									label: Text('Activar (${_seleccionados.length})'),
								),
						],
					),
				),
				Padding(
					padding: const EdgeInsets.symmetric(horizontal: 20),
					child: Wrap(
						spacing: 12,
						runSpacing: 10,
						crossAxisAlignment: WrapCrossAlignment.center,
						children: [
							OutlinedButton.icon(
								onPressed: _pickNecesariasAl,
								icon: const Icon(Icons.event_rounded, size: 18),
								label: Text('Necesarias al ${_dateFormat.format(_necesariasAl)}'),
							),
							if (_mapSelection != null)
								Chip(
									label: Text('Ámbito: ${_mapSelection!.label}'),
									onDeleted: () {
										setState(() {
											_mapSelection = null;
											_filtroEquipoId = null;
											_filtroSectorId = null;
										});
										_cargarNecesarias();
									},
								),
							IconButton(
								tooltip: 'Actualizar',
								onPressed: _cargarNecesarias,
								icon: const Icon(Icons.refresh_rounded),
							),
						],
					),
				),
				const SizedBox(height: 12),
				if (_error != null)
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 20),
						child: Text(_error!, style: TextStyle(color: scheme.error)),
					),
				Expanded(
					child: _items.isEmpty
							? Center(
									child: Column(
										mainAxisSize: MainAxisSize.min,
										children: [
											Icon(
												Icons.check_circle_outline_rounded,
												size: 56,
												color: scheme.onSurfaceVariant,
											),
											const SizedBox(height: 12),
											const Text('No hay OT necesarias para la fecha seleccionada'),
										],
									),
								)
							: ListView.separated(
									padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
									itemCount: _items.length,
									separatorBuilder: (_, __) => const SizedBox(height: 8),
									itemBuilder: (context, index) {
										final item = _items[index];
										final key = _itemKey(item);
										final equipo = item['equipo'] as Map<String, dynamic>;
										final ubicacion =
												equipo['ubicacion'] as Map<String, dynamic>?;
										final diasAtraso = item['diasAtraso'] as int? ?? 0;
										final selected = _seleccionados.contains(key);

										return Material(
											color: scheme.surfaceContainerLowest,
											borderRadius: BorderRadius.circular(14),
											child: InkWell(
												borderRadius: BorderRadius.circular(14),
												onTap: _canEmitir
														? () => setState(() {
																	if (selected) {
																		_seleccionados.remove(key);
																	} else {
																		_seleccionados.add(key);
																	}
																})
														: null,
												child: Padding(
													padding: const EdgeInsets.all(14),
													child: Row(
														crossAxisAlignment: CrossAxisAlignment.start,
														children: [
															if (_canEmitir)
																Checkbox(
																	value: selected,
																	onChanged: (value) => setState(() {
																		if (value == true) {
																			_seleccionados.add(key);
																		} else {
																			_seleccionados.remove(key);
																		}
																	}),
																),
															Expanded(
																child: Column(
																	crossAxisAlignment:
																			CrossAxisAlignment.start,
																	children: [
																		Text(
																			'#${item['procedimientoCodigo']} — ${item['procedimientoNombre']}',
																			style: const TextStyle(
																				fontWeight: FontWeight.w700,
																			),
																		),
																		const SizedBox(height: 4),
																		Text(
																			'${equipo['codigo']} — ${equipo['nombre']}'
																			' · ${ubicacion?['nombre'] ?? ''}',
																			style: TextStyle(
																				color: scheme.onSurfaceVariant,
																				fontSize: 13,
																			),
																		),
																		const SizedBox(height: 8),
																		Wrap(
																			spacing: 8,
																			runSpacing: 6,
																			children: [
																				_Chip(
																					label:
																							'Vence ${_dateFormat.format(DateTime.parse(item['fechaNecesaria'] as String))}',
																					tone: diasAtraso > 0
																							? _ChipTone.warning
																							: _ChipTone.neutral,
																				),
																				if (diasAtraso > 0)
																					_Chip(
																						label: '$diasAtraso días de atraso',
																						tone: _ChipTone.danger,
																					),
																				if (item['esPrimeraEmision'] == true)
																					const _Chip(
																						label: 'Nueva asociación',
																						tone: _ChipTone.warning,
																					),
																				_Chip(
																					label:
																							'Cada ${item['periodicidadDias']} días',
																					tone: _ChipTone.neutral,
																				),
																			],
																		),
																		if (_canEmitir) ...[
																			const SizedBox(height: 10),
																			DropdownButtonFormField<String?>(
																				value: _tecnicoPorItem[key],
																				isExpanded: true,
																				decoration: const InputDecoration(
																					labelText: 'Recibe',
																					isDense: true,
																					border: OutlineInputBorder(),
																				),
																				items: [
																					const DropdownMenuItem(
																						value: null,
																						child: Text('Sin asignar'),
																					),
																					..._tecnicos.map(
																						(t) => DropdownMenuItem(
																							value: t['id'] as String,
																							child: Text(
																								t['nombreUsuario'] as String,
																							),
																						),
																					),
																				],
																				onChanged: (value) => setState(
																					() => _tecnicoPorItem[key] = value,
																				),
																			),
																		],
																	],
																),
															),
															if (_canEmitir) ...[
																Column(
																	children: [
																		TextButton(
																			onPressed: () => _pickFechaItem(key),
																			child: Text(
																				_dateFormat.format(
																					_fechasProgramacion[key]!,
																				),
																			),
																		),
																		FilledButton.tonal(
																			onPressed: _emitiendo
																					? null
																					: () => _activarItem(item),
																			child: const Text('Activar'),
																		),
																	],
																),
															],
														],
													),
												),
											),
										);
									},
								),
				),
				if (_items.isNotEmpty && _canEmitir)
					Material(
						color: scheme.surface,
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
							child: Row(
								children: [
									Checkbox(
										tristate: true,
										value: _seleccionados.length == _items.length
												? true
												: _seleccionados.isEmpty
														? false
														: null,
										onChanged: _toggleTodos,
									),
									const Text('Seleccionar todas'),
								],
							),
						),
					),
			],
		);
	}

	@override
	Widget build(BuildContext context) {
		if (_loading && _items.isEmpty && _error == null) {
			return const Center(child: CircularProgressIndicator());
		}

		final scheme = Theme.of(context).colorScheme;
		final wide = MediaQuery.sizeOf(context).width >= 900;

		if (!wide && _showMapaMobile) {
			return Column(
				children: [
					ListTile(
						leading: IconButton(
							onPressed: () => setState(() => _showMapaMobile = false),
							icon: const Icon(Icons.arrow_back_rounded),
						),
						title: const Text('Mapa — OT necesarias'),
						trailing: FilledButton.tonalIcon(
							onPressed: () => setState(() => _showMapaMobile = false),
							icon: const Icon(Icons.check_rounded, size: 18),
							label: const Text('Listo'),
						),
					),
					Expanded(
						child: PlantaMapPanel(
							selection: _mapSelection,
							showSearchButton: false,
							onSelectionChanged: _onMapSelectionChanged,
						),
					),
				],
			);
		}

		if (!wide) {
			return Column(
				children: [
					Expanded(child: _buildContent(scheme)),
					SafeArea(
						child: Padding(
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
							child: SizedBox(
								width: double.infinity,
								child: FilledButton.tonalIcon(
									onPressed: () => setState(() => _showMapaMobile = true),
									icon: const Icon(Icons.map_rounded),
									label: const Text('Elegir ámbito en mapa'),
								),
							),
						),
					),
				],
			);
		}

		return Row(
			children: [
				Expanded(child: _buildContent(scheme)),
				PanelCollapseHandle(
					collapsed: _mapCollapsed,
					onToggle: () => setState(() => _mapCollapsed = !_mapCollapsed),
					edge: PanelCollapseEdge.end,
					topOffset: 20,
					expandTooltip: 'Mostrar mapa',
					collapseTooltip: 'Ocultar mapa',
				),
				CollapsiblePanel(
					collapsed: _mapCollapsed,
					expandedWidth: _mapExpandedWidth,
					collapsedWidth: _mapCollapsedWidth,
					child: PlantaMapPanel(
						compact: true,
						selection: _mapSelection,
						highlightEquipoId:
								_showMapaMobile ? null : _highlightEquipoId,
						onSelectionChanged: _onMapSelectionChanged,
						onSearch: () => _aplicarFiltroMapa(),
					),
				),
			],
		);
	}
}

enum _ChipTone { neutral, warning, danger }

class _Chip extends StatelessWidget {
	const _Chip({required this.label, required this.tone});

	final String label;
	final _ChipTone tone;

	@override
	Widget build(BuildContext context) {
		final colors = switch (tone) {
			_ChipTone.neutral => (const Color(0xFFE2E8F0), const Color(0xFF475569)),
			_ChipTone.warning => (const Color(0xFFFFF0E6), AppColors.brandOrange),
			_ChipTone.danger => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
		};

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
			decoration: BoxDecoration(
				color: colors.$1,
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				label,
				style: TextStyle(
					color: colors.$2,
					fontSize: 11,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}
}
