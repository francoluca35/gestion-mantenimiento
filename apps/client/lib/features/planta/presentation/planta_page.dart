import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';

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
	List<Map<String, dynamic>> _ubicacionesTree = [];
	List<Map<String, dynamic>> _equipos = [];
	List<Map<String, dynamic>> _tipos = [];
	_TreeNode? _selected;
	Map<String, dynamic>? _equipoDetalle;
	String _search = '';
	bool _loading = true;
	String? _error;

	AuthUser? get _user => ref.read(authControllerProvider).session?.usuario;

	bool get _canEditUbicaciones =>
			_user?.tieneDerecho('archivos.ubicaciones.agregar_nodo') == true;

	bool get _canEditEquipos =>
			_user?.tieneDerecho('archivos.equipos.agregar') == true;

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

			if (user?.sucursalId == null) {
				throw Exception(
					'Tu usuario no tiene planta asignada. Solo se muestra la planta del usuario logueado.',
				);
			}

			_sucursalId = user!.sucursalId;
			_plantaNombre = user.sucursalNombre ?? 'PLANTA';

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

	Future<void> _select(_TreeNode node) async {
		setState(() {
			_selected = node;
			_equipoDetalle = null;
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
		if (_tipos.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('No hay tipos de máquina configurados')),
			);
			return;
		}

		final nombreCtrl = TextEditingController();
		final codigoCtrl = TextEditingController();
		var tipoId = _tipos.first['id'] as String;

		final ok = await showDialog<bool>(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setDialogState) => AlertDialog(
					title: const Text('Nueva máquina'),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Align(
								alignment: Alignment.centerLeft,
								child: Text(
									'En: $ubicacionNombre',
									style: TextStyle(color: Colors.grey.shade600),
								),
							),
							const SizedBox(height: 12),
							TextField(
								controller: nombreCtrl,
								decoration: const InputDecoration(
									labelText: 'Nombre',
									hintText: 'Ej: SILO 103 ARENA FINA L-24',
								),
							),
							const SizedBox(height: 8),
							TextField(
								controller: codigoCtrl,
								decoration: const InputDecoration(
									labelText: 'Código',
									hintText: 'Ej: SILO-103',
								),
							),
							const SizedBox(height: 8),
							DropdownButtonFormField<String>(
								value: tipoId,
								items: _tipos
										.map(
											(tipo) => DropdownMenuItem(
												value: tipo['id'] as String,
												child: Text(tipo['nombre'] as String),
											),
										)
										.toList(),
								onChanged: (value) {
									if (value != null) setDialogState(() => tipoId = value);
								},
								decoration: const InputDecoration(labelText: 'Tipo'),
							),
						],
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.pop(context, false),
							child: const Text('Cancelar'),
						),
						FilledButton(
							onPressed: () => Navigator.pop(context, true),
							child: const Text('Crear'),
						),
					],
				),
			),
		);

		if (ok != true) return;

		try {
			await ref.read(apiClientProvider).postJson('equipos', {
				'sucursalId': _sucursalId,
				'ubicacionId': ubicacionId,
				'tipoEquipoId': tipoId,
				'nombre': nombreCtrl.text.trim().toUpperCase(),
				'codigo': codigoCtrl.text.trim().toUpperCase(),
			});
			await _reload();
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
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
		final explorerBg = isDark ? const Color(0xFF111827) : Colors.white;
		final pageBg = isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9);

		if (_loading) {
			return const Scaffold(body: Center(child: CircularProgressIndicator()));
		}

		if (_error != null) {
			return Scaffold(
				appBar: AppBar(title: const Text('Gestión de equipos')),
				body: Center(child: Text(_error!)),
			);
		}

		final root = _buildExplorerTree();
		final visible = _filterTree(root);

		return Scaffold(
			backgroundColor: pageBg,
			body: Row(
				children: [
					SizedBox(
						width: 320,
						child: Material(
							color: explorerBg,
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									Padding(
										padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
										child: Text(
											'Explorador de equipos',
											style: Theme.of(context).textTheme.titleMedium?.copyWith(
														fontWeight: FontWeight.w700,
													),
										),
									),
									Padding(
										padding: const EdgeInsets.symmetric(horizontal: 16),
										child: TextField(
											onChanged: (value) => setState(() => _search = value),
											decoration: InputDecoration(
												hintText: 'Buscar ubicación, sector o máquina...',
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
																		onSelect: _select,
																	),
																)
																.toList(),
													),
									),
								],
							),
						),
					),
					VerticalDivider(
						width: 1,
						color: scheme.outlineVariant.withValues(alpha: 0.4),
					),
					Expanded(
						child: Column(
							children: [
								_TopBar(
									plantaNombre: _plantaNombre ?? '',
									onRefresh: _bootstrap,
									showAdd: _showAddButton,
									onAdd: _onAddPressed,
								),
								Expanded(
									child: ListView(
										padding: const EdgeInsets.all(20),
										children: [
											_StatsRow(
												total: _totalMaquinas,
												activos: _activas,
												desactivados: _desactivadas,
												sectores: _sectoresCount,
											),
											const SizedBox(height: 20),
											_DetailPanel(
												selected: _selected,
												equipoDetalle: _equipoDetalle,
												plantaNombre: _plantaNombre ?? '',
												empresaNombre: _empresaNombre,
												emptyTree: _ubicacionesTree.isEmpty,
												canEdit: _canEditUbicaciones,
												onCreateFirstUbicacion: _canEditUbicaciones
														? () => _createUbicacion()
														: null,
											),
										],
									),
								),
							],
						),
					),
				],
			),
		);
	}
}

class _TopBar extends StatelessWidget {
	const _TopBar({
		required this.plantaNombre,
		required this.onRefresh,
		required this.showAdd,
		required this.onAdd,
	});

	final String plantaNombre;
	final VoidCallback onRefresh;
	final bool showAdd;
	final VoidCallback onAdd;

	@override
	Widget build(BuildContext context) {
		return Container(
			height: 64,
			padding: const EdgeInsets.symmetric(horizontal: 20),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surface,
				border: Border(
					bottom: BorderSide(
						color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
					),
				),
			),
			child: Row(
				children: [
					Text(
						'Gestión de equipos',
						style: Theme.of(context).textTheme.titleLarge?.copyWith(
									fontWeight: FontWeight.w700,
								),
					),
					const SizedBox(width: 12),
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
						decoration: BoxDecoration(
							color: AppColors.primary.withValues(alpha: 0.1),
							borderRadius: BorderRadius.circular(999),
						),
						child: Text(
							plantaNombre,
							style: const TextStyle(
								color: AppColors.primary,
								fontWeight: FontWeight.w600,
								fontSize: 12,
							),
						),
					),
					const Spacer(),
					IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
					if (showAdd) ...[
						const SizedBox(width: 8),
						FilledButton.icon(
							onPressed: onAdd,
							icon: const Icon(Icons.add),
							label: const Text('Agregar'),
						),
					],
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
					_StatCard(label: 'Máquinas totales', value: '$total', color: AppColors.primary),
					_StatCard(label: 'Activas', value: '$activos', color: AppColors.success),
					_StatCard(label: 'Desactivadas', value: '$desactivados', color: AppColors.warning),
					_StatCard(label: 'Ubicaciones / sectores', value: '$sectores', color: AppColors.secondary),
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

class _StatCard extends StatelessWidget {
	const _StatCard({
		required this.label,
		required this.value,
		required this.color,
	});

	final String label;
	final String value;
	final Color color;

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

class _ExplorerTile extends StatelessWidget {
	const _ExplorerTile({
		required this.node,
		required this.selectedId,
		required this.depth,
		required this.onSelect,
	});

	final _TreeNode node;
	final String? selectedId;
	final int depth;
	final void Function(_TreeNode node) onSelect;

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

	@override
	Widget build(BuildContext context) {
		final selected = selectedId == node.id;
		final scheme = Theme.of(context).colorScheme;

		return Column(
			children: [
				Material(
					color: selected
							? AppColors.primary.withValues(alpha: 0.12)
							: Colors.transparent,
					borderRadius: BorderRadius.circular(10),
					child: InkWell(
						borderRadius: BorderRadius.circular(10),
						onTap: () => onSelect(node),
						child: Padding(
							padding: EdgeInsets.fromLTRB(8.0 + depth * 14, 10, 8, 10),
							child: Row(
								children: [
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
											style: TextStyle(
												fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
												fontSize: 13,
											),
										),
									),
								],
							),
						),
					),
				),
				...node.children.map(
					(child) => _ExplorerTile(
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

class _DetailPanel extends StatelessWidget {
	const _DetailPanel({
		required this.selected,
		required this.equipoDetalle,
		required this.plantaNombre,
		required this.empresaNombre,
		required this.emptyTree,
		required this.canEdit,
		required this.onCreateFirstUbicacion,
	});

	final _TreeNode? selected;
	final Map<String, dynamic>? equipoDetalle;
	final String plantaNombre;
	final String empresaNombre;
	final bool emptyTree;
	final bool canEdit;
	final VoidCallback? onCreateFirstUbicacion;

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
						],
					),
					const SizedBox(height: 16),
					if (node.kind == _NodeKind.planta && emptyTree)
						_EmptyPlantState(
							canEdit: canEdit,
							onCreate: onCreateFirstUbicacion,
						)
					else if (node.kind == _NodeKind.maquina)
						_MaquinaInfo(detalle: equipoDetalle ?? node.raw ?? {})
					else if (node.kind == _NodeKind.ubicacion)
						_UbicacionInfo(node: node)
					else if (node.kind == _NodeKind.planta)
						Text(
							'Seleccioná una ubicación, sector o máquina en el explorador. '
							'Usá Agregar para crear ubicaciones bajo esta planta.',
							style: Theme.of(context).textTheme.bodyMedium,
						)
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

class _MaquinaInfo extends StatelessWidget {
	const _MaquinaInfo({required this.detalle});

	final Map<String, dynamic> detalle;

	@override
	Widget build(BuildContext context) {
		final tipo = detalle['tipoEquipo'] as Map<String, dynamic>?;
		final ubicacion = detalle['ubicacion'] as Map<String, dynamic>?;
		final campos = detalle['detalle'] as Map<String, dynamic>? ?? {};

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Wrap(
					spacing: 12,
					runSpacing: 12,
					children: [
						_InfoChip(label: 'Código', value: '${detalle['codigo'] ?? '-'}'),
						_InfoChip(label: 'Tipo', value: '${tipo?['nombre'] ?? '-'}'),
						_InfoChip(label: 'Ubicación', value: '${ubicacion?['nombre'] ?? '-'}'),
						_InfoChip(
							label: 'Estado',
							value: (detalle['fueraDeServicio'] as bool? ?? false)
									? 'Fuera de servicio'
									: 'Operativo',
						),
					],
				),
				if (campos.isNotEmpty) ...[
					const SizedBox(height: 16),
					Text('Detalle', style: Theme.of(context).textTheme.titleSmall),
					const SizedBox(height: 8),
					...campos.entries.map(
						(entry) => ListTile(
							dense: true,
							contentPadding: EdgeInsets.zero,
							title: Text(entry.key),
							subtitle: Text('${entry.value}'),
						),
					),
				],
			],
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
