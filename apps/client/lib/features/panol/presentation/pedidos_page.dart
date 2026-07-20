import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import 'panol_ui.dart';

class PedidosPage extends ConsumerStatefulWidget {
	const PedidosPage({super.key});

	@override
	ConsumerState<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends ConsumerState<PedidosPage>
		with SingleTickerProviderStateMixin {
	static final _dateFmt = DateFormat('dd/MM/yyyy');

	late final TabController _tabs;
	List<Map<String, dynamic>> _pedidos = [];
	List<Map<String, dynamic>> _solicitudes = [];
	List<Map<String, dynamic>> _stock = [];
	List<Map<String, dynamic>> _panoles = [];
	String? _panolId;
	bool _loading = true;
	String? _error;

	AuthUser? get _user => ref.read(authControllerProvider).session?.usuario;

	bool get _canEdit =>
			_user?.tieneDerecho('stock.materiales_en_stock.modificar_valores_gestion') ==
					true ||
			_user?.esAdministrador == true;

	bool get _canAprobar =>
			_user?.tieneDerecho('stock.pañol.solicitudes_materiales.aprobar') == true ||
			_user?.esAdministrador == true;

	bool get _canRechazar =>
			_user?.tieneDerecho('stock.pañol.solicitudes_materiales.rechazar') == true ||
			_user?.esAdministrador == true;

	@override
	void initState() {
		super.initState();
		_tabs = TabController(length: 2, vsync: this);
		WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
	}

	@override
	void dispose() {
		_tabs.dispose();
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
			final panolId = _panolId ??
					(panoles.isNotEmpty ? panoles.first['id'] as String? : null);
			final pedidos = (await api.getList(
				panolId != null ? 'pedidos-stock?panolId=$panolId' : 'pedidos-stock',
			))
					.cast<Map<String, dynamic>>();
			final stock = (await api.getList(
				panolId != null ? 'stock?panolId=$panolId' : 'stock',
			))
					.cast<Map<String, dynamic>>();
			List<Map<String, dynamic>> solicitudes = [];
			try {
				solicitudes = (await api.getList('solicitudes-materiales?estado=pendiente'))
						.cast<Map<String, dynamic>>();
			} catch (_) {
				solicitudes = [];
			}
			if (!mounted) return;
			setState(() {
				_panoles = panoles;
				_panolId = panolId;
				_pedidos = pedidos;
				_stock = stock;
				_solicitudes = solicitudes;
			});
		} catch (e) {
			if (mounted) setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	bool _bajoStock(Map<String, dynamic> item) {
		if (item['bajoMinimo'] == true) return true;
		final disponible = (item['disponible'] as num?)?.toDouble() ??
				((item['cantidadActual'] as num?)?.toDouble() ?? 0) -
						((item['cantidadReservada'] as num?)?.toDouble() ?? 0);
		return disponible < 6;
	}

	Future<void> _analizar() async {
		final bajos = _stock.where(_bajoStock).toList();
		await showDialog<void>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Analizar stock'),
				content: SizedBox(
					width: 420,
					child: bajos.isEmpty
							? const Text('Todo el stock está OK.')
							: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										for (final item in bajos.take(15))
											Text(
												'• ${(item['material'] as Map?)?['codigo']} — '
												'${(item['material'] as Map?)?['nombre']}',
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

	Future<void> _pedir() async {
		if (!_canEdit || _panolId == null) return;
		final candidatos = _stock.where(_bajoStock).toList();
		if (candidatos.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('No hay bajo stock para pedir')),
			);
			return;
		}
		Map<String, dynamic> elegido = candidatos.first;
		final cantCtrl = TextEditingController(text: '10');
		final ok = await showDialog<bool>(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setDialog) => AlertDialog(
					title: const Text('Pedir stock'),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							DropdownButtonFormField<String>(
								value: elegido['id'] as String,
								decoration: const InputDecoration(
									labelText: 'Material',
									border: OutlineInputBorder(),
								),
								items: [
									for (final item in candidatos)
										DropdownMenuItem(
											value: item['id'] as String,
											child: Text(
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
									labelText: 'Cantidad',
									border: OutlineInputBorder(),
								),
							),
						],
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
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		}
	}

	Future<void> _avanzarPedido(Map<String, dynamic> pedido) async {
		if (!_canEdit) return;
		final estado = pedido['estado'] as String? ?? 'pendiente';
		final next = estado == 'pendiente' ? 'en_proceso' : 'completado';
		try {
			await ref.read(apiClientProvider).patchJson('pedidos-stock/${pedido['id']}', {
				'estado': next,
			});
			await _cargar();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		}
	}

	Future<void> _aprobar(Map<String, dynamic> sol) async {
		try {
			await ref.read(apiClientProvider).patchJson(
				'solicitudes-materiales/${sol['id']}/aprobar',
				{},
			);
			await _cargar();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		}
	}

	Future<void> _rechazar(Map<String, dynamic> sol) async {
		final motivoCtrl = TextEditingController();
		final ok = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Rechazar solicitud'),
				content: TextField(
					controller: motivoCtrl,
					decoration: const InputDecoration(
						labelText: 'Motivo',
						border: OutlineInputBorder(),
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
						child: const Text('Rechazar'),
					),
				],
			),
		);
		if (ok != true) return;
		try {
			await ref.read(apiClientProvider).patchJson(
				'solicitudes-materiales/${sol['id']}/rechazar',
				{'motivo': motivoCtrl.text.trim()},
			);
			await _cargar();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
		}
	}

	@override
	Widget build(BuildContext context) {
		final bajos = _stock.where(_bajoStock).length;
		final abiertos =
				_pedidos.where((p) => p['estado'] != 'completado').length;
		final ui = PanolUi.of(context);

		return ColoredBox(
			color: ui.canvas,
			child: PanolPageFade(
				child: Padding(
					padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							PanolSectionTitle(
								title: 'Pedidos',
								subtitle: 'Reposición y solicitudes de OT',
								trailing: IconButton.filledTonal(
									onPressed: _cargar,
									icon: const Icon(Icons.refresh_rounded),
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
									title: 'Resumen',
									kpis: [
										PanolKpi(
											label: 'Pedidos abiertos',
											value: abiertos,
											icon: Icons.local_shipping_outlined,
											tone: abiertos > 0
													? PanolKpiTone.warning
													: PanolKpiTone.neutral,
										),
										PanolKpi(
											label: 'Solicitudes OT',
											value: _solicitudes.length,
											icon: Icons.assignment_turned_in_outlined,
											tone: _solicitudes.isNotEmpty
													? PanolKpiTone.danger
													: PanolKpiTone.success,
										),
										PanolKpi(
											label: 'Ítems bajo stock',
											value: bajos,
											icon: Icons.warning_amber_rounded,
											tone: bajos > 0
													? PanolKpiTone.danger
													: PanolKpiTone.success,
										),
									],
								),
								const SizedBox(height: 10),
							],
							Row(
								children: [
									Expanded(
										child: PanolToolbarButton(
											label: 'Analizar',
											icon: Icons.analytics_outlined,
											onTap: _analizar,
										),
									),
									const SizedBox(width: 8),
									Expanded(
										child: PanolToolbarButton(
											label: bajos > 0 ? 'Pedir stock' : 'Sin bajo stock',
											icon: Icons.shopping_cart_outlined,
											variant: PanolToolbarVariant.danger,
											onTap: bajos > 0 && _canEdit ? _pedir : null,
										),
									),
								],
							),
							const SizedBox(height: 10),
							Expanded(
								child: PanolSurface(
									child: Column(
										children: [
											TabBar(
												controller: _tabs,
												labelColor: ui.ink,
												unselectedLabelColor: ui.muted,
												indicatorColor: AppColors.brandYellow,
												indicatorWeight: 3,
												labelStyle: const TextStyle(fontWeight: FontWeight.w700),
												tabs: [
													Tab(text: 'Reposición (${_pedidos.length})'),
													Tab(text: 'Solicitudes OT (${_solicitudes.length})'),
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
																			_pedidosList(),
																			_solicitudesList(),
																		],
																	),
											),
										],
									),
								),
							),
						],
					),
				),
			),
		);
	}

	Widget _pedidosList() {
		if (_pedidos.isEmpty) {
			return const PanolEmptyState(
				icon: Icons.receipt_long_outlined,
				title: 'Sin pedidos de reposición',
				subtitle: 'Cuando haya bajo stock, pedí material desde aquí.',
			);
		}
		return ListView.separated(
			padding: const EdgeInsets.all(12),
			itemCount: _pedidos.length,
			separatorBuilder: (_, __) => const SizedBox(height: 8),
			itemBuilder: (context, index) {
				final p = _pedidos[index];
				final mat = p['material'] as Map<String, dynamic>? ?? {};
				final estado = p['estado'] as String? ?? 'pendiente';
				final numero = p['numero'] as int? ?? 0;
				final fecha = p['createdAt'] != null
						? DateTime.tryParse(p['createdAt'].toString())
						: null;
				final canAdvance = estado != 'completado' && _canEdit;

				return Container(
					padding: EdgeInsets.all(14),
					decoration: BoxDecoration(
						color: index.isEven
								? PanolUi.of(context).surface
								: PanolUi.of(context).rowAlt,
						borderRadius: BorderRadius.circular(14),
						border: Border.all(color: PanolUi.of(context).border),
					),
					child: Row(
						children: [
							Container(
								width: 44,
								height: 44,
								decoration: BoxDecoration(
									color: PanolUi.of(context).softYellow,
									borderRadius: BorderRadius.circular(12),
								),
								alignment: Alignment.center,
								child: Text(
									'${numero.toString().padLeft(2, '0')}',
									style: const TextStyle(
										fontWeight: FontWeight.w800,
										fontSize: 13,
									),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'PD-${numero.toString().padLeft(4, '0')}',
											style: const TextStyle(
												fontWeight: FontWeight.w800,
												fontSize: 14,
											),
										),
										SizedBox(height: 2),
										Text(
											'${mat['nombre'] ?? ''} · Cant. ${p['cantidad']}',
											style: TextStyle(
												color: PanolUi.of(context).muted,
												fontSize: 12,
											),
										),
										Text(
											fecha != null ? _dateFmt.format(fecha) : '—',
											style: TextStyle(
												color: PanolUi.of(context).muted,
												fontSize: 11,
											),
										),
									],
								),
							),
							PanolStatusPill(
								label: pedidoLabel(estado),
								tone: pedidoTone(estado),
							),
							if (canAdvance) ...[
								const SizedBox(width: 8),
								TextButton(
									onPressed: () => _avanzarPedido(p),
									child: Text(
										estado == 'pendiente' ? 'En proceso' : 'Completar',
										style: const TextStyle(fontWeight: FontWeight.w700),
									),
								),
							],
						],
					),
				);
			},
		);
	}

	Widget _solicitudesList() {
		if (_solicitudes.isEmpty) {
			return const PanolEmptyState(
				icon: Icons.assignment_outlined,
				title: 'Sin solicitudes de OT',
				subtitle: 'Cuando un técnico pida materiales, aparecen acá.',
			);
		}
		return ListView.separated(
			padding: const EdgeInsets.all(12),
			itemCount: _solicitudes.length,
			separatorBuilder: (_, __) => const SizedBox(height: 8),
			itemBuilder: (context, index) {
				final sol = _solicitudes[index];
				final mat = sol['material'] as Map<String, dynamic>? ?? {};
				final ot = sol['ot'] as Map<String, dynamic>? ?? {};
				final solicitante =
						sol['solicitante'] as Map<String, dynamic>? ?? {};
				return Container(
					padding: EdgeInsets.all(14),
					decoration: BoxDecoration(
						color: PanolUi.of(context).surface,
						borderRadius: BorderRadius.circular(14),
						border: Border.all(color: PanolUi.of(context).border),
					),
					child: Row(
						children: [
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'${mat['codigo'] ?? ''} — ${mat['nombre'] ?? ''}',
											style: const TextStyle(
												fontWeight: FontWeight.w800,
												fontSize: 14,
											),
										),
										SizedBox(height: 4),
										Text(
											'OT #${ot['numero'] ?? '—'} · Cant. ${sol['cantidad']} · '
											'${solicitante['nombreUsuario'] ?? ''}',
											style: TextStyle(
												color: PanolUi.of(context).muted,
												fontSize: 12,
											),
										),
									],
								),
							),
							if (_canAprobar)
								IconButton.filled(
									style: IconButton.styleFrom(
										backgroundColor: PanolUi.of(context).softGreen,
										foregroundColor: AppColors.success,
									),
									tooltip: 'Aprobar',
									onPressed: () => _aprobar(sol),
									icon: Icon(Icons.check_rounded),
								),
							if (_canRechazar) ...[
								SizedBox(width: 4),
								IconButton.filled(
									style: IconButton.styleFrom(
										backgroundColor: PanolUi.of(context).softRed,
										foregroundColor: AppColors.brandRed,
									),
									tooltip: 'Rechazar',
									onPressed: () => _rechazar(sol),
									icon: const Icon(Icons.close_rounded),
								),
							],
						],
					),
				);
			},
		);
	}
}