import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

Future<bool> showSolicitarMaterialesSheet(
	BuildContext context,
	WidgetRef ref, {
	required String otId,
	required int otNumero,
}) async {
	final result = await showModalBottomSheet<bool>(
		context: context,
		isScrollControlled: true,
		useSafeArea: true,
		builder: (context) => _SolicitarMaterialesSheet(
			otId: otId,
			otNumero: otNumero,
		),
	);
	return result == true;
}

class _SolicitarMaterialesSheet extends ConsumerStatefulWidget {
	const _SolicitarMaterialesSheet({
		required this.otId,
		required this.otNumero,
	});

	final String otId;
	final int otNumero;

	@override
	ConsumerState<_SolicitarMaterialesSheet> createState() =>
			_SolicitarMaterialesSheetState();
}

class _SolicitarMaterialesSheetState
		extends ConsumerState<_SolicitarMaterialesSheet> {
	List<Map<String, dynamic>> _stock = [];
	List<Map<String, dynamic>> _panoles = [];
	String? _panolId;
	final Map<String, TextEditingController> _cantidades = {};
	final Set<String> _seleccionados = {};
	bool _loading = true;
	bool _saving = false;
	String? _error;
	String _q = '';

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
	}

	@override
	void dispose() {
		for (final c in _cantidades.values) {
			c.dispose();
		}
		super.dispose();
	}

	Future<void> _cargar() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final api = ref.read(apiClientProvider);
			final panoles = (await api.getList('panoles')).cast<Map<String, dynamic>>();
			final panolId = panoles.isNotEmpty ? panoles.first['id'] as String : null;
			final stock = (await api.getList(
				panolId != null ? 'stock?panolId=$panolId' : 'stock',
			))
					.cast<Map<String, dynamic>>();
			if (!mounted) return;
			setState(() {
				_panoles = panoles;
				_panolId = panolId;
				_stock = stock;
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
			return '${mat['codigo']}'.toLowerCase().contains(q) ||
					'${mat['nombre']}'.toLowerCase().contains(q);
		}).toList();
	}

	Future<void> _enviar() async {
		if (_seleccionados.isEmpty || _panolId == null) return;
		final items = <Map<String, dynamic>>[];
		for (final stockId in _seleccionados) {
			final item = _stock.where((s) => s['id'] == stockId).firstOrNull;
			if (item == null) continue;
			final mat = item['material'] as Map<String, dynamic>? ?? {};
			final qty = double.tryParse(_cantidades[stockId]?.text ?? '1') ?? 1;
			if (qty <= 0) continue;
			items.add({'materialId': mat['id'], 'cantidad': qty});
		}
		if (items.isEmpty) return;

		setState(() => _saving = true);
		try {
			await ref.read(apiClientProvider).postJson('solicitudes-materiales', {
				'otId': widget.otId,
				'panolId': _panolId,
				'items': items,
			});
			if (mounted) Navigator.pop(context, true);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		} finally {
			if (mounted) setState(() => _saving = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final bottom = MediaQuery.viewInsetsOf(context).bottom;
		return Padding(
			padding: EdgeInsets.only(bottom: bottom),
			child: DraggableScrollableSheet(
				expand: false,
				initialChildSize: 0.85,
				minChildSize: 0.5,
				maxChildSize: 0.95,
				builder: (context, scrollController) {
					return Column(
						children: [
							const SizedBox(height: 8),
							Container(
								width: 40,
								height: 4,
								decoration: BoxDecoration(
									color: AppColors.mutedText,
									borderRadius: BorderRadius.circular(4),
								),
							),
							Padding(
								padding: const EdgeInsets.all(16),
								child: Row(
									children: [
										Expanded(
											child: Text(
												'Solicitar materiales · OT #${widget.otNumero}',
												style: const TextStyle(
													fontWeight: FontWeight.w800,
													fontSize: 16,
												),
											),
										),
										IconButton(
											onPressed: () => Navigator.pop(context, false),
											icon: const Icon(Icons.close),
										),
									],
								),
							),
							if (_panoles.length > 1)
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 16),
									child: DropdownButtonFormField<String>(
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
										onChanged: (v) async {
											setState(() => _panolId = v);
											await _cargar();
										},
									),
								),
							Padding(
								padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
								child: TextField(
									decoration: const InputDecoration(
										hintText: 'Buscar material…',
										prefixIcon: Icon(Icons.search),
										border: OutlineInputBorder(),
										isDense: true,
									),
									onChanged: (v) => setState(() => _q = v),
								),
							),
							Expanded(
								child: _loading
										? const Center(child: CircularProgressIndicator())
										: _error != null
												? Center(child: Text(_error!))
												: ListView.builder(
														controller: scrollController,
														itemCount: _filtrados.length,
														itemBuilder: (context, index) {
															final item = _filtrados[index];
															final id = item['id'] as String;
															final mat =
																	item['material'] as Map<String, dynamic>? ?? {};
															final selected = _seleccionados.contains(id);
															_cantidades.putIfAbsent(
																id,
																() => TextEditingController(text: '1'),
															);
															return CheckboxListTile(
																value: selected,
																onChanged: (v) {
																	setState(() {
																		if (v == true) {
																			_seleccionados.add(id);
																		} else {
																			_seleccionados.remove(id);
																		}
																	});
																},
																title: Text(
																	'${mat['codigo']} — ${mat['nombre']}',
																	style: const TextStyle(
																		fontWeight: FontWeight.w600,
																	),
																),
																subtitle: Text(
																	'Disp. ${item['disponible'] ?? item['cantidadActual'] ?? 0}',
																),
																secondary: selected
																		? SizedBox(
																				width: 72,
																				child: TextField(
																					controller: _cantidades[id],
																					keyboardType: TextInputType.number,
																					decoration: const InputDecoration(
																						labelText: 'Cant.',
																						isDense: true,
																						border: OutlineInputBorder(),
																					),
																				),
																			)
																		: null,
															);
														},
													),
							),
							SafeArea(
								child: Padding(
									padding: const EdgeInsets.all(16),
									child: FilledButton(
										style: FilledButton.styleFrom(
											backgroundColor: AppColors.brandYellow,
											foregroundColor: AppColors.ink,
											minimumSize: const Size.fromHeight(48),
										),
										onPressed:
												_saving || _seleccionados.isEmpty ? null : _enviar,
										child: _saving
												? const SizedBox(
														width: 22,
														height: 22,
														child: CircularProgressIndicator(strokeWidth: 2),
													)
												: Text(
														'Enviar solicitud (${_seleccionados.length})',
														style: const TextStyle(fontWeight: FontWeight.w800),
													),
									),
								),
							),
						],
					);
				},
			),
		);
	}
}
