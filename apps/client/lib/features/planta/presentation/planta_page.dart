import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/shell_back_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import 'planta_actions.dart';
import 'planta_clipboard.dart';
import 'planta_equipo_ficha.dart';
import 'planta_export.dart';
import 'planta_print.dart';
import 'planta_toolbar.dart';
import 'planta_ui.dart';

enum _NodeKind { empresa, planta, ubicacion, maquina }

class _TreeNode {
	_TreeNode({
		required this.id,
		required this.label,
		required this.kind,
		required this.activo,
		this.children = const [],
		this.raw,
	});

	final String id;
	final String label;
	final _NodeKind kind;
	final bool activo;
	final List<_TreeNode> children;
	final Map<String, dynamic>? raw;
}

class PlantaPage extends ConsumerStatefulWidget {
	const PlantaPage({super.key});

	@override
	ConsumerState<PlantaPage> createState() => _PlantaPageState();
}

class _PlantaPageState extends ConsumerState<PlantaPage> {
	static const _empresaNombre = 'SIKA';

	String? _sucursalId;
	String? _plantaNombre;
	List<Map<String, dynamic>> _sucursales = [];
	List<Map<String, dynamic>> _ubicacionesTree = [];
	List<Map<String, dynamic>> _equipos = [];
	List<Map<String, dynamic>> _tipos = [];
	_TreeNode? _selected;
	Map<String, dynamic>? _equipoDetalle;
	PlantaClipboard? _clipboard;
	String _search = '';
	bool _loading = true;
	String? _error;
	/// En mobile/tablet: muestra detalle a pantalla completa tras elegir un nodo.
	bool _compactShowDetail = false;
	final Set<String> _expandedIds = {};

	void _seedExpanded(_TreeNode root) {
		_expandedIds.clear();
		// Solo planta + ubicaciones de 1er nivel abiertas; sectores/máquinas colapsables.
		void walk(_TreeNode node, int depth) {
			if (node.children.isEmpty) return;
			if (depth <= 1) {
				_expandedIds.add(node.id);
			}
			for (final child in node.children) {
				walk(child, depth + 1);
			}
		}
		walk(root, 0);
	}

	void _toggleExpand(String id) {
		setState(() {
			if (_expandedIds.contains(id)) {
				_expandedIds.remove(id);
			} else {
				_expandedIds.add(id);
			}
		});
	}

	void _expandMatching(_TreeNode node) {
		if (node.children.isEmpty) return;
		_expandedIds.add(node.id);
		for (final child in node.children) {
			_expandMatching(child);
		}
	}

	AuthUser? get _user => ref.read(authControllerProvider).session?.usuario;

	bool get _canEditUbicaciones =>
			_user?.tieneDerecho('archivos.ubicaciones.agregar_nodo') == true;

	bool get _canEditEquipos =>
			_user?.tieneDerecho('archivos.equipos.agregar') == true;

	bool get _canModificarUbicaciones =>
			_user?.tieneDerecho('archivos.ubicaciones.modificar_nodo') == true;

	bool get _canBorrarUbicaciones =>
			_user?.tieneDerecho('archivos.ubicaciones.borrar_nodo') == true;

	bool get _canMoverUbicaciones =>
			_user?.tieneDerecho('archivos.ubicaciones.mover_nodo') == true;

	bool get _canModificarEquipos =>
			_user?.tieneDerecho('archivos.equipos.modificar') == true;

	bool get _canMoverEquipos =>
			_user?.tieneDerecho('archivos.equipos.mover') == true;

	bool get _canCopiarEquipos =>
			_user?.tieneDerecho('archivos.equipos.copiar') == true ||
			_user?.esAdministrador == true;

	bool get _canBorrarEquipos =>
			_user?.tieneDerecho('archivos.equipos.borrar') == true ||
			_user?.esAdministrador == true;

	bool get _canCambiarPlanta =>
			_user?.esAdministrador == true || _user?.supervisaSucursales == true;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
	}

	Future<void> _bootstrap() async {
		setState(() {
			_loading = true;
			_error = null;
		});

		try {
			final api = ref.read(apiClientProvider);
			final user = _user;

			if (user?.sucursalId == null && !_canCambiarPlanta) {
				throw Exception('Tu usuario no tiene planta asignada.');
			}

			if (_canCambiarPlanta) {
				_sucursales = (await api.getList('sucursales')).cast<Map<String, dynamic>>();
			}

			_sucursalId = user?.sucursalId ?? _sucursales.firstOrNull?['id'] as String?;
			_plantaNombre = user?.sucursalNombre ??
					_sucursales.where((s) => s['id'] == _sucursalId).map((s) => s['nombre'] as String).firstOrNull ??
					'PLANTA';

			if (_sucursalId == null) throw Exception('No hay plantas disponibles');

			final tipos = await api.getList('tipos-equipo');
			_tipos = tipos.cast<Map<String, dynamic>>();
			await _reload();

			_selected = _TreeNode(
				id: 'planta:$_sucursalId',
				label: _plantaNombre!,
				kind: _NodeKind.planta,
				activo: true,
			);
		} catch (error) {
			_error = error.toString();
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	Future<void> _reload() async {
		final api = ref.read(apiClientProvider);
		final query = '?sucursalId=$_sucursalId';
		final tree = await api.getList('ubicaciones/tree$query');
		final equipos = await api.getList('equipos$query');
		setState(() {
			_ubicacionesTree = tree.cast<Map<String, dynamic>>();
			_equipos = equipos.cast<Map<String, dynamic>>();
			_equipoDetalle = null;
			_seedExpanded(_buildExplorerTree());
		});
	}

	_TreeNode _buildExplorerTree() {
		final plantaChildren = _ubicacionesTree
				.map((node) => _mapUbicacionNode(node))
				.toList();

		return _TreeNode(
			id: 'empresa',
			label: _empresaNombre,
			kind: _NodeKind.empresa,
			activo: true,
			children: [
				_TreeNode(
					id: 'planta:$_sucursalId',
					label: _plantaNombre ?? 'PLANTA',
					kind: _NodeKind.planta,
					activo: true,
					children: plantaChildren,
				),
			],
		);
	}

	_TreeNode _mapUbicacionNode(Map<String, dynamic> node) {
		final childrenUbic = (node['children'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>();
		final id = node['id'] as String;
		final maquinas = _equipos
				.where((e) => e['ubicacionId'] == id)
				.map(
					(e) => _TreeNode(
						id: 'maquina:${e['id']}',
						label: e['nombre'] as String,
						kind: _NodeKind.maquina,
						activo: !(e['fueraDeServicio'] as bool? ?? false) &&
								(e['activo'] as bool? ?? true),
						raw: e,
					),
				)
				.toList();

		final children = [
			...childrenUbic.map(_mapUbicacionNode),
			...maquinas,
		];

		return _TreeNode(
			id: 'ubicacion:$id',
			label: node['nombre'] as String,
			kind: _NodeKind.ubicacion,
			activo: node['activa'] as bool? ?? true,
			children: children,
			raw: node,
		);
	}

	List<_TreeNode> _filterTree(_TreeNode node) {
		if (_search.trim().isEmpty) return [node];
		final query = _search.trim().toLowerCase();

		_TreeNode? filter(_TreeNode current) {
			final childMatches = current.children
					.map(filter)
					.whereType<_TreeNode>()
					.toList();
			final selfMatch = current.label.toLowerCase().contains(query);
			if (selfMatch || childMatches.isNotEmpty) {
				return _TreeNode(
					id: current.id,
					label: current.label,
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

	int get _totalMaquinas => _equipos.length;

	int get _activas => _equipos
			.where(
				(e) =>
						(e['activo'] as bool? ?? true) &&
						!(e['fueraDeServicio'] as bool? ?? false),
			)
			.length;

	int get _desactivadas => _totalMaquinas - _activas;

	int get _sectoresCount {
		int count = 0;
		void walk(List<Map<String, dynamic>> nodes) {
			for (final node in nodes) {
				count++;
				walk((node['children'] as List<dynamic>? ?? [])
						.cast<Map<String, dynamic>>());
			}
		}

		walk(_ubicacionesTree);
		return count;
	}

	List<_TreeNode> _ubicacionesHojaDesde(_TreeNode node) {
		if (node.kind == _NodeKind.planta || node.kind == _NodeKind.empresa) {
			return node.children.expand(_ubicacionesHojaDesde).toList();
		}
		if (node.kind == _NodeKind.ubicacion) {
			final hasChildUbic = node.children.any((c) => c.kind == _NodeKind.ubicacion);
			if (!hasChildUbic) return [node];
			return node.children
					.where((c) => c.kind == _NodeKind.ubicacion)
					.expand(_ubicacionesHojaDesde)
					.toList();
		}
		return [];
	}

	Future<void> _select(_TreeNode node) async {
		final compact =
				MediaQuery.sizeOf(context).width < Breakpoints.tablet;
		setState(() {
			_selected = node;
			_equipoDetalle = null;
			// En mobile solo abrimos detalle al tocar máquina (acciones quedan en el árbol).
			if (compact && node.kind == _NodeKind.maquina) {
				_compactShowDetail = true;
			} else if (compact && node.kind != _NodeKind.maquina) {
				_compactShowDetail = false;
			}
		});

		if (node.kind == _NodeKind.maquina) {
			final id = node.id.replaceFirst('maquina:', '');
			try {
				final detalle = await ref.read(apiClientProvider).getJson('equipos/$id');
				if (mounted) setState(() => _equipoDetalle = detalle);
			} catch (error) {
				if (!mounted) return;
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('$error')),
				);
			}
		}
	}

	Future<void> _onEquipoUpdated() async {
		final node = _selected;
		await _reload();
		if (node?.kind == _NodeKind.maquina) await _select(node!);
	}

	Future<void> _onSucursalChanged(String? id) async {
		if (id == null || id == _sucursalId) return;
		final sucursal = _sucursales.firstWhere((s) => s['id'] == id, orElse: () => {});
		setState(() {
			_sucursalId = id;
			_plantaNombre = sucursal['nombre'] as String? ?? 'PLANTA';
			_selected = _TreeNode(
				id: 'planta:$_sucursalId',
				label: _plantaNombre!,
				kind: _NodeKind.planta,
				activo: true,
			);
		});
		await _reload();
	}

	Set<String> _descendantUbicacionIds(_TreeNode node) {
		final ids = <String>{node.id.replaceFirst('ubicacion:', '')};
		for (final child in node.children) {
			if (child.kind == _NodeKind.ubicacion) ids.addAll(_descendantUbicacionIds(child));
		}
		return ids;
	}

	List<Map<String, String>> _ubicacionesHojaOptions() {
		return _ubicacionesHojaDesde(_buildExplorerTree())
				.map((n) => {
							'id': n.id.replaceFirst('ubicacion:', ''),
							'label': n.label,
						})
				.toList();
	}

	Future<void> _editUbicacion(_TreeNode node) async {
		final ok = await showEditUbicacionDialog(
			context: context,
			api: ref.read(apiClientProvider),
			ubicacionId: node.id.replaceFirst('ubicacion:', ''),
			nombreActual: node.label,
		);
		if (ok) await _reload();
	}

	Future<void> _deleteUbicacion(_TreeNode node) async {
		final ok = await confirmDeleteUbicacion(
			context: context,
			api: ref.read(apiClientProvider),
			ubicacionId: node.id.replaceFirst('ubicacion:', ''),
			nombre: node.label,
		);
		if (!ok || !mounted) return;
		setState(() {
			_selected = _TreeNode(
				id: 'planta:$_sucursalId',
				label: _plantaNombre ?? 'PLANTA',
				kind: _NodeKind.planta,
				activo: true,
			);
		});
		await _reload();
	}

	Future<void> _moverUbicacion(_TreeNode node) async {
		final ok = await showMoverUbicacionDialog(
			context: context,
			api: ref.read(apiClientProvider),
			ubicacionId: node.id.replaceFirst('ubicacion:', ''),
			ubicacionesTree: _ubicacionesTree,
			excludeIds: _descendantUbicacionIds(node),
		);
		if (ok) await _reload();
	}

	Future<void> _editEquipo() async {
		final detalle = _equipoDetalle;
		if (detalle == null) return;
		final ok = await showEditEquipoDialog(
			context: context,
			api: ref.read(apiClientProvider),
			detalle: detalle,
		);
		if (ok) await _onEquipoUpdated();
	}

	Future<void> _deleteEquipo() async {
		final detalle = _equipoDetalle;
		if (detalle == null) return;

		final confirmado = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Dar de baja la máquina'),
				content: Text(
					'¿Querés dar de baja ${detalle['codigo']} — ${detalle['nombre']}?\n\n'
					'Solo es posible si no tiene órdenes de trabajo. La máquina dejará de aparecer en el explorador.',
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Dar de baja'),
					),
				],
			),
		);

		if (confirmado != true) return;

		try {
			await ref.read(apiClientProvider).deleteJson('equipos/${detalle['id']}');
			if (!mounted) return;
			setState(() {
				_selected = _TreeNode(
					id: 'planta:$_sucursalId',
					label: _plantaNombre ?? 'PLANTA',
					kind: _NodeKind.planta,
					activo: true,
				);
				_equipoDetalle = null;
			});
			await _reload();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Máquina dada de baja')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	void _exportEquipos() {
		if (_equipos.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('No hay máquinas para exportar en esta planta')),
			);
			return;
		}
		PlantaExport.downloadEquipos(_equipos);
	}

	void _imprimirEquipos({String? sectorFiltro}) {
		if (_equipos.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('No hay máquinas para imprimir en esta planta')),
			);
			return;
		}
		PlantaPrint.previewEquipos(
			empresaNombre: _empresaNombre,
			plantaNombre: _plantaNombre ?? 'PLANTA',
			equipos: _equipos,
			sectorFiltro: sectorFiltro,
		);
	}

	void _onToolbarModificar() {
		final selected = _selected;
		if (selected == null) return;
		if (selected.kind == _NodeKind.maquina) {
			_editEquipo();
		} else if (selected.kind == _NodeKind.ubicacion) {
			_editUbicacion(selected);
		}
	}

	void _onToolbarMover() {
		final selected = _selected;
		if (selected == null) return;
		if (selected.kind == _NodeKind.maquina) {
			_moverEquipo();
		} else if (selected.kind == _NodeKind.ubicacion) {
			_moverUbicacion(selected);
		}
	}

	void _onToolbarEliminar() {
		final selected = _selected;
		if (selected == null) return;
		if (selected.kind == _NodeKind.maquina) {
			_deleteEquipo();
		} else if (selected.kind == _NodeKind.ubicacion) {
			_deleteUbicacion(selected);
		}
	}

	Future<void> _moverEquipo() async {
		final detalle = _equipoDetalle;
		if (detalle == null) return;
		final ok = await showMoverEquipoDialog(
			context: context,
			api: ref.read(apiClientProvider),
			equipoId: detalle['id'] as String,
			hojas: _ubicacionesHojaOptions(),
		);
		if (ok) await _reload();
	}

	Future<void> _createUbicacion({String? parentId}) async {
		final controller = TextEditingController();
		final nombre = await showDialog<String>(
			context: context,
			builder: (context) => AlertDialog(
				title: Text(parentId == null ? 'Nueva ubicación' : 'Nuevo sector'),
				content: TextField(
					controller: controller,
					autofocus: true,
					decoration: InputDecoration(
						labelText: parentId == null ? 'Nombre de ubicación' : 'Nombre de sector',
						hintText: parentId == null ? 'Ej: SILOS EXTERNOS' : 'Ej: SECTOR LOSA',
					),
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Cancelar'),
					),
					FilledButton(
						onPressed: () => Navigator.pop(context, controller.text.trim()),
						child: const Text('Crear'),
					),
				],
			),
		);

		if (nombre == null || nombre.isEmpty) return;

		try {
			await ref.read(apiClientProvider).postJson('ubicaciones', {
				'sucursalId': _sucursalId,
				if (parentId != null) 'parentId': parentId,
				'nombre': nombre.toUpperCase(),
			});
			await _reload();
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
	}

	Future<void> _createMaquina(String ubicacionId, String ubicacionNombre) async {
		final ok = await showCreateMaquinaDialog(
			context: context,
			api: ref.read(apiClientProvider),
			sucursalId: _sucursalId!,
			ubicacionId: ubicacionId,
			ubicacionNombre: ubicacionNombre,
			tipos: _tipos,
		);
		if (ok) await _reload();
	}

	bool _isUbicacionHoja(_TreeNode node) {
		if (node.kind != _NodeKind.ubicacion) return false;
		return !node.children.any((child) => child.kind == _NodeKind.ubicacion);
	}

	void _copiarEquipoSeleccionado() {
		final detalle = _equipoDetalle;
		final node = _selected;
		if (detalle == null || node?.kind != _NodeKind.maquina) return;
		setState(() {
			_clipboard = PlantaClipboard(
				equipoId: detalle['id'] as String,
				nombre: detalle['nombre'] as String,
				codigo: detalle['codigo'] as String,
				mode: PlantaClipboardMode.copiar,
			);
		});
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('Copiado: ${detalle['nombre']}')),
		);
	}

	void _cortarEquipoSeleccionado() {
		final detalle = _equipoDetalle;
		final node = _selected;
		if (detalle == null || node?.kind != _NodeKind.maquina) return;
		setState(() {
			_clipboard = PlantaClipboard(
				equipoId: detalle['id'] as String,
				nombre: detalle['nombre'] as String,
				codigo: detalle['codigo'] as String,
				mode: PlantaClipboardMode.mover,
			);
		});
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('Listo para mover: ${detalle['nombre']}')),
		);
	}

	Future<void> _pegarClipboard() async {
		final clipboard = _clipboard;
		final target = _selected;
		if (clipboard == null || target == null) return;

		final api = ref.read(apiClientProvider);

		try {
			if (clipboard.isMove) {
				if (!_canMoverEquipos) return;
				if (target.kind != _NodeKind.ubicacion || !_isUbicacionHoja(target)) {
					throw Exception('Seleccione una ubicación hoja para mover el equipo');
				}
				final ubicacionId = target.id.replaceFirst('ubicacion:', '');
				await api.postJson('equipos/${clipboard.equipoId}/mover', {
					'ubicacionId': ubicacionId,
				});
			} else {
				if (!_canCopiarEquipos) return;
				if (target.kind == _NodeKind.maquina) {
					final targetId = target.id.replaceFirst('maquina:', '');
					await api.postJson('equipos/$targetId/pegar-componentes', {
						'sourceEquipoId': clipboard.equipoId,
					});
				} else if (target.kind == _NodeKind.ubicacion && _isUbicacionHoja(target)) {
					final ubicacionId = target.id.replaceFirst('ubicacion:', '');
					await api.postJson('equipos/${clipboard.equipoId}/duplicar', {
						'ubicacionId': ubicacionId,
					});
				} else {
					throw Exception('Seleccione un equipo o ubicación hoja para pegar');
				}
			}

			if (!mounted) return;
			setState(() => _clipboard = null);
			await _reload();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Operación completada')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
	}

	Future<void> _listarEquipos() async {
		final controller = TextEditingController();
		var query = '';

		final selectedId = await showDialog<String>(
			context: context,
			builder: (ctx) => StatefulBuilder(
				builder: (context, setDialogState) {
					final filtered = _equipos.where((equipo) {
						if (query.trim().isEmpty) return true;
						final q = query.trim().toLowerCase();
						final nombre = (equipo['nombre'] as String? ?? '').toLowerCase();
						final codigo = (equipo['codigo'] as String? ?? '').toLowerCase();
						return nombre.contains(q) || codigo.contains(q);
					}).toList();

					return AlertDialog(
						title: const Text('Buscar máquina'),
						content: SizedBox(
							width: (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 460.0),
							height: (MediaQuery.sizeOf(context).height * 0.55).clamp(280.0, 460.0),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									TextField(
										controller: controller,
										autofocus: true,
										decoration: const InputDecoration(
											labelText: 'Nombre o código',
											hintText: 'Ej: SILO-104',
											prefixIcon: Icon(Icons.search_rounded),
											border: OutlineInputBorder(),
										),
										onChanged: (value) => setDialogState(() => query = value),
									),
									const SizedBox(height: 8),
									Text(
										'${filtered.length} de ${_equipos.length} máquinas',
										style: TextStyle(
											fontSize: 12,
											color: Theme.of(context).colorScheme.onSurfaceVariant,
										),
									),
									const SizedBox(height: 8),
									Expanded(
										child: filtered.isEmpty
												? PlantaEmptyState(
														icon: Icons.precision_manufacturing_outlined,
														title: query.trim().isEmpty
																? 'No hay máquinas en esta planta'
																: 'Sin resultados',
														message: query.trim().isEmpty
																? 'Agregá la primera máquina desde un sector.'
																: 'Probá con otro nombre o código.',
													)
												: ListView.separated(
														itemCount: filtered.length,
														separatorBuilder: (_, __) => const Divider(height: 1),
														itemBuilder: (context, index) {
															final equipo = filtered[index];
															final tipo = equipo['tipoEquipo'] as Map<String, dynamic>?;
															final ubicacion = equipo['ubicacion'] as Map<String, dynamic>?;
															return ListTile(
																leading: CircleAvatar(
																	backgroundColor: AppColors.brandYellow.withValues(alpha: 0.15),
																	child: const Icon(
																		Icons.precision_manufacturing_outlined,
																		size: 20,
																		color: AppColors.brandYellow,
																	),
																),
																title: Text(equipo['nombre'] as String? ?? ''),
																subtitle: Text(
																	'${equipo['codigo'] ?? ''} · ${tipo?['nombre'] ?? ''} · ${ubicacion?['nombre'] ?? ''}',
																	maxLines: 2,
																	overflow: TextOverflow.ellipsis,
																),
																onTap: () => Navigator.pop(
																	ctx,
																	equipo['id'] as String,
																),
															);
														},
													),
									),
								],
							),
						),
						actions: [
							TextButton.icon(
								onPressed: _equipos.isEmpty
										? null
										: () {
												Navigator.pop(ctx);
												_imprimirEquipos(
													sectorFiltro: query.trim().isEmpty ? null : query.trim(),
												);
											},
								icon: const Icon(Icons.print_outlined, size: 18),
								label: const Text('Imprimir listado'),
							),
							TextButton(
								onPressed: () => Navigator.pop(ctx),
								child: const Text('Cerrar'),
							),
						],
					);
				},
			),
		);

		controller.dispose();
		if (selectedId == null || !mounted) return;

		final node = _findMaquinaNode(_buildExplorerTree(), selectedId);
		if (node != null) await _select(node);
	}

	_TreeNode? _findMaquinaNode(_TreeNode node, String equipoId) {
		if (node.kind == _NodeKind.maquina && node.id == 'maquina:$equipoId') {
			return node;
		}
		for (final child in node.children) {
			final found = _findMaquinaNode(child, equipoId);
			if (found != null) return found;
		}
		return null;
	}

	Future<void> _onDrop(PlantaDragPayload payload, _TreeNode target) async {
		final api = ref.read(apiClientProvider);

		try {
			if (payload.kind == PlantaDragKind.equipo) {
				if (!_canMoverEquipos) return;
				if (target.kind != _NodeKind.ubicacion || !_isUbicacionHoja(target)) {
					throw Exception('Soltar sobre una ubicación hoja');
				}
				final ubicacionId = target.id.replaceFirst('ubicacion:', '');
				await api.postJson('equipos/${payload.id}/mover', {
					'ubicacionId': ubicacionId,
				});
			} else {
				if (!_canMoverUbicaciones) return;
				final ubicacionId = payload.id;
				final parentId = switch (target.kind) {
					_NodeKind.planta => null,
					_NodeKind.ubicacion => target.id.replaceFirst('ubicacion:', ''),
					_ => throw Exception('Destino inválido para ubicación'),
				};
				await api.postJson('ubicaciones/$ubicacionId/mover', {
					if (parentId != null) 'parentId': parentId,
				});
			}

			if (!mounted) return;
			await _reload();
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
	}

	bool get _canPegar {
		final clipboard = _clipboard;
		final target = _selected;
		if (clipboard == null || target == null) return false;

		if (clipboard.isMove) {
			return _canMoverEquipos &&
					target.kind == _NodeKind.ubicacion &&
					_isUbicacionHoja(target);
		}

		if (!_canCopiarEquipos) return false;
		if (target.kind == _NodeKind.maquina) return true;
		return target.kind == _NodeKind.ubicacion && _isUbicacionHoja(target);
	}

	void _onAddPressed() {
		final selected = _selected;
		if (selected == null) return;

		if (selected.kind == _NodeKind.planta && _canEditUbicaciones) {
			_createUbicacion();
			return;
		}

		if (selected.kind == _NodeKind.ubicacion) {
			final ubicacionId = selected.id.replaceFirst('ubicacion:', '');
			final hasChildUbicaciones = selected.children.any(
				(child) => child.kind == _NodeKind.ubicacion,
			);
			final hasMaquinas = selected.children.any(
				(child) => child.kind == _NodeKind.maquina,
			);

			showModalBottomSheet<void>(
				context: context,
				showDragHandle: true,
				builder: (context) => SafeArea(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							if (_canEditUbicaciones && !hasMaquinas)
								ListTile(
									leading: const Icon(Icons.folder_outlined),
									title: const Text('Agregar sector'),
									subtitle: Text('Dentro de ${selected.label}'),
									onTap: () {
										Navigator.pop(context);
										_createUbicacion(parentId: ubicacionId);
									},
								),
							if (_canEditEquipos && !hasChildUbicaciones)
								ListTile(
									leading: const Icon(Icons.precision_manufacturing_outlined),
									title: const Text('Agregar máquina'),
									subtitle: Text('En ${selected.label}'),
									onTap: () {
										Navigator.pop(context);
										_createMaquina(ubicacionId, selected.label);
									},
								),
							if ((!_canEditUbicaciones || hasMaquinas) &&
									(!_canEditEquipos || hasChildUbicaciones))
								const ListTile(
									title: Text('No hay acciones disponibles en este nodo'),
								),
						],
					),
				),
			);
		}
	}

	bool get _showAddButton {
		final selected = _selected;
		if (selected == null) return false;
		if (selected.kind == _NodeKind.planta) return _canEditUbicaciones;
		if (selected.kind == _NodeKind.ubicacion) {
			return _canEditUbicaciones || _canEditEquipos;
		}
		return false;
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final explorerBg = isDark ? AppColors.explorerPanel : Colors.white;
		final pageBg = isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9);
		final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;

		if (_loading) {
			return const Scaffold(body: Center(child: CircularProgressIndicator()));
		}

		if (_error != null) {
			return Scaffold(
				appBar: AppBar(
					automaticallyImplyLeading: false,
					leading: const ShellBackButton(),
					title: const Text('Gestión de equipos'),
				),
				body: Center(child: Text(_error!)),
			);
		}

		final root = _buildExplorerTree();
		final visible = _filterTree(root);

		if (compact) {
			return Scaffold(
				backgroundColor: pageBg,
				body: _compactShowDetail
						? _buildDetailColumn(
								scheme: scheme,
								pageBg: pageBg,
								compact: true,
								onBackToExplorer: () => setState(() => _compactShowDetail = false),
							)
						: Column(
								children: [
									_buildToolbar(),
									Expanded(
										child: _buildExplorerPanel(
											scheme: scheme,
											explorerBg: explorerBg,
											isDark: isDark,
											visible: visible,
											compact: true,
										),
									),
								],
							),
			);
		}

		return Scaffold(
			backgroundColor: pageBg,
			body: Row(
				children: [
					SizedBox(
						width: 320,
						child: _buildExplorerPanel(
							scheme: scheme,
							explorerBg: explorerBg,
							isDark: isDark,
							visible: visible,
							compact: false,
						),
					),
					VerticalDivider(
						width: 1,
						color: scheme.outlineVariant.withValues(alpha: 0.4),
					),
					Expanded(
						child: _buildDetailColumn(
							scheme: scheme,
							pageBg: pageBg,
							compact: false,
						),
					),
				],
			),
		);
	}

	Widget _buildToolbar() {
		return PlantaToolbar(
			plantaNombre: _plantaNombre ?? '',
			onRefresh: _bootstrap,
			sucursales: _canCambiarPlanta ? _sucursales : const [],
			sucursalId: _sucursalId,
			onSucursalChanged: _canCambiarPlanta ? _onSucursalChanged : null,
			selectionKind: switch (_selected?.kind) {
				_NodeKind.maquina => 'maquina',
				_NodeKind.ubicacion => 'ubicacion',
				_NodeKind.planta => 'planta',
				_ => null,
			},
			clipboardLabel: _clipboard?.nombre,
			canAgregar: _showAddButton,
			onAgregar: _onAddPressed,
			canModificar:
					(_selected?.kind == _NodeKind.maquina && _canModificarEquipos) ||
					(_selected?.kind == _NodeKind.ubicacion && _canModificarUbicaciones),
			onModificar: _onToolbarModificar,
			canEliminar:
					(_selected?.kind == _NodeKind.maquina && _canBorrarEquipos) ||
					(_selected?.kind == _NodeKind.ubicacion && _canBorrarUbicaciones),
			onEliminar: _onToolbarEliminar,
			canMover:
					(_selected?.kind == _NodeKind.maquina && _canMoverEquipos) ||
					(_selected?.kind == _NodeKind.ubicacion && _canMoverUbicaciones),
			onMover: _onToolbarMover,
			canCopiar: _selected?.kind == _NodeKind.maquina && _canCopiarEquipos,
			onCopiar: _copiarEquipoSeleccionado,
			canCortar: _selected?.kind == _NodeKind.maquina && _canMoverEquipos,
			onCortar: _cortarEquipoSeleccionado,
			canPegar: _canPegar,
			onPegar: _canPegar ? () => _pegarClipboard() : null,
			onBuscar: () => _listarEquipos(),
			onImprimir: _imprimirEquipos,
			onExportar: _exportEquipos,
		);
	}

	Widget _buildExplorerPanel({
		required ColorScheme scheme,
		required Color explorerBg,
		required bool isDark,
		required List<_TreeNode> visible,
		required bool compact,
	}) {
		return Material(
			color: explorerBg,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: EdgeInsets.fromLTRB(compact ? 8 : 12, compact ? 12 : 20, 16, 8),
						child: Row(
							children: [
								const ShellBackButton(),
								const SizedBox(width: 4),
								Expanded(
									child: Text(
										'Explorador de equipos',
										style: Theme.of(context).textTheme.titleMedium?.copyWith(
													fontWeight: FontWeight.w700,
												),
									),
								),
							],
						),
					),
					if (compact)
						Padding(
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
							child: Text(
								'Seleccioná un sector para Agregar/Editar. Tocá una máquina para ver su ficha.',
								style: TextStyle(
									fontSize: 12,
									color: scheme.onSurfaceVariant,
								),
							),
						),
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 16),
						child: TextField(
							onChanged: (value) => setState(() {
								_search = value;
								if (value.trim().isNotEmpty) {
									for (final node in _filterTree(_buildExplorerTree())) {
										_expandMatching(node);
									}
								}
							}),
							decoration: InputDecoration(
								hintText: 'Buscar sector o máquina…',
								helperText: compact ? null : 'Ej: SILO, sector losa, código de máquina',
								helperMaxLines: 2,
								prefixIcon: const Icon(Icons.search, size: 20),
								filled: true,
								fillColor: isDark
										? Colors.white.withValues(alpha: 0.06)
										: const Color(0xFFF8FAFC),
								border: OutlineInputBorder(
									borderRadius: BorderRadius.circular(12),
									borderSide: BorderSide.none,
								),
								contentPadding: const EdgeInsets.symmetric(vertical: 12),
							),
						),
					),
					const SizedBox(height: 8),
					Expanded(
						child: visible.isEmpty
								? const Center(child: Text('Sin resultados'))
								: ListView(
										padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
										children: visible
												.map(
													(node) => _ExplorerTile(
														node: node,
														selectedId: _selected?.id,
														depth: 0,
														expandedIds: _expandedIds,
														onToggleExpand: _toggleExpand,
														onSelect: _select,
														onDrop: _onDrop,
														canDragEquipo: _canMoverEquipos,
														canDragUbicacion: _canMoverUbicaciones,
														isUbicacionHoja: _isUbicacionHoja,
													),
												)
												.toList(),
									),
					),
				],
			),
		);
	}

	Widget _buildDetailColumn({
		required ColorScheme scheme,
		required Color pageBg,
		required bool compact,
		VoidCallback? onBackToExplorer,
	}) {
		return ColoredBox(
			color: pageBg,
			child: Column(
				children: [
					if (onBackToExplorer != null)
						Material(
							color: scheme.surface,
							child: SafeArea(
								bottom: false,
								child: InkWell(
									onTap: onBackToExplorer,
									child: Padding(
										padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
										child: Row(
											children: [
												Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
												const SizedBox(width: 8),
												Expanded(
													child: Text(
														_selected?.label ?? 'Explorador',
														maxLines: 1,
														overflow: TextOverflow.ellipsis,
														style: const TextStyle(fontWeight: FontWeight.w700),
													),
												),
												TextButton(
													onPressed: onBackToExplorer,
													child: const Text('Árbol'),
												),
											],
										),
									),
								),
							),
						),
					_buildToolbar(),
					Expanded(
						child: ListView(
							padding: EdgeInsets.all(compact ? 12 : 20),
							children: [
								_StatsRow(
									total: _totalMaquinas,
									activos: _activas,
									desactivados: _desactivadas,
									sectores: _sectoresCount,
								),
								SizedBox(height: compact ? 12 : 20),
								_DetailPanel(
									selected: _selected,
									equipoDetalle: _equipoDetalle,
									plantaNombre: _plantaNombre ?? '',
									empresaNombre: _empresaNombre,
									sucursalId: _sucursalId,
									emptyTree: _ubicacionesTree.isEmpty,
									canEdit: _canEditUbicaciones,
									onCreateFirstUbicacion: _canEditUbicaciones
											? () => _createUbicacion()
											: null,
									onEquipoUpdated: _onEquipoUpdated,
									onEditUbicacion: _canModificarUbicaciones ? _editUbicacion : null,
									onDeleteUbicacion: _canBorrarUbicaciones ? _deleteUbicacion : null,
									onMoverUbicacion: _canMoverUbicaciones ? _moverUbicacion : null,
									onEditEquipo: _canModificarEquipos ? (_) => _editEquipo() : null,
									onMoverEquipo: _canMoverEquipos ? (_) => _moverEquipo() : null,
								),
							],
						),
					),
				],
			),
		);
	}
}

class _StatCard extends StatelessWidget {
	const _StatCard({
		required this.label,
		required this.value,
		required this.color,
		this.hint,
	});

	final String label;
	final String value;
	final Color color;
	final String? hint;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(
					color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
				),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(label, style: Theme.of(context).textTheme.bodySmall),
					if (hint != null) ...[
						const SizedBox(height: 2),
						Text(
							hint!,
							style: TextStyle(
								fontSize: 11,
								color: Theme.of(context).colorScheme.onSurfaceVariant,
							),
						),
					],
					const SizedBox(height: 8),
					Text(
						value,
						style: Theme.of(context).textTheme.headlineSmall?.copyWith(
									color: color,
									fontWeight: FontWeight.w700,
								),
					),
				],
			),
		);
	}
}

class _StatsRow extends StatelessWidget {
	const _StatsRow({
		required this.total,
		required this.activos,
		required this.desactivados,
		required this.sectores,
	});

	final int total;
	final int activos;
	final int desactivados;
	final int sectores;

	@override
	Widget build(BuildContext context) {
		return LayoutBuilder(
			builder: (context, constraints) {
				final cards = [
					_StatCard(
						label: 'Máquinas en planta',
						value: '$total',
						hint: 'Total registradas',
						color: AppColors.brandYellow,
					),
					_StatCard(
						label: 'Operativas',
						value: '$activos',
						hint: 'Disponibles para OT',
						color: AppColors.success,
					),
					_StatCard(
						label: 'Fuera de servicio',
						value: '$desactivados',
						hint: 'No programar mantenimiento',
						color: AppColors.warning,
					),
					_StatCard(
						label: 'Sectores',
						value: '$sectores',
						hint: 'Ubicaciones del mapa',
						color: AppColors.secondary,
					),
				];

				if (constraints.maxWidth < 700) {
					return Wrap(
						spacing: 12,
						runSpacing: 12,
						children: cards
								.map((card) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: card))
								.toList(),
					);
				}

				return Row(
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
			},
		);
	}
}

class _ExplorerTile extends StatefulWidget {
	const _ExplorerTile({
		required this.node,
		required this.selectedId,
		required this.depth,
		required this.expandedIds,
		required this.onToggleExpand,
		required this.onSelect,
		required this.onDrop,
		required this.canDragEquipo,
		required this.canDragUbicacion,
		required this.isUbicacionHoja,
	});

	final _TreeNode node;
	final String? selectedId;
	final int depth;
	final Set<String> expandedIds;
	final void Function(String id) onToggleExpand;
	final void Function(_TreeNode node) onSelect;
	final Future<void> Function(PlantaDragPayload payload, _TreeNode target) onDrop;
	final bool canDragEquipo;
	final bool canDragUbicacion;
	final bool Function(_TreeNode node) isUbicacionHoja;

	@override
	State<_ExplorerTile> createState() => _ExplorerTileState();
}

class _ExplorerTileState extends State<_ExplorerTile> {
	bool _isDragOver = false;

	_TreeNode get node => widget.node;

	IconData get _icon {
		switch (node.kind) {
			case _NodeKind.empresa:
				return Icons.apartment_rounded;
			case _NodeKind.planta:
				return Icons.factory_rounded;
			case _NodeKind.ubicacion:
				return Icons.folder_rounded;
			case _NodeKind.maquina:
				return Icons.precision_manufacturing_rounded;
		}
	}

	PlantaDragPayload? _dragPayloadForNode() {
		if (node.kind == _NodeKind.maquina && widget.canDragEquipo) {
			return PlantaDragPayload(
				kind: PlantaDragKind.equipo,
				id: node.id.replaceFirst('maquina:', ''),
				label: node.label,
			);
		}
		if (node.kind == _NodeKind.ubicacion && widget.canDragUbicacion) {
			return PlantaDragPayload(
				kind: PlantaDragKind.ubicacion,
				id: node.id.replaceFirst('ubicacion:', ''),
				label: node.label,
			);
		}
		return null;
	}

	bool _acceptsDrop(PlantaDragPayload? payload) {
		if (payload == null) return false;

		if (payload.kind == PlantaDragKind.equipo) {
			return node.kind == _NodeKind.ubicacion && widget.isUbicacionHoja(node);
		}

		if (payload.kind == PlantaDragKind.ubicacion) {
			if (node.kind == _NodeKind.planta) return true;
			if (node.kind == _NodeKind.ubicacion) {
				return payload.id != node.id.replaceFirst('ubicacion:', '');
			}
		}

		return false;
	}

	bool get _isDropTarget =>
			node.kind == _NodeKind.planta ||
			node.kind == _NodeKind.ubicacion;

	Widget _buildTileContent(bool selected, bool isDark) {
		final scheme = Theme.of(context).colorScheme;
		final dragOver = _isDragOver;
		final hasChildren = node.children.isNotEmpty;
		final isExpanded = widget.expandedIds.contains(node.id);

		return Material(
			color: dragOver
					? AppColors.explorerSelected.withValues(alpha: 0.85)
					: selected
							? (isDark
									? AppColors.explorerSelected
									: AppColors.primary.withValues(alpha: 0.12))
							: Colors.transparent,
			borderRadius: BorderRadius.circular(10),
			child: InkWell(
				borderRadius: BorderRadius.circular(10),
				onTap: () => widget.onSelect(node),
				child: Padding(
					padding: EdgeInsets.fromLTRB(8.0 + (widget.depth.clamp(0, 8) * 12.0), 10, 8, 10),
					child: Row(
						children: [
							if (hasChildren)
								InkWell(
									borderRadius: BorderRadius.circular(6),
									onTap: () => widget.onToggleExpand(node.id),
									child: Container(
										width: 26,
										height: 26,
										alignment: Alignment.center,
										decoration: BoxDecoration(
											color: AppColors.brandPurple.withValues(alpha: isDark ? 0.35 : 0.12),
											borderRadius: BorderRadius.circular(6),
										),
										child: Icon(
											isExpanded
													? Icons.expand_more_rounded
													: Icons.chevron_right_rounded,
											size: 20,
											color: AppColors.brandPurple,
										),
									),
								)
							else
								const SizedBox(width: 26),
							const SizedBox(width: 8),
							Icon(_icon, size: 18, color: scheme.onSurfaceVariant),
							const SizedBox(width: 8),
							Container(
								width: 8,
								height: 8,
								decoration: BoxDecoration(
									shape: BoxShape.circle,
									color: node.activo ? AppColors.success : AppColors.warning,
								),
							),
							const SizedBox(width: 8),
							Expanded(
								child: Text(
									node.label,
									maxLines: 1,
									overflow: TextOverflow.ellipsis,
									style: TextStyle(
										fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
										fontSize: 13,
									),
								),
							),
							if (hasChildren)
								Text(
									'${node.children.length}',
									style: TextStyle(
										fontSize: 11,
										fontWeight: FontWeight.w700,
										color: scheme.onSurface.withValues(alpha: 0.4),
									),
								),
						],
					),
				),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		final selected = widget.selectedId == node.id;
		final payload = _dragPayloadForNode();
		final isDark = Theme.of(context).brightness == Brightness.dark;

		Widget rowContent = _buildTileContent(selected, isDark);

		if (payload != null) {
			rowContent = LongPressDraggable<PlantaDragPayload>(
				data: payload,
				feedback: Material(
					elevation: 4,
					borderRadius: BorderRadius.circular(8),
					color: isDark ? AppColors.cardElevated : null,
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
						child: Text(payload.label, style: const TextStyle(fontSize: 13)),
					),
				),
				childWhenDragging: Opacity(opacity: 0.35, child: rowContent),
				child: rowContent,
			);
		}

		Widget row = rowContent;

		if (_isDropTarget) {
			final inner = rowContent;
			row = DragTarget<PlantaDragPayload>(
				onWillAcceptWithDetails: (details) => _acceptsDrop(details.data),
				onLeave: (_) {
					if (_isDragOver) setState(() => _isDragOver = false);
				},
				onMove: (_) {
					if (!_isDragOver) setState(() => _isDragOver = true);
				},
				onAcceptWithDetails: (details) async {
					setState(() => _isDragOver = false);
					await widget.onDrop(details.data, node);
				},
				builder: (context, candidate, rejected) => inner,
			);
		}

		return Column(
			children: [
				row,
				if (node.children.isNotEmpty && widget.expandedIds.contains(node.id))
					...node.children.map(
						(child) => _ExplorerTile(
							node: child,
							selectedId: widget.selectedId,
							depth: widget.depth + 1,
							expandedIds: widget.expandedIds,
							onToggleExpand: widget.onToggleExpand,
							onSelect: widget.onSelect,
							onDrop: widget.onDrop,
							canDragEquipo: widget.canDragEquipo,
							canDragUbicacion: widget.canDragUbicacion,
							isUbicacionHoja: widget.isUbicacionHoja,
						),
					),
			],
		);
	}
}

class _DetailPanel extends StatelessWidget {
	const _DetailPanel({
		required this.selected,
		required this.equipoDetalle,
		required this.plantaNombre,
		required this.empresaNombre,
		this.sucursalId,
		required this.emptyTree,
		required this.canEdit,
		required this.onCreateFirstUbicacion,
		this.onEquipoUpdated,
		this.onEditUbicacion,
		this.onDeleteUbicacion,
		this.onMoverUbicacion,
		this.onEditEquipo,
		this.onMoverEquipo,
	});

	final _TreeNode? selected;
	final Map<String, dynamic>? equipoDetalle;
	final String plantaNombre;
	final String empresaNombre;
	final String? sucursalId;
	final bool emptyTree;
	final bool canEdit;
	final VoidCallback? onCreateFirstUbicacion;
	final Future<void> Function()? onEquipoUpdated;
	final Future<void> Function(_TreeNode node)? onEditUbicacion;
	final Future<void> Function(_TreeNode node)? onDeleteUbicacion;
	final Future<void> Function(_TreeNode node)? onMoverUbicacion;
	final Future<void> Function(_TreeNode node)? onEditEquipo;
	final Future<void> Function(_TreeNode node)? onMoverEquipo;

	@override
	Widget build(BuildContext context) {
		final node = selected;
		if (node == null) {
			return const SizedBox.shrink();
		}

		final breadcrumb = switch (node.kind) {
			_NodeKind.empresa => empresaNombre,
			_NodeKind.planta => '$empresaNombre › $plantaNombre',
			_NodeKind.ubicacion => '$empresaNombre › $plantaNombre › ${node.label}',
			_NodeKind.maquina => '$empresaNombre › $plantaNombre › ${node.label}',
		};

		return Container(
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surface,
				borderRadius: BorderRadius.circular(20),
				border: Border.all(
					color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
				),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						breadcrumb,
						style: Theme.of(context).textTheme.bodySmall?.copyWith(
									color: Theme.of(context).colorScheme.onSurfaceVariant,
								),
					),
					const SizedBox(height: 8),
					Row(
						children: [
							Expanded(
								child: Text(
									node.label,
									style: Theme.of(context).textTheme.headlineSmall?.copyWith(
												fontWeight: FontWeight.w700,
											),
								),
							),
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
								decoration: BoxDecoration(
									color: (node.activo ? AppColors.success : AppColors.warning)
											.withValues(alpha: 0.12),
									borderRadius: BorderRadius.circular(999),
								),
								child: Text(
									node.activo ? 'Activo' : 'Desactivado',
									style: TextStyle(
										color: node.activo ? AppColors.success : AppColors.warning,
										fontWeight: FontWeight.w600,
										fontSize: 12,
									),
								),
							),
							if (node.kind == _NodeKind.ubicacion &&
									(onEditUbicacion != null ||
											onDeleteUbicacion != null ||
											onMoverUbicacion != null))
								PopupMenuButton<String>(
									onSelected: (action) async {
										switch (action) {
											case 'edit':
												await onEditUbicacion?.call(node);
											case 'move':
												await onMoverUbicacion?.call(node);
											case 'delete':
												await onDeleteUbicacion?.call(node);
										}
									},
									itemBuilder: (context) => [
										if (onEditUbicacion != null)
											const PopupMenuItem(value: 'edit', child: Text('Editar')),
										if (onMoverUbicacion != null)
											const PopupMenuItem(value: 'move', child: Text('Mover')),
										if (onDeleteUbicacion != null)
											const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
									],
								),
							if (node.kind == _NodeKind.maquina &&
									(onEditEquipo != null || onMoverEquipo != null))
								PopupMenuButton<String>(
									onSelected: (action) async {
										switch (action) {
											case 'edit':
												await onEditEquipo?.call(node);
											case 'move':
												await onMoverEquipo?.call(node);
										}
									},
									itemBuilder: (context) => [
										if (onEditEquipo != null)
											const PopupMenuItem(value: 'edit', child: Text('Editar')),
										if (onMoverEquipo != null)
											const PopupMenuItem(value: 'move', child: Text('Mover')),
									],
								),
						],
					),
					const SizedBox(height: 16),
					if (node.kind == _NodeKind.planta && emptyTree)
						_EmptyPlantState(
							canEdit: canEdit,
							onCreate: onCreateFirstUbicacion,
						)
					else if (node.kind == _NodeKind.maquina)
						PlantaEquipoFicha(
							detalle: equipoDetalle ?? node.raw ?? {},
							sucursalId: sucursalId,
							onUpdated: onEquipoUpdated,
						)
					else if (node.kind == _NodeKind.ubicacion) ...[
						_UbicacionInfo(node: node),
						const SizedBox(height: 16),
						_AlcanceProcedimientosSection(
							ubicacionId: node.raw?['id'] as String?,
						),
					]
					else if (node.kind == _NodeKind.planta && !emptyTree)
						_AlcanceProcedimientosSection(sucursalId: sucursalId)
					else if (node.kind == _NodeKind.planta && emptyTree)
						const SizedBox.shrink()
					else
						Text(
							'SIKA es la empresa. La planta del usuario logueado aparece debajo.',
							style: Theme.of(context).textTheme.bodyMedium,
						),
				],
			),
		);
	}
}

class _EmptyPlantState extends StatelessWidget {
	const _EmptyPlantState({
		required this.canEdit,
		required this.onCreate,
	});

	final bool canEdit;
	final VoidCallback? onCreate;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(24),
			decoration: BoxDecoration(
				color: AppColors.primary.withValues(alpha: 0.05),
				borderRadius: BorderRadius.circular(16),
			),
			child: Column(
				children: [
					const Icon(Icons.account_tree_outlined, size: 40, color: AppColors.primary),
					const SizedBox(height: 12),
					Text(
						'Esta planta todavía no tiene ubicaciones',
						style: Theme.of(context).textTheme.titleMedium?.copyWith(
									fontWeight: FontWeight.w600,
								),
					),
					const SizedBox(height: 8),
					const Text(
						'Creá la primera ubicación (ej: SILOS EXTERNOS) y después sectores y máquinas.',
						textAlign: TextAlign.center,
					),
					if (canEdit && onCreate != null) ...[
						const SizedBox(height: 16),
						FilledButton.icon(
							onPressed: onCreate,
							icon: const Icon(Icons.add),
							label: const Text('Crear primera ubicación'),
						),
					],
				],
			),
		);
	}
}

class _UbicacionInfo extends StatelessWidget {
	const _UbicacionInfo({required this.node});

	final _TreeNode node;

	@override
	Widget build(BuildContext context) {
		final sectores = node.children.where((c) => c.kind == _NodeKind.ubicacion).length;
		final maquinas = node.children.where((c) => c.kind == _NodeKind.maquina).length;

		return Wrap(
			spacing: 12,
			runSpacing: 12,
			children: [
				_InfoChip(label: 'Tipo', value: sectores > 0 ? 'Ubicación' : 'Sector / hoja'),
				_InfoChip(label: 'Sectores hijos', value: '$sectores'),
				_InfoChip(label: 'Máquinas', value: '$maquinas'),
			],
		);
	}
}

class _AlcanceProcedimientosSection extends ConsumerStatefulWidget {
	const _AlcanceProcedimientosSection({this.sucursalId, this.ubicacionId});

	final String? sucursalId;
	final String? ubicacionId;

	@override
	ConsumerState<_AlcanceProcedimientosSection> createState() =>
			_AlcanceProcedimientosSectionState();
}

class _AlcanceProcedimientosSectionState extends ConsumerState<_AlcanceProcedimientosSection> {
	List<Map<String, dynamic>> _items = [];
	bool _loading = true;
	String? _error;

	@override
	void initState() {
		super.initState();
		_load();
	}

	@override
	void didUpdateWidget(covariant _AlcanceProcedimientosSection oldWidget) {
		super.didUpdateWidget(oldWidget);
		if (oldWidget.sucursalId != widget.sucursalId ||
				oldWidget.ubicacionId != widget.ubicacionId) {
			_load();
		}
	}

	Future<void> _load() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final q = widget.ubicacionId != null
					? 'ubicacionId=${widget.ubicacionId}'
					: 'sucursalId=${widget.sucursalId}';
			final data = await ref.read(apiClientProvider).getList(
				'ubicaciones/alcance/procedimientos?$q',
			);
			if (mounted) setState(() => _items = data.cast<Map<String, dynamic>>());
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final alcanceLabel = widget.ubicacionId != null
				? 'este sector'
				: 'toda la planta';

		return PlantaSectionCard(
			title: 'Procedimientos de mantenimiento',
			subtitle:
					'Solo los asociados a $alcanceLabel (no el listado general de la empresa).',
			child: _loading
					? const Center(child: Padding(
							padding: EdgeInsets.all(16),
							child: CircularProgressIndicator(strokeWidth: 2),
						))
					: _error != null
							? PlantaEmptyState(
									icon: Icons.error_outline_rounded,
									title: 'No pudimos cargar los procedimientos',
									message: _error,
									action: TextButton(
										onPressed: _load,
										child: const Text('Reintentar'),
									),
								)
							: _items.isEmpty
									? const PlantaEmptyState(
											icon: Icons.description_outlined,
											title: 'Sin procedimientos en este alcance',
											message:
													'Cuando asocies un procedimiento a esta planta, sector o máquina, aparecerá acá.',
										)
									: Column(
											children: _items.map((item) {
												final proc = item['procedimiento'] as Map<String, dynamic>?;
												if (proc == null) return const SizedBox.shrink();
												return PlantaProcTile(
													codigo: proc['codigo'],
													nombre: proc['nombre'] as String? ?? '',
													tipo: proc['tipo'] as String?,
													subtitle: PlantaUi.periodicidadCorta(proc),
												);
											}).toList(),
										),
		);
	}
}

class _InfoChip extends StatelessWidget {
	const _InfoChip({required this.label, required this.value});

	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
				borderRadius: BorderRadius.circular(12),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(label, style: Theme.of(context).textTheme.bodySmall),
					const SizedBox(height: 2),
					Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
				],
			),
		);
	}
}
