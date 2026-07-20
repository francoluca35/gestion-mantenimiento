import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import 'panol_ui.dart';

class StockPage extends ConsumerStatefulWidget {
	const StockPage({super.key, this.embeddedInPanol = false});

	final bool embeddedInPanol;

	@override
	ConsumerState<StockPage> createState() => _StockPageState();
}

class _StockPageState extends ConsumerState<StockPage> {
	static final _dateFmt = DateFormat('dd/MM/yyyy');

	List<Map<String, dynamic>> _stock = [];
	List<Map<String, dynamic>> _pedidos = [];
	List<Map<String, dynamic>> _panoles = [];
	List<Map<String, dynamic>> _unidades = [];
	String? _panolId;
	Map<String, dynamic>? _selected;
	bool _loading = true;
	String? _error;
	String _q = '';

	AuthUser? get _user => ref.read(authControllerProvider).session?.usuario;

	bool get _canEdit =>
			_user?.tieneDerecho('stock.materiales_en_stock.modificar_valores_gestion') ==
					true ||
			_user?.esAdministrador == true;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
	}

	Future<void> _cargar() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final api = ref.read(apiClientProvider);
			final panoles = (await api.getList('panoles')).cast<Map<String, dynamic>>();
			final unidades =
					(await api.getList('materiales/unidades')).cast<Map<String, dynamic>>();
			final panolId = _panolId ??
					(panoles.isNotEmpty ? panoles.first['id'] as String? : null);
			final stockQuery = panolId != null ? 'stock?panolId=$panolId' : 'stock';
			final stock = (await api.getList(stockQuery)).cast<Map<String, dynamic>>();
			final pedidos = panolId != null
					? (await api.getList('pedidos-stock?panolId=$panolId'))
							.cast<Map<String, dynamic>>()
					: <Map<String, dynamic>>[];
			if (!mounted) return;
			setState(() {
				_panoles = panoles;
				_unidades = unidades;
				_panolId = panolId;
				_stock = stock;
				_pedidos = pedidos;
				if (_selected != null) {
					final id = _selected!['id'];
					_selected = stock.where((s) => s['id'] == id).firstOrNull;
				}
			});
		} catch (e) {
			if (mounted) setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	List<Map<String, dynamic>> get _filtrados {
		final q = _q.trim().toLowerCase();
		if (q.isEmpty) return _stock;
		return _stock.where((item) {
			final mat = item['material'] as Map<String, dynamic>? ?? {};
			final codigo = (mat['codigo'] as String? ?? '').toLowerCase();
			final nombre = (mat['nombre'] as String? ?? '').toLowerCase();
			final uso = (mat['uso'] as String? ?? '').toLowerCase();
			return codigo.contains(q) || nombre.contains(q) || uso.contains(q);
		}).toList();
	}

	bool _bajoStock(Map<String, dynamic> item) {
		if (item['bajoMinimo'] == true) return true;
		final disponible = (item['disponible'] as num?)?.toDouble() ??
				((item['cantidadActual'] as num?)?.toDouble() ?? 0) -
						((item['cantidadReservada'] as num?)?.toDouble() ?? 0);
		return disponible < 6;
	}

	num _disponible(Map<String, dynamic> item) =>
			(item['disponible'] as num?) ??
			((item['cantidadActual'] as num?) ?? 0) -
					((item['cantidadReservada'] as num?) ?? 0);

	Future<void> _anadir() async {
		if (!_canEdit || _panolId == null) return;
		final codigoCtrl = TextEditingController();
		final nombreCtrl = TextEditingController();
		final usoCtrl = TextEditingController(text: 'Mantenimiento');
		final cantCtrl = TextEditingController(text: '0');
		final minCtrl = TextEditingController(text: '5');
		String? unidadId = _unidades.isNotEmpty ? _unidades.first['id'] as String : null;

		final ok = await showDialog<bool>(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setDialog) => AlertDialog(
					title: const Text('Añadir material'),
					content: SizedBox(
						width: 420,
						child: SingleChildScrollView(
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									TextField(
										controller: codigoCtrl,
										decoration: const InputDecoration(
											labelText: 'Código',
											border: OutlineInputBorder(),
										),
									),
									const SizedBox(height: 12),
									TextField(
										controller: nombreCtrl,
										decoration: const InputDecoration(
											labelText: 'Nombre',
											border: OutlineInputBorder(),
										),
									),
									const SizedBox(height: 12),
									TextField(
										controller: usoCtrl,
										decoration: const InputDecoration(
											labelText: 'Uso',
											border: OutlineInputBorder(),
										),
									),
									const SizedBox(height: 12),
									DropdownButtonFormField<String>(
										value: unidadId,
										decoration: const InputDecoration(
											labelText: 'Unidad',
											border: OutlineInputBorder(),
										),
										items: [
											for (final u in _unidades)
												DropdownMenuItem(
													value: u['id'] as String,
													child: Text('${u['codigo']} — ${u['nombre']}'),
												),
										],
										onChanged: (v) => setDialog(() => unidadId = v),
									),
									const SizedBox(height: 12),
									TextField(
										controller: cantCtrl,
										keyboardType: TextInputType.number,
										decoration: const InputDecoration(
											labelText: 'Cantidad',
											border: OutlineInputBorder(),
										),
									),
									const SizedBox(height: 12),
									TextField(
										controller: minCtrl,
										keyboardType: TextInputType.number,
										decoration: const InputDecoration(
											labelText: 'Mínimo',
											border: OutlineInputBorder(),
										),
									),
								],
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
							child: const Text('Guardar'),
						),
					],
				),
			),
		);
		if (ok != true || unidadId == null) return;
		try {
			await ref.read(apiClientProvider).postJson('materiales', {
				'codigo': codigoCtrl.text.trim(),
				'nombre': nombreCtrl.text.trim(),
				'uso': usoCtrl.text.trim(),
				'unidadId': unidadId,
				'panolId': _panolId,
				'cantidadActual': double.tryParse(cantCtrl.text) ?? 0,
				'cantidadMinima': double.tryParse(minCtrl.text) ?? 0,
			});
			await _cargar();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		}
	}

	Future<void> _editar() async {
		final item = _selected;
		if (!_canEdit || item == null) {
			_toast('Seleccioná un ítem de la tabla');
			return;
		}
		final mat = item['material'] as Map<String, dynamic>? ?? {};
		final codigoCtrl = TextEditingController(text: mat['codigo'] as String? ?? '');
		final nombreCtrl = TextEditingController(text: mat['nombre'] as String? ?? '');
		final usoCtrl = TextEditingController(text: mat['uso'] as String? ?? 'Mantenimiento');
		final cantCtrl = TextEditingController(
			text: '${item['cantidadActual'] ?? item['disponible'] ?? 0}',
		);
		final minCtrl = TextEditingController(text: '${item['cantidadMinima'] ?? 0}');

		final ok = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Editar stock'),
				content: SizedBox(
					width: 420,
					child: SingleChildScrollView(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								TextField(
									controller: codigoCtrl,
									decoration: const InputDecoration(
										labelText: 'Código',
										border: OutlineInputBorder(),
									),
								),
								const SizedBox(height: 12),
								TextField(
									controller: nombreCtrl,
									decoration: const InputDecoration(
										labelText: 'Nombre',
										border: OutlineInputBorder(),
									),
								),
								const SizedBox(height: 12),
								TextField(
									controller: usoCtrl,
									decoration: const InputDecoration(
										labelText: 'Uso',
										border: OutlineInputBorder(),
									),
								),
								const SizedBox(height: 12),
								TextField(
									controller: cantCtrl,
									keyboardType: TextInputType.number,
									decoration: const InputDecoration(
										labelText: 'Cantidad',
										border: OutlineInputBorder(),
									),
								),
								const SizedBox(height: 12),
								TextField(
									controller: minCtrl,
									keyboardType: TextInputType.number,
									decoration: const InputDecoration(
										labelText: 'Mínimo',
										border: OutlineInputBorder(),
									),
								),
							],
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
						child: const Text('Guardar'),
					),
				],
			),
		);
		if (ok != true) return;
		try {
			final api = ref.read(apiClientProvider);
			await api.patchJson('materiales/${mat['id']}', {
				'codigo': codigoCtrl.text.trim(),
				'nombre': nombreCtrl.text.trim(),
				'uso': usoCtrl.text.trim(),
			});
			await api.patchJson('stock/${item['id']}', {
				'cantidadActual': double.tryParse(cantCtrl.text) ?? 0,
				'cantidadMinima': double.tryParse(minCtrl.text) ?? 0,
			});
			await _cargar();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		}
	}

	Future<void> _eliminar() async {
		final item = _selected;
		if (!_canEdit || item == null) {
			_toast('Seleccioná un ítem de la tabla');
			return;
		}
		final mat = item['material'] as Map<String, dynamic>? ?? {};
		final confirm = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Eliminar material'),
				content: Text('¿Desactivar ${mat['nombre']}?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						style: FilledButton.styleFrom(backgroundColor: AppColors.brandRed),
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Eliminar'),
					),
				],
			),
		);
		if (confirm != true) return;
		try {
			await ref.read(apiClientProvider).patchJson('materiales/${mat['id']}', {
				'activo': false,
			});
			_selected = null;
			await _cargar();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		}
	}

	Future<void> _utilizar() async {
		final item = _selected;
		if (!_canEdit || item == null || _panolId == null) {
			_toast('Seleccioná un ítem de la tabla');
			return;
		}
		final mat = item['material'] as Map<String, dynamic>? ?? {};
		final cantCtrl = TextEditingController(text: '1');
		final ok = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Utilizar stock'),
				content: TextField(
					controller: cantCtrl,
					keyboardType: TextInputType.number,
					decoration: InputDecoration(
						labelText: 'Cantidad a descontar (${mat['nombre']})',
						border: const OutlineInputBorder(),
					),
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Utilizar'),
					),
				],
			),
		);
		if (ok != true) return;
		try {
			await ref.read(apiClientProvider).postJson('stock/movimientos', {
				'panolId': _panolId,
				'materialId': mat['id'],
				'tipo': 'salida',
				'cantidad': double.tryParse(cantCtrl.text) ?? 1,
				'origen': 'utilizar',
			});
			await _cargar();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		}
	}

	Future<void> _analizarStock() async {
		final bajos = _stock.where(_bajoStock).toList();
		if (!mounted) return;
		await showDialog<void>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Analizar stock'),
				content: SizedBox(
					width: 420,
					child: bajos.isEmpty
							? const Text('No hay ítems en bajo stock.')
							: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text('${bajos.length} ítem(s) requieren atención:'),
										const SizedBox(height: 12),
										for (final item in bajos.take(12))
											Padding(
												padding: const EdgeInsets.only(bottom: 6),
												child: Text(
													'• ${(item['material'] as Map?)?['codigo']} — '
													'${(item['material'] as Map?)?['nombre']} '
													'(disp. ${_disponible(item)})',
												),
											),
									],
								),
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Cerrar'),
					),
				],
			),
		);
	}

	Future<void> _pedirStock() async {
		if (!_canEdit || _panolId == null) return;
		final candidatos = _stock.where(_bajoStock).toList();
		if (candidatos.isEmpty) {
			_toast('No hay materiales con bajo stock para pedir');
			return;
		}
		Map<String, dynamic> elegido = candidatos.first;
		final cantCtrl = TextEditingController(text: '10');
		final ok = await showDialog<bool>(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setDialog) => AlertDialog(
					title: const Text('Pedir stock'),
					content: SizedBox(
						width: 420,
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								DropdownButtonFormField<String>(
									value: elegido['id'] as String,
									decoration: const InputDecoration(
										labelText: 'Material (bajo stock)',
										border: OutlineInputBorder(),
									),
									items: [
										for (final item in candidatos)
											DropdownMenuItem(
												value: item['id'] as String,
												child: Text(
													'${(item['material'] as Map?)?['codigo']} — '
													'${(item['material'] as Map?)?['nombre']}',
												),
											),
									],
									onChanged: (id) {
										final found =
												candidatos.where((c) => c['id'] == id).firstOrNull;
										if (found != null) setDialog(() => elegido = found);
									},
								),
								const SizedBox(height: 12),
								TextField(
									controller: cantCtrl,
									keyboardType: TextInputType.number,
									decoration: const InputDecoration(
										labelText: 'Cantidad a pedir',
										border: OutlineInputBorder(),
									),
								),
							],
						),
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.pop(context, false),
							child: const Text('Cancelar'),
						),
						FilledButton(
							style: FilledButton.styleFrom(backgroundColor: AppColors.brandRed),
							onPressed: () => Navigator.pop(context, true),
							child: const Text('Pedir'),
						),
					],
				),
			),
		);
		if (ok != true) return;
		final mat = elegido['material'] as Map<String, dynamic>? ?? {};
		try {
			await ref.read(apiClientProvider).postJson('pedidos-stock', {
				'panolId': _panolId,
				'materialId': mat['id'],
				'cantidad': double.tryParse(cantCtrl.text) ?? 10,
			});
			await _cargar();
			_toast('Pedido creado');
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		}
	}

	void _toast(String msg) {
		ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
	}

	@override
	Widget build(BuildContext context) {
		final wide = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;
		final showSide = widget.embeddedInPanol && wide;
		final bajos = _stock.where(_bajoStock).length;
		final okCount = _stock.length - bajos;
		final pendientes =
				_pedidos.where((p) => p['estado'] != 'completado').length;

		return ColoredBox(
			color: widget.embeddedInPanol ? PanolUi.of(context).canvas : Theme.of(context).scaffoldBackgroundColor,
			child: PanolPageFade(
				child: Padding(
					padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							PanolSectionTitle(
								title: 'Inventario',
								subtitle: 'Materiales y disponibilidad',
								trailing: IconButton.filledTonal(
									onPressed: _cargar,
									icon: const Icon(Icons.refresh_rounded),
									tooltip: 'Actualizar',
								),
							),
							const SizedBox(height: 10),
							if (_panoles.length > 1) ...[
								DropdownButtonFormField<String>(
									value: _panolId,
									decoration: const InputDecoration(
										labelText: 'Pañol',
										border: OutlineInputBorder(),
										isDense: true,
									),
									items: [
										for (final p in _panoles)
											DropdownMenuItem(
												value: p['id'] as String,
												child: Text(p['nombre'] as String? ?? 'Pañol'),
											),
									],
									onChanged: (v) {
										setState(() => _panolId = v);
										_cargar();
									},
								),
								const SizedBox(height: 10),
							],
							if (!_loading && _error == null) ...[
								PanolCollapsibleKpis(
									title: 'Resumen de stock',
									kpis: [
										PanolKpi(
											label: 'Ítems en stock',
											value: _stock.length,
											icon: Icons.inventory_2_outlined,
										),
										PanolKpi(
											label: 'Disponibles OK',
											value: okCount,
											icon: Icons.check_circle_outline,
											tone: PanolKpiTone.success,
										),
										PanolKpi(
											label: 'Bajo stock',
											value: bajos,
											icon: Icons.warning_amber_rounded,
											tone: bajos > 0
													? PanolKpiTone.danger
													: PanolKpiTone.neutral,
											hint: bajos > 0 ? 'Requieren reposición' : null,
										),
										PanolKpi(
											label: 'Pedidos abiertos',
											value: pendientes,
											icon: Icons.local_shipping_outlined,
											tone: pendientes > 0
													? PanolKpiTone.warning
													: PanolKpiTone.neutral,
										),
									],
								),
								const SizedBox(height: 10),
							],
							Expanded(
								child: _loading
										? const Center(child: CircularProgressIndicator())
										: _error != null
												? Center(child: Text(_error!))
												: Row(
														crossAxisAlignment: CrossAxisAlignment.stretch,
														children: [
															Expanded(flex: 5, child: _stockPanel()),
															if (showSide) ...[
																const SizedBox(width: 12),
																SizedBox(width: 300, child: _pedidosPanel()),
															],
														],
													),
							),
						],
					),
				),
			),
		);
	}

	Widget _stockPanel() {
		final rows = _filtrados;
		return PanolSurface(
			clip: true,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								Text(
									'Materiales',
									style: TextStyle(
										fontWeight: FontWeight.w800,
										fontSize: 15,
										color: PanolUi.of(context).ink,
									),
								),
								const SizedBox(height: 12),
								Wrap(
									spacing: 8,
									runSpacing: 8,
									children: [
										PanolToolbarButton(
											label: 'Editar',
											icon: Icons.edit_outlined,
											variant: PanolToolbarVariant.secondary,
											onTap: _canEdit ? _editar : null,
										),
										PanolToolbarButton(
											label: 'Añadir',
											icon: Icons.add_rounded,
											onTap: _canEdit ? _anadir : null,
										),
										PanolToolbarButton(
											label: 'Utilizar',
											icon: Icons.build_circle_outlined,
											variant: PanolToolbarVariant.secondary,
											onTap: _canEdit ? _utilizar : null,
										),
										PanolToolbarButton(
											label: 'Eliminar',
											icon: Icons.delete_outline,
											variant: PanolToolbarVariant.danger,
											onTap: _canEdit ? _eliminar : null,
										),
									],
								),
								const SizedBox(height: 12),
								PanolSearchField(
									hint: 'Buscar por código, nombre o uso…',
									onChanged: (v) => setState(() => _q = v),
								),
							],
						),
					),
					Divider(height: 1, color: PanolUi.of(context).border),
					Expanded(
						child: rows.isEmpty
								? const PanolEmptyState(
										icon: Icons.inventory_2_outlined,
										title: 'Sin materiales',
										subtitle: 'Añadí el primer ítem o ajustá la búsqueda.',
									)
								: ListView.separated(
										itemCount: rows.length,
										separatorBuilder: (_, __) =>
												Divider(height: 1, color: PanolUi.of(context).border),
										itemBuilder: (context, index) {
											final item = rows[index];
											final mat =
													item['material'] as Map<String, dynamic>? ?? {};
											final selected = _selected?['id'] == item['id'];
											final bajo = _bajoStock(item);
											return Material(
												color: selected
														? PanolUi.of(context).softYellow
														: index.isEven
																? PanolUi.of(context).surface
																: PanolUi.of(context).rowAlt,
												child: InkWell(
													onTap: () => setState(() => _selected = item),
													child: Padding(
														padding: const EdgeInsets.symmetric(
															horizontal: 16,
															vertical: 14,
														),
														child: Row(
															children: [
																Expanded(
																	flex: 2,
																	child: Text(
																		'${mat['codigo'] ?? ''}',
																		style: TextStyle(
																			fontWeight: FontWeight.w800,
																			fontSize: 13,
																			letterSpacing: 0.2,
																			color: PanolUi.of(context).ink,
																		),
																	),
																),
																Expanded(
																	flex: 3,
																	child: Column(
																		crossAxisAlignment:
																				CrossAxisAlignment.start,
																		children: [
																			Text(
																				'${mat['nombre'] ?? ''}',
																				style: TextStyle(
																					fontWeight: FontWeight.w600,
																					fontSize: 14,
																					color: PanolUi.of(context).ink,
																				),
																			),
																			SizedBox(height: 2),
																			Text(
																				'${mat['uso'] ?? '—'}',
																				style: TextStyle(
																					color: PanolUi.of(context).muted,
																					fontSize: 12,
																				),
																			),
																		],
																	),
																),
																SizedBox(
																	width: 72,
																	child: Text(
																		'${_disponible(item)}',
																		textAlign: TextAlign.right,
																		style: TextStyle(
																			fontWeight: FontWeight.w800,
																			fontSize: 16,
																			color: bajo
																					? AppColors.brandRed
																					: PanolUi.of(context).ink,
																		),
																	),
																),
																const SizedBox(width: 12),
																PanolStatusPill(
																	label: bajo ? 'Bajo stock' : 'OK',
																	tone: bajo
																			? PanolKpiTone.danger
																			: PanolKpiTone.success,
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
		);
	}

	Widget _pedidosPanel() {
		final bajos = _stock.where(_bajoStock).isNotEmpty;
		return PanolSurface(
			padding: const EdgeInsets.all(16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Text(
						'Acciones rápidas',
						style: TextStyle(
							fontWeight: FontWeight.w800,
							fontSize: 15,
							color: PanolUi.of(context).ink,
						),
					),
					SizedBox(height: 4),
					Text(
						'Analizá mínimos y generá reposición.',
						style: TextStyle(color: PanolUi.of(context).muted, fontSize: 12),
					),
					const SizedBox(height: 14),
					SizedBox(
						height: 46,
						child: FilledButton.icon(
							style: FilledButton.styleFrom(
								backgroundColor: AppColors.brandYellow,
								foregroundColor: AppColors.ink,
								shape: RoundedRectangleBorder(
									borderRadius: BorderRadius.circular(12),
								),
							),
							onPressed: _analizarStock,
							icon: const Icon(Icons.analytics_outlined),
							label: const Text(
								'Analizar stock',
								style: TextStyle(fontWeight: FontWeight.w700),
							),
						),
					),
					const SizedBox(height: 8),
					SizedBox(
						height: 46,
						child: FilledButton.icon(
							style: FilledButton.styleFrom(
								backgroundColor: bajos ? AppColors.brandRed : const Color(0xFF9CA3AF),
								foregroundColor: Colors.white,
								shape: RoundedRectangleBorder(
									borderRadius: BorderRadius.circular(12),
								),
							),
							onPressed: bajos && _canEdit ? _pedirStock : null,
							icon: const Icon(Icons.shopping_cart_outlined),
							label: Text(
								bajos ? 'Pedir stock' : 'Sin bajo stock',
								style: const TextStyle(fontWeight: FontWeight.w700),
							),
						),
					),
					SizedBox(height: 20),
					Text(
						'Últimos pedidos',
						style: TextStyle(
							fontWeight: FontWeight.w800,
							fontSize: 13,
							color: PanolUi.of(context).ink,
							letterSpacing: 0.2,
						),
					),
					const SizedBox(height: 10),
					Expanded(
						child: _pedidos.isEmpty
								? const PanolEmptyState(
										icon: Icons.receipt_long_outlined,
										title: 'Sin pedidos',
									)
								: ListView.separated(
										itemCount: _pedidos.take(10).length,
										separatorBuilder: (_, __) => const SizedBox(height: 8),
										itemBuilder: (context, index) {
											final p = _pedidos[index];
											final mat =
													p['material'] as Map<String, dynamic>? ?? {};
											final numero = p['numero'] as int? ?? 0;
											final estado = p['estado'] as String? ?? 'pendiente';
											final fecha = p['createdAt'] != null
													? DateTime.tryParse(p['createdAt'].toString())
													: null;
											return Container(
												padding: EdgeInsets.all(12),
												decoration: BoxDecoration(
													color: PanolUi.of(context).rowAlt,
													borderRadius: BorderRadius.circular(12),
													border: Border.all(color: PanolUi.of(context).border),
												),
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Row(
															children: [
																Text(
																	'PD-${numero.toString().padLeft(4, '0')}',
																	style: TextStyle(
																		fontWeight: FontWeight.w800,
																		fontSize: 13,
																		color: PanolUi.of(context).ink,
																	),
																),
																const Spacer(),
																PanolStatusPill(
																	label: pedidoLabel(estado),
																	tone: pedidoTone(estado),
																),
															],
														),
														const SizedBox(height: 6),
														Text(
															'${mat['nombre'] ?? ''}',
															style: TextStyle(
																fontSize: 13,
																fontWeight: FontWeight.w600,
																color: PanolUi.of(context).ink,
															),
														),
														SizedBox(height: 2),
														Text(
															fecha != null ? _dateFmt.format(fecha) : '—',
															style: TextStyle(
																color: PanolUi.of(context).muted,
																fontSize: 11,
															),
														),
													],
												),
											);
										},
									),
					),
				],
			),
		);
	}
}