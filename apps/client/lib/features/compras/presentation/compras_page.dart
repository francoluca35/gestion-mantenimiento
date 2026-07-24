import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class ComprasPage extends ConsumerStatefulWidget {
	const ComprasPage({super.key});

	@override
	ConsumerState<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends ConsumerState<ComprasPage>
		with SingleTickerProviderStateMixin {
	late final TabController _tabs;
	List<dynamic> _ocs = [];
	List<dynamic> _proveedores = [];
	List<dynamic> _materiales = [];
	bool _loading = true;
	String? _error;

	@override
	void initState() {
		super.initState();
		_tabs = TabController(length: 2, vsync: this);
		WidgetsBinding.instance.addPostFrameCallback((_) => _load());
	}

	@override
	void dispose() {
		_tabs.dispose();
		super.dispose();
	}

	Future<void> _load() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final api = ref.read(apiClientProvider);
			final results = await Future.wait([
				api.getList('ordenes-compra'),
				api.getList('proveedores'),
				api.getList('materiales'),
			]);
			if (!mounted) return;
			setState(() {
				_ocs = results[0];
				_proveedores = results[1];
				_materiales = results[2];
				_loading = false;
			});
		} catch (e) {
			if (!mounted) return;
			setState(() {
				_error = e.toString();
				_loading = false;
			});
		}
	}

	Future<void> _cambiarEstado(String id, String estado) async {
		try {
			await ref.read(apiClientProvider).patchJson('ordenes-compra/$id/estado', {
				'estado': estado,
			});
			await _load();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('No se pudo actualizar: $e')),
			);
		}
	}

	Future<void> _nuevaOc() async {
		if (_proveedores.isEmpty || _materiales.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Necesitás proveedores y materiales cargados')),
			);
			return;
		}
		String? proveedorId = (_proveedores.first as Map)['id'] as String?;
		String? materialId = (_materiales.first as Map)['id'] as String?;
		final cantidadCtrl = TextEditingController(text: '1');
		final precioCtrl = TextEditingController(text: '0');
		final notasCtrl = TextEditingController();

		final ok = await showModalBottomSheet<bool>(
			context: context,
			isScrollControlled: true,
			useSafeArea: true,
			builder: (ctx) {
				return StatefulBuilder(
					builder: (ctx, setLocal) {
						return Padding(
							padding: EdgeInsets.only(
								left: 16,
								right: 16,
								top: 16,
								bottom: 16 + MediaQuery.viewInsetsOf(ctx).bottom,
							),
							child: SingleChildScrollView(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										Text(
											'Nueva orden de compra',
											style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
														fontWeight: FontWeight.w800,
													),
										),
										const SizedBox(height: 12),
										DropdownButtonFormField<String>(
											value: proveedorId,
											decoration: const InputDecoration(labelText: 'Proveedor'),
											items: [
												for (final raw in _proveedores)
													DropdownMenuItem(
														value: (raw as Map)['id'] as String,
														child: Text('${raw['nombre']}'),
													),
											],
											onChanged: (v) => setLocal(() => proveedorId = v),
										),
										const SizedBox(height: 8),
										DropdownButtonFormField<String>(
											value: materialId,
											decoration: const InputDecoration(labelText: 'Material'),
											items: [
												for (final raw in _materiales)
													DropdownMenuItem(
														value: (raw as Map)['id'] as String,
														child: Text('${raw['codigo']} — ${raw['nombre']}'),
													),
											],
											onChanged: (v) => setLocal(() => materialId = v),
										),
										const SizedBox(height: 8),
										TextField(
											controller: cantidadCtrl,
											keyboardType: const TextInputType.numberWithOptions(decimal: true),
											decoration: const InputDecoration(labelText: 'Cantidad'),
										),
										const SizedBox(height: 8),
										TextField(
											controller: precioCtrl,
											keyboardType: const TextInputType.numberWithOptions(decimal: true),
											decoration: const InputDecoration(labelText: 'Precio unitario'),
										),
										const SizedBox(height: 8),
										TextField(
											controller: notasCtrl,
											decoration: const InputDecoration(labelText: 'Notas'),
										),
										const SizedBox(height: 16),
										FilledButton(
											onPressed: () => Navigator.pop(ctx, true),
											child: const Text('Crear OC'),
										),
									],
								),
							),
						);
					},
				);
			},
		);

		if (ok != true || proveedorId == null || materialId == null) return;
		try {
			await ref.read(apiClientProvider).postJson('ordenes-compra', {
				'proveedorId': proveedorId,
				'notas': notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
				'lineas': [
					{
						'materialId': materialId,
						'cantidad': double.tryParse(cantidadCtrl.text.replaceAll(',', '.')) ?? 1,
						'precioUnitario':
								double.tryParse(precioCtrl.text.replaceAll(',', '.')) ?? 0,
					},
				],
			});
			await _load();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Error al crear OC: $e')),
			);
		}
	}

	Future<void> _nuevoProveedor() async {
		final nombre = TextEditingController();
		final cuit = TextEditingController();
		final contacto = TextEditingController();
		final ok = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Nuevo proveedor'),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						TextField(
							controller: nombre,
							decoration: const InputDecoration(labelText: 'Nombre'),
						),
						TextField(
							controller: cuit,
							decoration: const InputDecoration(labelText: 'CUIT'),
						),
						TextField(
							controller: contacto,
							decoration: const InputDecoration(labelText: 'Contacto'),
						),
					],
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(ctx, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						onPressed: () => Navigator.pop(ctx, true),
						child: const Text('Guardar'),
					),
				],
			),
		);
		if (ok != true || nombre.text.trim().isEmpty) return;
		try {
			await ref.read(apiClientProvider).postJson('proveedores', {
				'nombre': nombre.text.trim(),
				'cuit': cuit.text.trim().isEmpty ? null : cuit.text.trim(),
				'contacto': contacto.text.trim().isEmpty ? null : contacto.text.trim(),
			});
			await _load();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Error: $e')),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		final user = ref.watch(authControllerProvider).session?.usuario;
		final canEmitir =
				user?.tieneDerecho('stock.ordenes_compra.emitir') == true ||
				user?.esAdministrador == true;

		return Column(
			children: [
				Padding(
					padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
					child: Row(
						children: [
							Expanded(
								child: Text(
									'Compras',
									style: Theme.of(context).textTheme.headlineSmall?.copyWith(
												fontWeight: FontWeight.w800,
											),
								),
							),
							if (canEmitir)
								IconButton(
									tooltip: 'Nuevo proveedor',
									onPressed: _nuevoProveedor,
									icon: const Icon(Icons.person_add_alt_1_rounded),
								),
							if (canEmitir)
								IconButton(
									tooltip: 'Nueva OC',
									onPressed: _nuevaOc,
									icon: const Icon(Icons.add_box_outlined),
								),
							IconButton(
								onPressed: _loading ? null : _load,
								icon: const Icon(Icons.refresh_rounded),
							),
						],
					),
				),
				TabBar(
					controller: _tabs,
					tabs: const [
						Tab(text: 'Órdenes'),
						Tab(text: 'Proveedores'),
					],
				),
				Expanded(
					child: _loading
							? const Center(child: CircularProgressIndicator())
							: _error != null
									? Center(child: Text(_error!))
									: TabBarView(
											controller: _tabs,
											children: [
												RefreshIndicator(
													onRefresh: _load,
													child: ListView.separated(
														padding: const EdgeInsets.all(12),
														itemCount: _ocs.length,
														separatorBuilder: (_, __) => const SizedBox(height: 8),
														itemBuilder: (context, i) {
															final oc = (_ocs[i] as Map).cast<String, dynamic>();
															final proveedor =
																	(oc['proveedor'] as Map?)?.cast<String, dynamic>();
															final estado = '${oc['estado'] ?? ''}';
															return Card(
																child: Padding(
																	padding: const EdgeInsets.all(12),
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			Row(
																				children: [
																					Text(
																						'OC #${oc['numero']}',
																						style: const TextStyle(
																							fontWeight: FontWeight.w800,
																							fontSize: 16,
																						),
																					),
																					const Spacer(),
																					_EstadoChip(estado),
																				],
																			),
																			const SizedBox(height: 4),
																			Text(proveedor?['nombre']?.toString() ?? '—'),
																			Text(
																				'Total: \$${oc['montoTotal']}',
																				style: TextStyle(
																					color: Theme.of(context)
																							.colorScheme
																							.onSurface
																							.withValues(alpha: 0.6),
																				),
																			),
																			if (estado == 'solicitada') ...[
																				const SizedBox(height: 8),
																				Wrap(
																					spacing: 8,
																					children: [
																						FilledButton(
																							onPressed: () =>
																									_cambiarEstado(oc['id'] as String, 'autorizada'),
																							child: const Text('Autorizar'),
																						),
																						OutlinedButton(
																							onPressed: () => _cambiarEstado(
																									oc['id'] as String, 'no_autorizada'),
																							child: const Text('Rechazar'),
																						),
																					],
																				),
																			],
																			if (estado == 'autorizada') ...[
																				const SizedBox(height: 8),
																				FilledButton.tonal(
																					onPressed: () =>
																							_cambiarEstado(oc['id'] as String, 'recibida'),
																					child: const Text('Marcar recibida'),
																				),
																			],
																		],
																	),
																),
															);
														},
													),
												),
												RefreshIndicator(
													onRefresh: _load,
													child: ListView.separated(
														padding: const EdgeInsets.all(12),
														itemCount: _proveedores.length,
														separatorBuilder: (_, __) => const SizedBox(height: 8),
														itemBuilder: (context, i) {
															final p =
																	(_proveedores[i] as Map).cast<String, dynamic>();
															return ListTile(
																shape: RoundedRectangleBorder(
																	borderRadius: BorderRadius.circular(12),
																	side: BorderSide(
																		color: Theme.of(context).brightness ==
																				Brightness.dark
																				? AppColors.cardBorder
																				: const Color(0xFFE2E6EC),
																	),
																),
																title: Text(
																	'${p['nombre']}',
																	style: const TextStyle(fontWeight: FontWeight.w700),
																),
																subtitle: Text(
																	[
																		if ((p['cuit'] as String?)?.isNotEmpty == true)
																			'CUIT ${p['cuit']}',
																		if ((p['contacto'] as String?)?.isNotEmpty == true)
																			p['contacto'],
																	].join(' · '),
																),
															);
														},
													),
												),
											],
										),
				),
			],
		);
	}
}

class _EstadoChip extends StatelessWidget {
	const _EstadoChip(this.estado);

	final String estado;

	@override
	Widget build(BuildContext context) {
		final color = switch (estado) {
			'autorizada' => AppColors.brandGreenDark,
			'recibida' => AppColors.success,
			'no_autorizada' || 'anulada' => AppColors.danger,
			_ => AppColors.accent,
		};
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				estado.replaceAll('_', ' '),
				style: TextStyle(
					color: color,
					fontWeight: FontWeight.w800,
					fontSize: 11,
				),
			),
		);
	}
}
