import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/sika_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

enum PlantaMapNodeKind { empresa, planta, ubicacion, equipo }

enum PlantaMapScope { planta, ubicacion, equipo }

class PlantaMapSelection {
	const PlantaMapSelection({
		required this.scope,
		this.equipoId,
		this.ubicacionId,
		this.sucursalId,
		this.label = '',
	});

	final PlantaMapScope scope;
	final String? equipoId;
	final String? ubicacionId;
	final String? sucursalId;
	final String label;
}

class _MapNode {
	const _MapNode({
		required this.id,
		required this.label,
		required this.kind,
		required this.activo,
		this.equipoUuid,
		this.ubicacionUuid,
		this.sucursalUuid,
		this.children = const [],
	});

	final String id;
	final String label;
	final PlantaMapNodeKind kind;
	final bool activo;
	final String? equipoUuid;
	final String? ubicacionUuid;
	final String? sucursalUuid;
	final List<_MapNode> children;
}

/// Mapa embebido de planta — árbol SIKA → planta → sectores → equipos.
class PlantaMapPanel extends ConsumerStatefulWidget {
	const PlantaMapPanel({
		super.key,
		this.selection,
		this.highlightEquipoId,
		this.onSelectionChanged,
		this.onSearch,
		this.showSearchButton = true,
		this.compact = false,
		this.rootAtPlanta = true,
	});

	final PlantaMapSelection? selection;
	final String? highlightEquipoId;
	final ValueChanged<PlantaMapSelection>? onSelectionChanged;
	final VoidCallback? onSearch;
	final bool showSearchButton;
	final bool compact;
	/// Si es true, el árbol arranca en la planta del usuario (sin nodo empresa).
	final bool rootAtPlanta;

	@override
	ConsumerState<PlantaMapPanel> createState() => _PlantaMapPanelState();
}

class _PlantaMapPanelState extends ConsumerState<PlantaMapPanel> {
	static const _empresaNombre = 'SIKA';

	String? _sucursalId;
	String? _plantaNombre;
	List<Map<String, dynamic>> _ubicacionesTree = [];
	List<Map<String, dynamic>> _equipos = [];
	_MapNode? _selectedNode;
	String _search = '';
	bool _loading = true;
	String? _error;
	final Set<String> _expandedIds = {};

	void _initExpanded(_MapNode root) {
		_expandedIds.clear();
		void walk(_MapNode node) {
			if (node.children.isNotEmpty) {
				_expandedIds.add(node.id);
				for (final child in node.children) {
					walk(child);
				}
			}
		}

		walk(root);
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

	void _expandAllVisible(_MapNode node) {
		if (node.children.isNotEmpty) {
			_expandedIds.add(node.id);
			for (final child in node.children) {
				_expandAllVisible(child);
			}
		}
	}

	void _onSearchChanged(String value) {
		setState(() {
			_search = value;
			if (value.trim().isNotEmpty) {
				for (final node in _filterTree(_displayRoot())) {
					_expandAllVisible(node);
				}
			}
		});
	}

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
	}

	@override
	void didUpdateWidget(covariant PlantaMapPanel oldWidget) {
		super.didUpdateWidget(oldWidget);
		if (oldWidget.highlightEquipoId != widget.highlightEquipoId &&
				widget.highlightEquipoId != null) {
			_syncHighlight(widget.highlightEquipoId!);
		}
		if (oldWidget.selection != widget.selection && widget.selection != null) {
			_syncExternalSelection(widget.selection!);
		}
	}

	_MapNode _plantaNode() {
		return _MapNode(
			id: 'planta:$_sucursalId',
			label: _plantaNombre ?? 'PLANTA',
			kind: PlantaMapNodeKind.planta,
			activo: true,
			sucursalUuid: _sucursalId,
			children: _ubicacionesTree.map(_mapUbicacion).toList(),
		);
	}

	_MapNode _displayRoot() {
		if (widget.rootAtPlanta) return _plantaNode();
		return _buildTree();
	}

	_MapNode? _findNode(_MapNode root, PlantaMapSelection selection) {
		_MapNode? match;
		void walk(_MapNode node) {
			final sel = _toSelection(node);
			if (sel != null &&
					sel.scope == selection.scope &&
					sel.equipoId == selection.equipoId &&
					sel.ubicacionId == selection.ubicacionId &&
					sel.sucursalId == selection.sucursalId) {
				match = node;
				return;
			}
			for (final child in node.children) {
				if (match != null) return;
				walk(child);
			}
		}

		walk(root);
		return match;
	}

	void _syncExternalSelection(PlantaMapSelection selection) {
		final root = _displayRoot();
		final found = _findNode(root, selection);
		if (found != null && mounted) {
			setState(() => _selectedNode = found);
		}
	}

	void _applyDefaultSelection() {
		final plant = _plantaNode();
		final external = widget.selection;
		if (external != null) {
			_selectedNode = _findNode(plant, external) ?? plant;
			return;
		}
		_selectedNode ??= plant;
		final selection = _toSelection(_selectedNode!);
		if (selection != null) {
			WidgetsBinding.instance.addPostFrameCallback((_) {
				if (mounted) widget.onSelectionChanged?.call(selection);
			});
		}
	}

	Future<void> _bootstrap() async {
		setState(() {
			_loading = true;
			_error = null;
		});

		try {
			final user = ref.read(authControllerProvider).session?.usuario;
			if (user?.sucursalId == null) {
				throw Exception('Sin planta asignada');
			}

			_sucursalId = user!.sucursalId;
			_plantaNombre = user.sucursalNombre ?? 'PLANTA';

			final api = ref.read(apiClientProvider);
			final query = '?sucursalId=$_sucursalId';
			final tree = await api.getList('ubicaciones/tree$query');
			final equipos = await api.getList('equipos$query');

			if (!mounted) return;
			setState(() {
				_ubicacionesTree = tree.cast<Map<String, dynamic>>();
				_equipos = equipos.cast<Map<String, dynamic>>();
			});
			_initExpanded(_displayRoot());
			_applyDefaultSelection();

			if (widget.highlightEquipoId != null) {
				_syncHighlight(widget.highlightEquipoId!);
			}
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	void _syncHighlight(String equipoId) {
		final root = _displayRoot();
		_MapNode? found;
		void walk(_MapNode node) {
			if (node.equipoUuid == equipoId) found = node;
			for (final child in node.children) {
				if (found != null) return;
				walk(child);
			}
		}

		walk(root);
		if (found != null && mounted) {
			setState(() => _selectedNode = found);
		}
	}

	_MapNode _buildTree() {
		return _MapNode(
			id: 'empresa',
			label: _empresaNombre,
			kind: PlantaMapNodeKind.empresa,
			activo: true,
			children: [_plantaNode()],
		);
	}

	_MapNode _mapUbicacion(Map<String, dynamic> node) {
		final id = node['id'] as String;
		final childrenUbic = (node['children'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>();
		final maquinas = _equipos
				.where((e) => e['ubicacionId'] == id)
				.map(
					(e) => _MapNode(
						id: 'equipo:${e['id']}',
						label: e['nombre'] as String,
						kind: PlantaMapNodeKind.equipo,
						activo: !(e['fueraDeServicio'] as bool? ?? false) &&
								(e['activo'] as bool? ?? true),
						equipoUuid: e['id'] as String,
						ubicacionUuid: id,
						sucursalUuid: _sucursalId,
					),
				)
				.toList();

		return _MapNode(
			id: 'ubicacion:$id',
			label: node['nombre'] as String,
			kind: PlantaMapNodeKind.ubicacion,
			activo: node['activa'] as bool? ?? true,
			ubicacionUuid: id,
			sucursalUuid: _sucursalId,
			children: [...childrenUbic.map(_mapUbicacion), ...maquinas],
		);
	}

	List<_MapNode> _filterTree(_MapNode node) {
		if (_search.trim().isEmpty) return [node];
		final query = _search.trim().toLowerCase();

		_MapNode? filter(_MapNode current) {
			final childMatches =
					current.children.map(filter).whereType<_MapNode>().toList();
			final selfMatch = current.label.toLowerCase().contains(query);
			if (selfMatch || childMatches.isNotEmpty) {
				return _MapNode(
					id: current.id,
					label: current.label,
					kind: current.kind,
					activo: current.activo,
					equipoUuid: current.equipoUuid,
					ubicacionUuid: current.ubicacionUuid,
					sucursalUuid: current.sucursalUuid,
					children: childMatches,
				);
			}
			return null;
		}

		final result = filter(node);
		return result == null ? [] : [result];
	}

	PlantaMapSelection? _toSelection(_MapNode node) {
		return switch (node.kind) {
			PlantaMapNodeKind.planta => PlantaMapSelection(
					scope: PlantaMapScope.planta,
					sucursalId: node.sucursalUuid,
					label: node.label,
				),
			PlantaMapNodeKind.ubicacion => PlantaMapSelection(
					scope: PlantaMapScope.ubicacion,
					ubicacionId: node.ubicacionUuid,
					sucursalId: node.sucursalUuid,
					label: node.label,
				),
			PlantaMapNodeKind.equipo => PlantaMapSelection(
					scope: PlantaMapScope.equipo,
					equipoId: node.equipoUuid,
					ubicacionId: node.ubicacionUuid,
					sucursalId: node.sucursalUuid,
					label: node.label,
				),
			_ => null,
		};
	}

	void _selectNode(_MapNode node) {
		if (node.kind == PlantaMapNodeKind.empresa) return;
		setState(() => _selectedNode = node);
		final selection = _toSelection(node);
		if (selection != null) {
			widget.onSelectionChanged?.call(selection);
		}
	}

	bool _isHighlighted(_MapNode node) {
		if (_selectedNode?.id == node.id) return true;
		if (widget.highlightEquipoId != null &&
				node.equipoUuid == widget.highlightEquipoId) {
			return true;
		}
		return false;
	}

	@override
	Widget build(BuildContext context) {
		final bg = widget.compact ? AppColors.black : AppColors.explorerPanel;

		if (_loading) {
			return const Center(child: CircularProgressIndicator(strokeWidth: 2));
		}

		if (_error != null) {
			return Center(
				child: Padding(
					padding: const EdgeInsets.all(16),
					child: Text(_error!, textAlign: TextAlign.center),
				),
			);
		}

		final root = _displayRoot();
		final visible = _filterTree(root);

		return Material(
			color: bg,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: EdgeInsets.fromLTRB(
							widget.compact ? 12 : 16,
							widget.compact ? 12 : 16,
							widget.compact ? 8 : 12,
							8,
						),
						child: Row(
							children: [
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												'Mapa de planta',
												style: Theme.of(context)
														.textTheme
														.titleSmall
														?.copyWith(
															fontWeight: FontWeight.w800,
															color: Colors.white,
														),
											),
											if (_selectedNode != null &&
													_selectedNode!.kind !=
															PlantaMapNodeKind.empresa)
												Text(
													_selectedNode!.label,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
													style: const TextStyle(
														fontSize: 12,
														color: AppColors.mutedText,
													),
												),
										],
									),
								),
								if (widget.showSearchButton && widget.onSearch != null)
									FilledButton.icon(
										onPressed: widget.onSearch,
										icon: const Icon(Icons.search_rounded, size: 18),
										label: const Text('Buscar'),
										style: FilledButton.styleFrom(
											backgroundColor: AppColors.brandYellow,
											foregroundColor: AppColors.ink,
											padding: const EdgeInsets.symmetric(
												horizontal: 12,
												vertical: 8,
											),
											visualDensity: VisualDensity.compact,
										),
									),
							],
						),
					),
					Padding(
						padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : 16),
						child: TextField(
							style: const TextStyle(color: Colors.white),
							onChanged: _onSearchChanged,
							decoration: SikaUi.searchDecoration(
								context: context,
								hint: 'Sector o equipo…',
							),
						),
					),
					const SizedBox(height: 8),
					Expanded(
						child: visible.isEmpty
								? const Center(child: Text('Sin resultados'))
								: ListView(
										padding: EdgeInsets.fromLTRB(
											widget.compact ? 6 : 8,
											0,
											widget.compact ? 6 : 8,
											12,
										),
										children: visible
												.map(
													(node) => _MapTreeTile(
														node: node,
														depth: 0,
														expandedIds: _expandedIds,
														isHighlighted: _isHighlighted,
														onSelect: _selectNode,
														onToggleExpand: _toggleExpand,
														rootAtPlanta: widget.rootAtPlanta,
													),
												)
												.toList(),
									),
					),
				],
			),
		);
	}
}

class _MapTreeTile extends StatelessWidget {
	const _MapTreeTile({
		required this.node,
		required this.depth,
		required this.expandedIds,
		required this.isHighlighted,
		required this.onSelect,
		required this.onToggleExpand,
		this.rootAtPlanta = true,
	});

	final _MapNode node;
	final int depth;
	final Set<String> expandedIds;
	final bool Function(_MapNode node) isHighlighted;
	final void Function(_MapNode node) onSelect;
	final void Function(String id) onToggleExpand;
	final bool rootAtPlanta;

	IconData get _icon => switch (node.kind) {
			PlantaMapNodeKind.empresa => Icons.apartment_rounded,
			PlantaMapNodeKind.planta => Icons.factory_rounded,
			PlantaMapNodeKind.ubicacion => Icons.folder_rounded,
			PlantaMapNodeKind.equipo => Icons.precision_manufacturing_rounded,
		};

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final highlighted = isHighlighted(node);
		final disabled = node.kind == PlantaMapNodeKind.equipo && !node.activo;
		final tapDisabled =
				node.kind == PlantaMapNodeKind.empresa || disabled;
		final hasChildren = node.children.isNotEmpty;
		final isExpanded = expandedIds.contains(node.id);
		final isPlantaRoot = node.kind == PlantaMapNodeKind.planta && rootAtPlanta;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Padding(
					padding: EdgeInsets.only(left: depth * 14.0, bottom: 2),
					child: Material(
						color: isPlantaRoot
								? const Color(0xFF3D3018)
								: highlighted
										? AppColors.primary.withValues(alpha: 0.14)
										: Colors.transparent,
						borderRadius: BorderRadius.circular(10),
						child: InkWell(
							borderRadius: BorderRadius.circular(10),
							onTap: tapDisabled ? null : () => onSelect(node),
							child: Padding(
								padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
								child: Row(
									children: [
										if (hasChildren)
											_InkMini(
												onTap: () => onToggleExpand(node.id),
												child: _ExpandToggle(expanded: isExpanded),
											)
										else
											const SizedBox(width: 22),
										const SizedBox(width: 6),
										Icon(
											_icon,
											size: 18,
											color: highlighted
													? AppColors.brandYellow
													: isPlantaRoot
															? AppColors.brandYellow
															: disabled
																	? scheme.onSurfaceVariant
																	: Colors.white.withValues(alpha: 0.9),
										),
										const SizedBox(width: 8),
										Expanded(
											child: Text(
												node.label,
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
												style: TextStyle(
													fontWeight: highlighted || isPlantaRoot
															? FontWeight.w700
															: FontWeight.w500,
													fontSize: 13,
													color: disabled
															? scheme.onSurfaceVariant
															: Colors.white,
												),
											),
										),
										if (highlighted)
											const Icon(
												Icons.my_location_rounded,
												size: 16,
												color: AppColors.brandYellow,
											),
									],
								),
							),
						),
					),
				),
				if (hasChildren && isExpanded)
					...node.children.map(
						(child) => _MapTreeTile(
							node: child,
							depth: depth + 1,
							expandedIds: expandedIds,
							isHighlighted: isHighlighted,
							onSelect: onSelect,
							onToggleExpand: onToggleExpand,
							rootAtPlanta: rootAtPlanta,
						),
					),
			],
		);
	}
}

class _ExpandToggle extends StatelessWidget {
	const _ExpandToggle({required this.expanded});

	final bool expanded;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: 22,
			height: 22,
			decoration: BoxDecoration(
				color: AppColors.brandYellow,
				borderRadius: BorderRadius.circular(5),
			),
			child: Icon(
				expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
				size: 16,
				color: AppColors.ink,
			),
		);
	}
}

class _InkMini extends StatelessWidget {
	const _InkMini({required this.onTap, required this.child});

	final VoidCallback onTap;
	final Widget child;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: Colors.transparent,
			child: InkWell(
				borderRadius: BorderRadius.circular(5),
				onTap: onTap,
				child: child,
			),
		);
	}
}
