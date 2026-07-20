import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import 'panol_ui.dart';

class SeguimientoPage extends ConsumerStatefulWidget {
	const SeguimientoPage({super.key});

	@override
	ConsumerState<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends ConsumerState<SeguimientoPage> {
	static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

	List<Map<String, dynamic>> _movimientos = [];
	List<Map<String, dynamic>> _panoles = [];
	String? _panolId;
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
			final panoles = (await api.getList('panoles')).cast<Map<String, dynamic>>();
			final panolId = _panolId ??
					(panoles.isNotEmpty ? panoles.first['id'] as String? : null);
			final path = panolId != null
					? 'stock/movimientos?panolId=$panolId'
					: 'stock/movimientos';
			final movs = (await api.getList(path)).cast<Map<String, dynamic>>();
			if (!mounted) return;
			setState(() {
				_panoles = panoles;
				_panolId = panolId;
				_movimientos = movs;
			});
		} catch (e) {
			if (mounted) setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	(Color, Color, IconData, String) _tipoMeta(String tipo) {
		final ui = PanolUi.of(context);
		return switch (tipo) {
			'entrada' => (
					ui.softGreen,
					AppColors.success,
					Icons.south_west_rounded,
					'Entrada',
				),
			'salida' => (
					ui.softRed,
					AppColors.brandRed,
					Icons.north_east_rounded,
					'Salida',
				),
			'reserva' => (
					ui.softYellow,
					ui.isDark ? AppColors.brandYellow : const Color(0xFF9A6B00),
					Icons.lock_outline_rounded,
					'Reserva',
				),
			_ => (
					ui.chipBg,
					ui.muted,
					Icons.swap_horiz_rounded,
					tipo,
				),
		};
	}

	@override
	Widget build(BuildContext context) {
		final entradas =
				_movimientos.where((m) => m['tipo'] == 'entrada').length;
		final salidas = _movimientos.where((m) => m['tipo'] == 'salida').length;
		final reservas =
				_movimientos.where((m) => m['tipo'] == 'reserva').length;

		return ColoredBox(
			color: PanolUi.of(context).canvas,
			child: PanolPageFade(
				child: Padding(
					padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							PanolSectionTitle(
								title: 'Seguimiento',
								subtitle: 'Movimientos del pañol',
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
									title: 'Resumen de movimientos',
									kpis: [
										PanolKpi(
											label: 'Entradas',
											value: entradas,
											icon: Icons.south_west_rounded,
											tone: PanolKpiTone.success,
										),
										PanolKpi(
											label: 'Salidas',
											value: salidas,
											icon: Icons.north_east_rounded,
											tone: PanolKpiTone.danger,
										),
										PanolKpi(
											label: 'Reservas',
											value: reservas,
											icon: Icons.lock_outline_rounded,
											tone: PanolKpiTone.warning,
										),
									],
								),
								const SizedBox(height: 10),
							],
							Expanded(
								child: PanolSurface(
									clip: true,
									child: _loading
											? const Center(child: CircularProgressIndicator())
											: _error != null
													? Center(child: Text(_error!))
													: _movimientos.isEmpty
															? const PanolEmptyState(
																	icon: Icons.timeline_outlined,
																	title: 'Sin movimientos',
																	subtitle:
																			'Las entradas, salidas y reservas se verán acá.',
																)
															: ListView.builder(
																	padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
																	itemCount: _movimientos.length,
																	itemBuilder: (context, index) {
																		final m = _movimientos[index];
																		final mat = m['material']
																				as Map<String, dynamic>? ??
																				{};
																		final user = m['usuario']
																				as Map<String, dynamic>? ??
																				{};
																		final tipo = m['tipo'] as String? ?? '';
																		final (bg, fg, icon, label) =
																				_tipoMeta(tipo);
																		final fecha = m['fecha'] != null
																				? DateTime.tryParse(
																						m['fecha'].toString(),
																					)
																				: null;
																		final isLast =
																				index == _movimientos.length - 1;

																		return IntrinsicHeight(
																			child: Row(
																				crossAxisAlignment:
																						CrossAxisAlignment.stretch,
																				children: [
																					SizedBox(
																						width: 36,
																						child: Column(
																							children: [
																								Container(
																									width: 34,
																									height: 34,
																									decoration: BoxDecoration(
																										color: bg,
																										shape: BoxShape.circle,
																										border: Border.all(
																											color: fg.withValues(
																												alpha: 0.25,
																											),
																										),
																									),
																									child: Icon(icon,
																											size: 16, color: fg),
																								),
																								if (!isLast)
																									Expanded(
																										child: Container(
																											width: 2,
																											margin:
																													EdgeInsets.symmetric(
																												vertical: 4,
																											),
																											color: PanolUi.of(context).border,
																										),
																									),
																							],
																						),
																					),
																					const SizedBox(width: 14),
																					Expanded(
																						child: Padding(
																							padding: EdgeInsets.only(
																								bottom: isLast ? 0 : 16,
																							),
																							child: Container(
																								padding: EdgeInsets.all(14),
																								decoration: BoxDecoration(
																									color: PanolUi.of(context).rowAlt,
																									borderRadius:
																											BorderRadius.circular(14),
																									border: Border.all(
																										color: PanolUi.of(context).border,
																									),
																								),
																								child: Column(
																									crossAxisAlignment:
																											CrossAxisAlignment.start,
																									children: [
																										Row(
																											children: [
																												PanolStatusPill(
																													label: label,
																													tone: switch (tipo) {
																														'entrada' =>
																															PanolKpiTone.success,
																														'salida' =>
																															PanolKpiTone.danger,
																														'reserva' =>
																															PanolKpiTone.warning,
																														_ => PanolKpiTone.neutral,
																													},
																												),
																												Spacer(),
																												Text(
																													fecha != null
																															? _dateFmt.format(fecha)
																															: '—',
																													style: TextStyle(
																														color: PanolUi.of(context).muted,
																														fontSize: 11,
																														fontWeight:
																																FontWeight.w600,
																													),
																												),
																											],
																										),
																										SizedBox(height: 8),
																										Text(
																											'${mat['codigo'] ?? ''} — ${mat['nombre'] ?? ''}',
																											style: TextStyle(
																												fontWeight: FontWeight.w800,
																												fontSize: 14,
																												color: PanolUi.of(context).ink,
																											),
																										),
																										SizedBox(height: 4),
																										Text(
																											'Cant. ${m['cantidad']} · ${m['origen'] ?? 'manual'} · ${user['nombreUsuario'] ?? ''}',
																											style: TextStyle(
																												color: PanolUi.of(context).muted,
																												fontSize: 12,
																											),
																										),
																									],
																								),
																							),
																						),
																					),
																				],
																			),
																		);
																	},
																),
								),
							),
						],
					),
				),
			),
		);
	}
}