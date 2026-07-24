import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/layout/shell_back_scope.dart';
import '../../auth/application/auth_controller.dart';

/// Gantt moderno estilo SGMWin: filas = equipos, columnas = días.
/// Rojo = pendiente · Amarillo = en ejecución · Verde = realizada.
class OtGanttPage extends ConsumerStatefulWidget {
	const OtGanttPage({super.key});

	@override
	ConsumerState<OtGanttPage> createState() => _OtGanttPageState();
}

class _OtGanttPageState extends ConsumerState<OtGanttPage> {
	bool _loading = true;
	String? _error;
	List<String> _dias = [];
	List<Map<String, dynamic>> _filas = [];
	Map<String, dynamic> _totales = {};
	late DateTime _desde;
	late DateTime _hasta;
	String _agruparPor = 'equipo';
	bool _misOt = false;

	static const _labelWidth = 200.0;
	static const _dayWidth = 36.0;
	static const _rowHeight = 40.0;
	static const _headerHeight = 52.0;

	/// Colores alineados a SGMWin: rojo pendiente, verde realizada.
	static const _rojoPendiente = Color(0xFFE53935);
	static const _amarilloEjecucion = Color(0xFFFFB300);
	static const _verdeRealizada = Color(0xFF43A047);
	static const _weekendBand = Color(0xFFD6EAF8);

	@override
	void initState() {
		super.initState();
		final now = DateTime.now();
		_desde = DateTime(now.year, now.month, 1);
		_hasta = DateTime(now.year, now.month + 1, 0);
		WidgetsBinding.instance.addPostFrameCallback((_) {
			final q = GoRouterState.of(context).uri.queryParameters;
			_misOt = q['misOt'] == 'true' || q['misOt'] == '1';
			final desdeQ = q['fechaDesde'];
			final hastaQ = q['fechaHasta'];
			final agrupar = q['agruparPor'];
			if (desdeQ != null) {
				final p = DateTime.tryParse(desdeQ);
				if (p != null) _desde = DateTime(p.year, p.month, p.day);
			}
			if (hastaQ != null) {
				final p = DateTime.tryParse(hastaQ);
				if (p != null) _hasta = DateTime(p.year, p.month, p.day);
			}
			if (agrupar == 'sector' || agrupar == 'equipo') _agruparPor = agrupar!;
			_load();
		});
	}

	Future<void> _pickRange() async {
		final picked = await showDateRangePicker(
			context: context,
			firstDate: DateTime(2020),
			lastDate: DateTime.now().add(const Duration(days: 365)),
			initialDateRange: DateTimeRange(start: _desde, end: _hasta),
			helpText: 'Período del Gantt',
			cancelText: 'Cancelar',
			confirmText: 'Aplicar',
			saveText: 'Aplicar',
		);
		if (picked == null) return;
		setState(() {
			_desde = DateTime(picked.start.year, picked.start.month, picked.start.day);
			_hasta = DateTime(picked.end.year, picked.end.month, picked.end.day);
		});
		await _load();
	}

	Future<void> _load() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final df = DateFormat('yyyy-MM-dd');
			final mis = _misOt ? '&misOt=true' : '';
			final data = await ref.read(apiClientProvider).getJson(
						'ot/gantt?fechaDesde=${df.format(_desde)}'
						'&fechaHasta=${df.format(_hasta)}'
						'&agruparPor=$_agruparPor$mis',
					);
			_dias = (data['dias'] is List)
					? (data['dias'] as List).map((e) => '$e').toList()
					: <String>[];
			_filas = (data['filas'] is List)
					? (data['filas'] as List)
							.whereType<Map>()
							.map((e) => Map<String, dynamic>.from(e))
							.toList()
					: <Map<String, dynamic>>[];
			_totales = data['totalesGenerales'] is Map
					? Map<String, dynamic>.from(data['totalesGenerales'] as Map)
					: {};
		} catch (e) {
			_error = e.toString();
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	Map<String, dynamic> _celda(Map<String, dynamic> fila, String dia) {
		final celdas = fila['celdas'];
		if (celdas is! Map) return const {};
		final raw = celdas[dia];
		return raw is Map ? Map<String, dynamic>.from(raw) : const {};
	}

	int _n(dynamic v) {
		if (v is int) return v;
		if (v is num) return v.toInt();
		return 0;
	}

	bool _isWeekend(String iso) {
		final d = DateTime.tryParse(iso);
		if (d == null) return false;
		return d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final chartWidth = _dias.length * _dayWidth;
		final monthLabel = DateFormat('MMMM yyyy').format(_desde);
		final dfTitle = DateFormat('dd/MM/yyyy');

		return Scaffold(
			backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF4F6F8),
			appBar: AppBar(
				automaticallyImplyLeading: false,
				leading: const ShellBackButton(),
				title: Text(_misOt ? 'Gantt · Mis OT' : 'Diagrama de Gantt de O.T.'),
				actions: [
					IconButton(
						tooltip: 'Período',
						onPressed: _loading ? null : _pickRange,
						icon: const Icon(Icons.date_range_rounded),
					),
					IconButton(
						tooltip: 'Actualizar',
						onPressed: _loading ? null : _load,
						icon: const Icon(Icons.refresh_rounded),
					),
				],
			),
			body: _loading
					? const Center(child: CircularProgressIndicator())
					: _error != null
							? Center(child: Text(_error!))
							: Column(
									children: [
										_Toolbar(
											periodo:
													'${dfTitle.format(_desde)} — ${dfTitle.format(_hasta)}',
											mesLabel: monthLabel,
											agruparPor: _agruparPor,
											showAgrupar: !_misOt,
											onPickRange: _pickRange,
											onAgrupar: (v) {
												setState(() => _agruparPor = v);
												_load();
											},
											pendientes: _n(_totales['pendientes']),
											enEjecucion: _n(_totales['enEjecucion']),
											realizadas: _n(_totales['realizadas']),
										),
										Expanded(
											child: _filas.isEmpty
													? const Center(child: Text('Sin OT en el período'))
													: LayoutBuilder(
															builder: (context, constraints) {
																return Scrollbar(
																	child: SingleChildScrollView(
																		scrollDirection: Axis.horizontal,
																		child: SizedBox(
																			width: (_labelWidth + chartWidth)
																					.clamp(constraints.maxWidth, double.infinity),
																			height: constraints.maxHeight,
																			child: Column(
																				children: [
																					_DayHeader(
																						labelWidth: _labelWidth,
																						dayWidth: _dayWidth,
																						headerHeight: _headerHeight,
																						dias: _dias,
																						isWeekend: _isWeekend,
																						weekendBand: isDark
																								? const Color(0xFF243447)
																								: _weekendBand,
																					),
																					Expanded(
																						child: ListView.builder(
																							itemCount: _filas.length,
																							itemExtent: _rowHeight,
																							itemBuilder: (context, index) {
																								final fila = _filas[index];
																								return _GanttRow(
																									label: '${fila['label'] ?? ''}',
																									labelWidth: _labelWidth,
																									dayWidth: _dayWidth,
																									rowHeight: _rowHeight,
																									dias: _dias,
																									zebra: index.isOdd,
																									isWeekend: _isWeekend,
																									weekendBand: isDark
																											? const Color(0xFF243447)
																											: _weekendBand,
																									celdaFor: (dia) => _celda(fila, dia),
																									countOf: _n,
																								);
																							},
																						),
																					),
																				],
																			),
																		),
																	),
																);
															},
														),
										),
										Container(
											width: double.infinity,
											padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
											decoration: BoxDecoration(
												color: scheme.surface,
												border: Border(
													top: BorderSide(color: scheme.outlineVariant),
												),
											),
											child: Text(
												'${_filas.length} equipos · ${_n(_totales['total'])} OT',
												style: TextStyle(
													fontSize: 12,
													color: scheme.onSurface.withValues(alpha: 0.6),
													fontWeight: FontWeight.w600,
												),
											),
										),
									],
								),
		);
	}
}

class _Toolbar extends StatelessWidget {
	const _Toolbar({
		required this.periodo,
		required this.mesLabel,
		required this.agruparPor,
		required this.showAgrupar,
		required this.onPickRange,
		required this.onAgrupar,
		required this.pendientes,
		required this.enEjecucion,
		required this.realizadas,
	});

	final String periodo;
	final String mesLabel;
	final String agruparPor;
	final bool showAgrupar;
	final VoidCallback onPickRange;
	final ValueChanged<String> onAgrupar;
	final int pendientes;
	final int enEjecucion;
	final int realizadas;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return Material(
			color: scheme.surface,
			child: Padding(
				padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
				child: Wrap(
					spacing: 10,
					runSpacing: 8,
					crossAxisAlignment: WrapCrossAlignment.center,
					children: [
						Material(
							color: AppColors.brandPurple.withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(10),
							child: InkWell(
								onTap: onPickRange,
								borderRadius: BorderRadius.circular(10),
								child: Padding(
									padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
									child: Row(
										mainAxisSize: MainAxisSize.min,
										children: [
											const Icon(
												Icons.calendar_month_rounded,
												size: 18,
												color: AppColors.brandPurple,
											),
											const SizedBox(width: 8),
											Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text(
														mesLabel[0].toUpperCase() + mesLabel.substring(1),
														style: const TextStyle(
															fontWeight: FontWeight.w800,
															fontSize: 13,
														),
													),
													Text(
														periodo,
														style: TextStyle(
															fontSize: 11,
															color: scheme.onSurface.withValues(alpha: 0.55),
														),
													),
												],
											),
										],
									),
								),
							),
						),
						if (showAgrupar)
							SegmentedButton<String>(
								style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
								segments: const [
									ButtonSegment(value: 'equipo', label: Text('Equipo')),
									ButtonSegment(value: 'sector', label: Text('Sector')),
								],
								selected: {agruparPor},
								onSelectionChanged: (s) => onAgrupar(s.first),
							),
						_LegendChip(
							color: _OtGanttPageState._rojoPendiente,
							label: 'Pendiente',
							count: pendientes,
						),
						_LegendChip(
							color: _OtGanttPageState._amarilloEjecucion,
							label: 'En ejecución',
							count: enEjecucion,
						),
						_LegendChip(
							color: _OtGanttPageState._verdeRealizada,
							label: 'Realizada',
							count: realizadas,
						),
					],
				),
			),
		);
	}
}

class _LegendChip extends StatelessWidget {
	const _LegendChip({
		required this.color,
		required this.label,
		required this.count,
	});

	final Color color;
	final String label;
	final int count;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(999),
				border: Border.all(color: color.withValues(alpha: 0.45)),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(
						width: 12,
						height: 12,
						decoration: BoxDecoration(
							color: color,
							borderRadius: BorderRadius.circular(3),
						),
					),
					const SizedBox(width: 6),
					Text(
						'$label $count',
						style: TextStyle(
							fontSize: 12,
							fontWeight: FontWeight.w700,
							color: color,
						),
					),
				],
			),
		);
	}
}

class _DayHeader extends StatelessWidget {
	const _DayHeader({
		required this.labelWidth,
		required this.dayWidth,
		required this.headerHeight,
		required this.dias,
		required this.isWeekend,
		required this.weekendBand,
	});

	final double labelWidth;
	final double dayWidth;
	final double headerHeight;
	final List<String> dias;
	final bool Function(String) isWeekend;
	final Color weekendBand;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
		final monthSpans = <({String label, int count})>[];
		String? currentMonth;
		var count = 0;
		for (final d in dias) {
			final dt = DateTime.tryParse(d);
			final label = dt == null
					? ''
					: DateFormat('MMM').format(dt).toUpperCase();
			if (label != currentMonth) {
				if (currentMonth != null) {
					monthSpans.add((label: currentMonth, count: count));
				}
				currentMonth = label;
				count = 1;
			} else {
				count++;
			}
		}
		if (currentMonth != null) {
			monthSpans.add((label: currentMonth, count: count));
		}

		return Container(
			height: headerHeight,
			decoration: BoxDecoration(
				color: scheme.surface,
				border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
			),
			child: Column(
				children: [
					SizedBox(
						height: 20,
						child: Row(
							children: [
								SizedBox(width: labelWidth),
								...monthSpans.map(
									(m) => Container(
										width: m.count * dayWidth,
										alignment: Alignment.center,
										decoration: BoxDecoration(
											border: Border(
												left: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
											),
										),
										child: Text(
											m.label,
											style: TextStyle(
												fontSize: 10,
												fontWeight: FontWeight.w800,
												letterSpacing: 0.6,
												color: scheme.onSurface.withValues(alpha: 0.55),
											),
										),
									),
								),
							],
						),
					),
					Expanded(
						child: Row(
							children: [
								SizedBox(
									width: labelWidth,
									child: Padding(
										padding: const EdgeInsets.symmetric(horizontal: 12),
										child: Text(
											'Equipo',
											style: TextStyle(
												fontWeight: FontWeight.w800,
												fontSize: 12,
												color: scheme.onSurface.withValues(alpha: 0.7),
											),
										),
									),
								),
								...dias.map((d) {
									final dt = DateTime.tryParse(d);
									final dayNum = dt?.day.toString() ?? d;
									final weekend = isWeekend(d);
									final isToday = d == today;
									return Container(
										width: dayWidth,
										alignment: Alignment.center,
										color: weekend ? weekendBand.withValues(alpha: 0.55) : null,
										child: Text(
											dayNum,
											style: TextStyle(
												fontSize: 11,
												fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
												color: isToday
														? AppColors.brandPurple
														: scheme.onSurface.withValues(alpha: 0.7),
											),
										),
									);
								}),
							],
						),
					),
				],
			),
		);
	}
}

class _GanttRow extends StatelessWidget {
	const _GanttRow({
		required this.label,
		required this.labelWidth,
		required this.dayWidth,
		required this.rowHeight,
		required this.dias,
		required this.zebra,
		required this.isWeekend,
		required this.weekendBand,
		required this.celdaFor,
		required this.countOf,
	});

	final String label;
	final double labelWidth;
	final double dayWidth;
	final double rowHeight;
	final List<String> dias;
	final bool zebra;
	final bool Function(String) isWeekend;
	final Color weekendBand;
	final Map<String, dynamic> Function(String dia) celdaFor;
	final int Function(dynamic) countOf;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final rowBg = zebra
				? scheme.onSurface.withValues(alpha: 0.03)
				: scheme.surface;

		return Container(
			height: rowHeight,
			decoration: BoxDecoration(
				color: rowBg,
				border: Border(
					bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
				),
			),
			child: Row(
				children: [
					SizedBox(
						width: labelWidth,
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 12),
							child: Text(
								label,
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
								style: const TextStyle(
									fontSize: 12,
									fontWeight: FontWeight.w600,
									height: 1.15,
								),
							),
						),
					),
					...dias.map((dia) {
						final c = celdaFor(dia);
						final p = countOf(c['pendientes']);
						final e = countOf(c['enEjecucion']);
						final r = countOf(c['realizadas']);
						final weekend = isWeekend(dia);
						return Container(
							width: dayWidth,
							height: rowHeight,
							color: weekend ? weekendBand.withValues(alpha: 0.35) : null,
							alignment: Alignment.center,
							child: _DayBars(
								pendientes: p,
								enEjecucion: e,
								realizadas: r,
								dia: dia,
							),
						);
					}),
				],
			),
		);
	}
}

class _DayBars extends StatelessWidget {
	const _DayBars({
		required this.pendientes,
		required this.enEjecucion,
		required this.realizadas,
		required this.dia,
	});

	final int pendientes;
	final int enEjecucion;
	final int realizadas;
	final String dia;

	@override
	Widget build(BuildContext context) {
		final total = pendientes + enEjecucion + realizadas;
		if (total == 0) return const SizedBox.shrink();

		final bars = <({Color color, int n, String name})>[
			if (pendientes > 0)
				(
					color: _OtGanttPageState._rojoPendiente,
					n: pendientes,
					name: 'Pendiente',
				),
			if (enEjecucion > 0)
				(
					color: _OtGanttPageState._amarilloEjecucion,
					n: enEjecucion,
					name: 'En ejecución',
				),
			if (realizadas > 0)
				(
					color: _OtGanttPageState._verdeRealizada,
					n: realizadas,
					name: 'Realizada',
				),
		];

		final tip = StringBuffer(dia);
		for (final b in bars) {
			tip.write('\n${b.name}: ${b.n}');
		}

		return Tooltip(
			message: tip.toString(),
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
				child: Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						for (final b in bars)
							for (var i = 0; i < b.n.clamp(1, 3); i++)
								Container(
									width: 7,
									margin: const EdgeInsets.symmetric(horizontal: 1),
									decoration: BoxDecoration(
										color: b.color,
										borderRadius: BorderRadius.circular(3),
										boxShadow: [
											BoxShadow(
												color: b.color.withValues(alpha: 0.35),
												blurRadius: 3,
												offset: const Offset(0, 1),
											),
										],
									),
								),
					],
				),
			),
		);
	}
}
