import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import 'panol_ui.dart';

/// Dashboard de pedidos: resumen ejecutivo + accesos rápidos.
class DashboardPedidosPage extends ConsumerStatefulWidget {
	const DashboardPedidosPage({super.key});

	@override
	ConsumerState<DashboardPedidosPage> createState() =>
			_DashboardPedidosPageState();
}

class _DashboardPedidosPageState extends ConsumerState<DashboardPedidosPage> {
	static final _dateFmt = DateFormat('dd/MM/yyyy');

	List<Map<String, dynamic>> _pedidos = [];
	List<Map<String, dynamic>> _solicitudes = [];
	List<Map<String, dynamic>> _stock = [];
	bool _loading = true;
	String? _error;

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
			final pedidos =
					(await api.getList('pedidos-stock')).cast<Map<String, dynamic>>();
			final stock = (await api.getList('stock')).cast<Map<String, dynamic>>();
			List<Map<String, dynamic>> solicitudes = [];
			try {
				solicitudes =
						(await api.getList('solicitudes-materiales?estado=pendiente'))
								.cast<Map<String, dynamic>>();
			} catch (_) {}
			if (!mounted) return;
			setState(() {
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

	bool _bajo(Map<String, dynamic> item) {
		if (item['bajoMinimo'] == true) return true;
		final d = (item['disponible'] as num?)?.toDouble() ??
				((item['cantidadActual'] as num?)?.toDouble() ?? 0) -
						((item['cantidadReservada'] as num?)?.toDouble() ?? 0);
		return d < 6;
	}

	@override
	Widget build(BuildContext context) {
		final pendientes =
				_pedidos.where((p) => p['estado'] == 'pendiente').length;
		final enProceso =
				_pedidos.where((p) => p['estado'] == 'en_proceso').length;
		final completados =
				_pedidos.where((p) => p['estado'] == 'completado').length;
		final bajos = _stock.where(_bajo).length;
		final recientes = _pedidos.take(8).toList();

		return ColoredBox(
			color: PanolUi.of(context).canvas,
			child: PanolPageFade(
				child: RefreshIndicator(
					onRefresh: _cargar,
					color: AppColors.brandYellow,
					child: ListView(
						padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
						children: [
							PanolSectionTitle(
								title: 'Dashboard de pedidos',
								subtitle: 'Vista general de reposición y solicitudes.',
								trailing: IconButton.filledTonal(
									onPressed: _cargar,
									icon: const Icon(Icons.refresh_rounded),
								),
							),
							const SizedBox(height: 16),
							if (_loading)
								const Padding(
									padding: EdgeInsets.symmetric(vertical: 48),
									child: Center(child: CircularProgressIndicator()),
								)
							else if (_error != null)
								Center(child: Text(_error!))
							else ...[
								LayoutBuilder(
									builder: (context, c) {
										final cols = c.maxWidth > 900
												? 4
												: c.maxWidth > 560
														? 2
														: 1;
										final kpis = [
											PanolKpi(
												label: 'Pendientes',
												value: pendientes,
												icon: Icons.hourglass_empty_rounded,
												tone: pendientes > 0
														? PanolKpiTone.danger
														: PanolKpiTone.neutral,
											),
											PanolKpi(
												label: 'En proceso',
												value: enProceso,
												icon: Icons.sync_rounded,
												tone: enProceso > 0
														? PanolKpiTone.warning
														: PanolKpiTone.neutral,
											),
											PanolKpi(
												label: 'Completados',
												value: completados,
												icon: Icons.check_circle_outline,
												tone: PanolKpiTone.success,
											),
											PanolKpi(
												label: 'Solicitudes OT',
												value: _solicitudes.length,
												icon: Icons.assignment_outlined,
												tone: _solicitudes.isNotEmpty
														? PanolKpiTone.danger
														: PanolKpiTone.success,
												hint: bajos > 0 ? '$bajos ítems bajo stock' : null,
											),
										];
										return Wrap(
											spacing: 12,
											runSpacing: 12,
											children: [
												for (final k in kpis)
													SizedBox(
														width: (c.maxWidth - (cols - 1) * 12) / cols,
														child: k,
													),
											],
										);
									},
								),
								const SizedBox(height: 16),
								Row(
									children: [
										Expanded(
											child: PanolToolbarButton(
												label: 'Ir a pedidos',
												icon: Icons.receipt_long_outlined,
												onTap: () => context.go('/panol/pedidos'),
											),
										),
										const SizedBox(width: 8),
										Expanded(
											child: PanolToolbarButton(
												label: 'Ver stock',
												icon: Icons.inventory_2_outlined,
												variant: PanolToolbarVariant.secondary,
												onTap: () => context.go('/panol/stock'),
											),
										),
									],
								),
								const SizedBox(height: 20),
								PanolSurface(
									clip: true,
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.stretch,
										children: [
											const Padding(
												padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
												child: Text(
													'Actividad reciente',
													style: TextStyle(
														fontWeight: FontWeight.w800,
														fontSize: 15,
													),
												),
											),
											if (recientes.isEmpty)
												const Padding(
													padding: EdgeInsets.all(24),
													child: PanolEmptyState(
														icon: Icons.inbox_outlined,
														title: 'Sin pedidos aún',
													),
												)
											else
												for (var i = 0; i < recientes.length; i++) ...[
													if (i > 0)
														Divider(height: 1, color: PanolUi.of(context).border),
													_RecentRow(
														pedido: recientes[i],
														dateFmt: _dateFmt,
														onTap: () => context.go('/panol/pedidos'),
													),
												],
										],
									),
								),
							],
						],
					),
				),
			),
		);
	}
}

class _RecentRow extends StatelessWidget {
	const _RecentRow({
		required this.pedido,
		required this.dateFmt,
		required this.onTap,
	});

	final Map<String, dynamic> pedido;
	final DateFormat dateFmt;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final mat = pedido['material'] as Map<String, dynamic>? ?? {};
		final numero = pedido['numero'] as int? ?? 0;
		final estado = pedido['estado'] as String? ?? 'pendiente';
		final fecha = pedido['createdAt'] != null
				? DateTime.tryParse(pedido['createdAt'].toString())
				: null;

		return ListTile(
			onTap: onTap,
			title: Text(
				'PD-${numero.toString().padLeft(4, '0')} · ${mat['nombre'] ?? ''}',
				style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
			),
			subtitle: Text(
				fecha != null ? dateFmt.format(fecha) : '—',
				style: const TextStyle(fontSize: 12),
			),
			trailing: PanolStatusPill(
				label: pedidoLabel(estado),
				tone: pedidoTone(estado),
			),
		);
	}
}