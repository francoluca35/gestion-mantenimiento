import 'package:excel/excel.dart' hide Border;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/shell_back_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/download_bytes.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';

class OtGraficosPage extends ConsumerStatefulWidget {
	const OtGraficosPage({super.key});

	@override
	ConsumerState<OtGraficosPage> createState() => _OtGraficosPageState();
}

class _OtGraficosPageState extends ConsumerState<OtGraficosPage> {
	bool _loadingCatalog = true;
	bool _loadingChart = false;
	bool _showFiltrosAvanzados = false;
	String? _error;

	late DateTime _desde;
	late DateTime _hasta;

	String _forma = 'barras';
	bool _es3d = false;
	String _ejeY = 'cantidad_ot';
	String _ejeX = 'mes';
	String _agrupado = 'ninguno';
	bool _plantaCompleta = true;
	String? _equipoId;
	String? _sectorResponsableId;
	String? _tipoProcedimiento;
	String? _tipoEquipoId;

	List<Map<String, dynamic>> _equipos = [];
	List<Map<String, dynamic>> _sectores = [];
	List<Map<String, dynamic>> _tiposEquipo = [];

	static const _formas = [
		('barras', 'Barras', Icons.bar_chart_rounded),
		('linea', 'Línea', Icons.show_chart_rounded),
		('torta', 'Torta', Icons.pie_chart_rounded),
	];

	static const _ejesY = [
		('horas_hombre', 'Horas hombre', Icons.timer_outlined),
		('costos', 'Costos', Icons.payments_outlined),
		('indisponibilidad', 'Indisponibilidad', Icons.warning_amber_rounded),
		('cantidad_ot', 'Cantidad OT', Icons.assignment_outlined),
	];

	static const _ejesX = [
		('mes', 'Mes'),
		('responsable', 'Responsable'),
		('tipo_trabajo', 'Tipo de trabajo'),
		('equipos', 'Equipos'),
	];

	static const _agrupados = [
		('mes', 'Mes'),
		('responsable', 'Responsable'),
		('tipo_trabajo', 'Tipo de trabajo'),
		('ninguno', 'No agrupado'),
	];

	static const _tiposProc = [
		('preventivo', 'Preventivo'),
		('preventivo_no_periodico', 'Preventivo no periódico'),
		('predictivo', 'Predictivo'),
		('correctivo', 'Correctivo'),
		('mejora', 'Mejora'),
	];

	String get _tipoGrafico => '${_forma}_${_es3d ? '3d' : '2d'}';

	String get _ejeYLabel =>
			_ejesY.firstWhere((e) => e.$1 == _ejeY, orElse: () => _ejesY.last).$2;

	@override
	void initState() {
		super.initState();
		final now = DateTime.now();
		_desde = DateTime(now.year, now.month, 1);
		_hasta = DateTime(now.year, now.month + 1, 0);
		WidgetsBinding.instance.addPostFrameCallback((_) {
			final q = GoRouterState.of(context).uri.queryParameters;
			final desdeQ = q['fechaDesde'];
			final hastaQ = q['fechaHasta'];
			if (desdeQ != null) {
				final p = DateTime.tryParse(desdeQ);
				if (p != null) _desde = DateTime(p.year, p.month, p.day);
			}
			if (hastaQ != null) {
				final p = DateTime.tryParse(hastaQ);
				if (p != null) _hasta = DateTime(p.year, p.month, p.day);
			}
			final tipoQ = q['tipoGrafico'];
			if (tipoQ != null && tipoQ.contains('_')) {
				final parts = tipoQ.split('_');
				if (parts.length >= 2) {
					_forma = parts.first;
					_es3d = parts.last == '3d';
				}
			}
			_loadCatalog();
		});
	}

	List<Map<String, dynamic>> _flattenUbicaciones(
		List<Map<String, dynamic>> nodes, [
		String prefix = '',
	]) {
		final out = <Map<String, dynamic>>[];
		for (final n in nodes) {
			final nombre = '${n['nombre'] ?? n['codigo'] ?? ''}';
			final label = prefix.isEmpty ? nombre : '$prefix / $nombre';
			out.add({...n, 'label': label});
			final children = n['children'];
			if (children is List) {
				out.addAll(
					_flattenUbicaciones(
						children.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
						label,
					),
				);
			}
		}
		return out;
	}

	Future<void> _loadCatalog() async {
		setState(() {
			_loadingCatalog = true;
			_error = null;
		});
		try {
			final api = ref.read(apiClientProvider);
			final AuthUser? user = ref.read(authControllerProvider).session?.usuario;
			final equipos = (await api.getList('equipos')).cast<Map<String, dynamic>>();
			final tipos = (await api.getList('tipos-equipo')).cast<Map<String, dynamic>>();
			var sectores = <Map<String, dynamic>>[];
			if (user?.sucursalId != null) {
				final tree = await api.getList('ubicaciones/tree?sucursalId=${user!.sucursalId}');
				sectores = _flattenUbicaciones(tree.cast<Map<String, dynamic>>());
			}
			if (!mounted) return;
			setState(() {
				_equipos = equipos;
				_tiposEquipo = tipos;
				_sectores = sectores;
			});
		} catch (e) {
			_error = e.toString();
		} finally {
			if (mounted) setState(() => _loadingCatalog = false);
		}
	}

	Future<void> _pickRango() async {
		final picked = await showDateRangePicker(
			context: context,
			firstDate: DateTime(2020),
			lastDate: DateTime.now().add(const Duration(days: 365)),
			initialDateRange: DateTimeRange(start: _desde, end: _hasta),
		);
		if (picked == null) return;
		setState(() {
			_desde = DateTime(picked.start.year, picked.start.month, picked.start.day);
			_hasta = DateTime(picked.end.year, picked.end.month, picked.end.day);
		});
	}

	Future<void> _graficar() async {
		setState(() {
			_loadingChart = true;
			_error = null;
		});
		try {
			final df = DateFormat('yyyy-MM-dd');
			final body = <String, dynamic>{
				'fechaDesde': df.format(_desde),
				'fechaHasta': df.format(_hasta),
				'ejeY': _ejeY,
				'ejeX': _ejeX,
				'agrupado': _agrupado,
				'tipoGrafico': _tipoGrafico,
				'plantaCompleta': _plantaCompleta,
				if (!_plantaCompleta && _equipoId != null) 'equipoIds': [_equipoId],
				if (_sectorResponsableId != null) 'sectorResponsableId': _sectorResponsableId,
				if (_tipoProcedimiento != null) 'tipoProcedimiento': _tipoProcedimiento,
				if (_tipoEquipoId != null) 'tipoEquipoId': _tipoEquipoId,
			};
			final data = await ref.read(apiClientProvider).postJson('ot/graficos', body);
			if (!mounted) return;
			await _openResultWindow(data);
		} catch (e) {
			if (mounted) setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _loadingChart = false);
		}
	}

	Future<void> _openResultWindow(Map<String, dynamic> data) async {
		final df = DateFormat('dd/MM/yyyy');
		final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

		await showGeneralDialog<void>(
			context: context,
			barrierDismissible: true,
			barrierLabel: 'Cerrar gráfico',
			barrierColor: Colors.black.withValues(alpha: 0.45),
			transitionDuration: const Duration(milliseconds: 280),
			pageBuilder: (ctx, anim, _) {
				return _GraficoResultDialog(
					resultado: data,
					ejeYLabel: _ejeYLabel,
					forma: _forma,
					es3d: _es3d,
					periodoLabel: '${df.format(_desde)} — ${df.format(_hasta)}',
					wide: wide,
					onExport: () => _exportarXls(data),
				);
			},
			transitionBuilder: (ctx, anim, secondary, child) {
				final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
				return FadeTransition(
					opacity: curved,
					child: ScaleTransition(
						scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
						child: child,
					),
				);
			},
		);
	}

	void _exportarXls(Map<String, dynamic> data) {
		final labels = (data['labels'] as List?)?.map((e) => '$e').toList() ?? [];
		final seriesRaw = data['series'];
		final series = seriesRaw is List
				? seriesRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
				: <Map<String, dynamic>>[];

		final excel = Excel.createExcel();
		final sheet = excel['Graficos'];
		excel.setDefaultSheet('Graficos');

		sheet.appendRow([
			TextCellValue('Serie'),
			...labels.map(TextCellValue.new),
		]);
		for (final s in series) {
			final name = '${s['name'] ?? ''}';
			final points = s['points'];
			final byX = <String, num>{};
			if (points is List) {
				for (final p in points.whereType<Map>()) {
					byX['${p['x']}'] = (p['y'] as num?) ?? 0;
				}
			}
			sheet.appendRow([
				TextCellValue(name),
				...labels.map((l) => DoubleCellValue((byX[l] ?? 0).toDouble())),
			]);
		}

		final bytes = excel.encode();
		if (bytes == null) return;
		final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
		downloadBytesFile(
			'graficos_ot_$stamp.xlsx',
			bytes,
			'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
		);
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final df = DateFormat('dd/MM/yyyy');
		final pageBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
		final cardBg = isDark ? AppColors.cardDark : AppColors.white;
		final border = isDark ? AppColors.cardBorder : const Color(0xFFE8E0F0);
		final fg = isDark ? Colors.white : AppColors.ink;
		final muted = isDark
				? Colors.white.withValues(alpha: 0.6)
				: AppColors.ink.withValues(alpha: 0.55);

		return Scaffold(
			backgroundColor: pageBg,
			appBar: AppBar(
				automaticallyImplyLeading: false,
				backgroundColor: pageBg,
				surfaceTintColor: Colors.transparent,
				leading: ShellBackButton(color: fg),
				title: Text('Gráficos', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
			),
			body: _loadingCatalog
					? const Center(child: CircularProgressIndicator())
					: LayoutBuilder(
							builder: (context, constraints) {
								final wide = constraints.maxWidth >= Breakpoints.tablet;
								final pad = wide ? 32.0 : 16.0;

								final tipoCard = _SectionCard(
									bg: cardBg,
									border: border,
									title: 'Visualización',
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.stretch,
										children: [
											Text('Tipo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: muted)),
											const SizedBox(height: 10),
											Wrap(
												spacing: 8,
												runSpacing: 8,
												children: [
													for (final f in _formas)
														_ChoicePill(
															label: f.$2,
															icon: f.$3,
															selected: _forma == f.$1,
															onTap: () => setState(() => _forma = f.$1),
														),
													_ChoicePill(
														label: _es3d ? '3D' : '2D',
														icon: Icons.layers_rounded,
														selected: _es3d,
														onTap: () => setState(() => _es3d = !_es3d),
													),
												],
											),
											const SizedBox(height: 18),
											Text('Métrica', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: muted)),
											const SizedBox(height: 10),
											Wrap(
												spacing: 8,
												runSpacing: 8,
												children: [
													for (final m in _ejesY)
														_ChoicePill(
															label: m.$2,
															icon: m.$3,
															selected: _ejeY == m.$1,
															onTap: () => setState(() => _ejeY = m.$1),
														),
												],
											),
											const SizedBox(height: 16),
											InkWell(
												onTap: _pickRango,
												borderRadius: BorderRadius.circular(12),
												child: Container(
													padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
													decoration: BoxDecoration(
														color: AppColors.brandPurple.withValues(alpha: isDark ? 0.16 : 0.08),
														borderRadius: BorderRadius.circular(12),
														border: Border.all(
															color: AppColors.brandPurple.withValues(alpha: 0.25),
														),
													),
													child: Row(
														children: [
															const Icon(Icons.date_range_rounded, color: AppColors.brandPurple, size: 20),
															const SizedBox(width: 10),
															Expanded(
																child: Text(
																	'${df.format(_desde)} — ${df.format(_hasta)}',
																	style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14),
																),
															),
															Icon(Icons.edit_calendar_rounded, size: 18, color: muted),
														],
													),
												),
											),
										],
									),
								);

								final agrupacionCard = _SectionCard(
									bg: cardBg,
									border: border,
									title: 'Agrupación y filtros',
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.stretch,
										children: [
											if (wide)
												Row(
													children: [
														Expanded(
															child: DropdownButtonFormField<String>(
																value: _ejeX,
																isExpanded: true,
																decoration: _fieldDecoration(context, 'Eje X'),
																items: _ejesX
																		.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
																		.toList(),
																onChanged: (v) => setState(() => _ejeX = v ?? _ejeX),
															),
														),
														const SizedBox(width: 12),
														Expanded(
															child: DropdownButtonFormField<String>(
																value: _agrupado,
																isExpanded: true,
																decoration: _fieldDecoration(context, 'Agrupado'),
																items: _agrupados
																		.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
																		.toList(),
																onChanged: (v) => setState(() => _agrupado = v ?? _agrupado),
															),
														),
													],
												)
											else ...[
												DropdownButtonFormField<String>(
													value: _ejeX,
													isExpanded: true,
													decoration: _fieldDecoration(context, 'Eje X'),
													items: _ejesX
															.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
															.toList(),
													onChanged: (v) => setState(() => _ejeX = v ?? _ejeX),
												),
												const SizedBox(height: 10),
												DropdownButtonFormField<String>(
													value: _agrupado,
													isExpanded: true,
													decoration: _fieldDecoration(context, 'Agrupado'),
													items: _agrupados
															.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
															.toList(),
													onChanged: (v) => setState(() => _agrupado = v ?? _agrupado),
												),
											],
											const SizedBox(height: 8),
											Align(
												alignment: Alignment.centerLeft,
												child: TextButton.icon(
													onPressed: () => setState(() => _showFiltrosAvanzados = !_showFiltrosAvanzados),
													icon: Icon(
														_showFiltrosAvanzados ? Icons.expand_less_rounded : Icons.tune_rounded,
														size: 18,
													),
													label: Text(_showFiltrosAvanzados ? 'Ocultar filtros' : 'Filtros avanzados'),
												),
											),
											if (_showFiltrosAvanzados) ...[
												SwitchListTile(
													contentPadding: EdgeInsets.zero,
													title: const Text('Planta completa', style: TextStyle(fontSize: 14)),
													value: _plantaCompleta,
													onChanged: (v) => setState(() {
														_plantaCompleta = v;
														if (v) _equipoId = null;
													}),
												),
												if (!_plantaCompleta) ...[
													DropdownButtonFormField<String?>(
														value: _equipoId,
														isExpanded: true,
														decoration: _fieldDecoration(context, 'Equipo'),
														items: [
															const DropdownMenuItem(value: null, child: Text('—')),
															..._equipos.map(
																(e) => DropdownMenuItem(
																	value: e['id'] as String?,
																	child: Text(
																		'${e['codigo'] ?? ''} · ${e['nombre'] ?? ''}',
																		overflow: TextOverflow.ellipsis,
																	),
																),
															),
														],
														onChanged: (v) => setState(() => _equipoId = v),
													),
													const SizedBox(height: 10),
												],
												DropdownButtonFormField<String?>(
													value: _sectorResponsableId,
													isExpanded: true,
													decoration: _fieldDecoration(context, 'Sector responsable'),
													items: [
														const DropdownMenuItem(value: null, child: Text('Todos')),
														..._sectores.map(
															(s) => DropdownMenuItem(
																value: s['id'] as String?,
																child: Text(
																	'${s['label'] ?? s['nombre'] ?? ''}',
																	overflow: TextOverflow.ellipsis,
																),
															),
														),
													],
													onChanged: (v) => setState(() => _sectorResponsableId = v),
												),
												const SizedBox(height: 10),
												DropdownButtonFormField<String?>(
													value: _tipoProcedimiento,
													isExpanded: true,
													decoration: _fieldDecoration(context, 'Tipo procedimiento'),
													items: [
														const DropdownMenuItem(value: null, child: Text('Todos')),
														..._tiposProc.map(
															(e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
														),
													],
													onChanged: (v) => setState(() => _tipoProcedimiento = v),
												),
												const SizedBox(height: 10),
												DropdownButtonFormField<String?>(
													value: _tipoEquipoId,
													isExpanded: true,
													decoration: _fieldDecoration(context, 'Tipo equipo'),
													items: [
														const DropdownMenuItem(value: null, child: Text('Todos')),
														..._tiposEquipo.map(
															(t) => DropdownMenuItem(
																value: t['id'] as String?,
																child: Text('${t['nombre'] ?? t['codigo'] ?? ''}'),
															),
														),
													],
													onChanged: (v) => setState(() => _tipoEquipoId = v),
												),
											],
										],
									),
								);

								final actions = Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										FilledButton.icon(
											style: FilledButton.styleFrom(
												backgroundColor: AppColors.accent,
												padding: const EdgeInsets.symmetric(vertical: 16),
												shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
											),
											onPressed: _loadingChart ? null : _graficar,
											icon: _loadingChart
													? const SizedBox(
															width: 18,
															height: 18,
															child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
														)
													: const Icon(Icons.auto_graph_rounded),
											label: Text(
												_loadingChart ? 'Generando…' : 'Graficar',
												style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
											),
										),
										if (_error != null) ...[
											const SizedBox(height: 12),
											Text(_error!, style: TextStyle(color: scheme.error)),
										],
										const SizedBox(height: 20),
										Container(
											padding: const EdgeInsets.all(16),
											decoration: BoxDecoration(
												color: cardBg,
												borderRadius: BorderRadius.circular(16),
												border: Border.all(color: border),
											),
											child: Row(
												children: [
													Icon(Icons.info_outline_rounded, color: muted, size: 20),
													const SizedBox(width: 10),
													Expanded(
														child: Text(
															wide
																	? 'Al graficar se abre una ventana con el resultado, KPIs y exportación.'
																	: 'Al graficar se abre el resultado a pantalla completa.',
															style: TextStyle(color: muted, fontSize: 13, height: 1.35),
														),
													),
												],
											),
										),
									],
								);

								if (wide) {
									return SingleChildScrollView(
										padding: EdgeInsets.fromLTRB(pad, 12, pad, 40),
										child: ConstrainedBox(
											constraints: const BoxConstraints(maxWidth: 1100),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.stretch,
												children: [
													Text(
														'Configurá el gráfico y abrí el resultado en una ventana aparte.',
														style: TextStyle(color: muted, fontSize: 14),
													),
													const SizedBox(height: 20),
													Row(
														crossAxisAlignment: CrossAxisAlignment.start,
														children: [
															Expanded(flex: 5, child: tipoCard),
															const SizedBox(width: 16),
															Expanded(flex: 5, child: agrupacionCard),
														],
													),
													const SizedBox(height: 20),
													Align(
														alignment: Alignment.centerLeft,
														child: SizedBox(width: 280, child: actions),
													),
												],
											),
										),
									);
								}

								return ListView(
									padding: EdgeInsets.fromLTRB(pad, 8, pad, 32),
									children: [
										tipoCard,
										const SizedBox(height: 12),
										agrupacionCard,
										const SizedBox(height: 16),
										actions,
									],
								);
							},
						),
		);
	}

	InputDecoration _fieldDecoration(BuildContext context, String label) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		return InputDecoration(
			labelText: label,
			isDense: true,
			filled: true,
			fillColor: isDark ? AppColors.cardElevated : AppColors.surfaceMuted,
			border: OutlineInputBorder(
				borderRadius: BorderRadius.circular(10),
				borderSide: BorderSide(
					color: isDark ? AppColors.cardBorder : const Color(0xFFE8E0F0),
				),
			),
			enabledBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(10),
				borderSide: BorderSide(
					color: isDark ? AppColors.cardBorder : const Color(0xFFE8E0F0),
				),
			),
		);
	}
}

class _GraficoResultDialog extends StatelessWidget {
	const _GraficoResultDialog({
		required this.resultado,
		required this.ejeYLabel,
		required this.forma,
		required this.es3d,
		required this.periodoLabel,
		required this.wide,
		required this.onExport,
	});

	final Map<String, dynamic> resultado;
	final String ejeYLabel;
	final String forma;
	final bool es3d;
	final String periodoLabel;
	final bool wide;
	final VoidCallback onExport;

	bool get _esTorta => forma == 'torta';
	bool get _esLinea => forma == 'linea';

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final scheme = Theme.of(context).colorScheme;
		final bg = isDark ? AppColors.cardDark : AppColors.white;
		final pageBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
		final border = isDark ? AppColors.cardBorder : const Color(0xFFE8E0F0);
		final fg = isDark ? Colors.white : AppColors.ink;
		final muted = isDark
				? Colors.white.withValues(alpha: 0.6)
				: AppColors.ink.withValues(alpha: 0.55);

		final content = Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Padding(
					padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 16, 8, 8),
					child: Row(
						children: [
							Container(
								width: 40,
								height: 40,
								decoration: BoxDecoration(
									color: AppColors.accent.withValues(alpha: 0.12),
									borderRadius: BorderRadius.circular(12),
								),
								child: const Icon(Icons.auto_graph_rounded, color: AppColors.accent),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'Resultado',
											style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: fg),
										),
										Text(
											'$periodoLabel · ${es3d ? '3D' : '2D'}',
											style: TextStyle(fontSize: 12, color: muted),
										),
									],
								),
							),
							IconButton(
								tooltip: 'Exportar XLS',
								onPressed: onExport,
								icon: Icon(Icons.grid_on_rounded, color: fg),
							),
							IconButton(
								tooltip: 'Cerrar',
								onPressed: () => Navigator.of(context).pop(),
								icon: Icon(Icons.close_rounded, color: fg),
							),
						],
					),
				),
				Divider(height: 1, color: border),
				Expanded(
					child: ListView(
						padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 16, wide ? 24 : 16, 24),
						children: [
							Row(
								children: [
									Expanded(
										child: _KpiTile(
											label: ejeYLabel,
											value: '${resultado['total'] ?? 0}',
											icon: Icons.analytics_outlined,
											bg: isDark ? AppColors.cardElevated : AppColors.surfaceMuted,
											border: border,
											fg: fg,
											muted: muted,
										),
									),
									const SizedBox(width: 10),
									Expanded(
										child: _KpiTile(
											label: 'Órdenes',
											value: '${resultado['cantidadOt'] ?? 0}',
											icon: Icons.assignment_outlined,
											bg: isDark ? AppColors.cardElevated : AppColors.surfaceMuted,
											border: border,
											fg: fg,
											muted: muted,
										),
									),
								],
							),
							const SizedBox(height: 16),
							Container(
								padding: const EdgeInsets.all(16),
								decoration: BoxDecoration(
									color: isDark ? AppColors.cardElevated : AppColors.surfaceMuted,
									borderRadius: BorderRadius.circular(16),
									border: Border.all(color: border),
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										SizedBox(
											height: wide ? 420 : 320,
											child: _buildChart(scheme, fg, muted),
										),
										const SizedBox(height: 14),
										_buildLegend(fg),
									],
								),
							),
							const SizedBox(height: 16),
							Align(
								alignment: Alignment.centerRight,
								child: FilledButton.icon(
									style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
									onPressed: onExport,
									icon: const Icon(Icons.file_download_outlined),
									label: const Text('Exportar XLS'),
								),
							),
						],
					),
				),
			],
		);

		if (!wide) {
			return Material(
				color: pageBg,
				child: SafeArea(child: content),
			);
		}

		return Center(
			child: ConstrainedBox(
				constraints: BoxConstraints(
					maxWidth: 980,
					maxHeight: MediaQuery.sizeOf(context).height * 0.88,
					minWidth: 720,
				),
				child: Material(
					color: bg,
					elevation: 12,
					shadowColor: Colors.black.withValues(alpha: 0.25),
					borderRadius: BorderRadius.circular(20),
					clipBehavior: Clip.antiAlias,
					child: content,
				),
			),
		);
	}

	Widget _buildLegend(Color fg) {
		final series = (resultado['series'] as List?)
						?.whereType<Map>()
						.map((e) => Map<String, dynamic>.from(e))
						.toList() ??
				[];
		return Wrap(
			spacing: 8,
			runSpacing: 8,
			children: [
				for (var i = 0; i < series.length; i++)
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
						decoration: BoxDecoration(
							color: _palette(i).withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(999),
						),
						child: Row(
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(
									width: 8,
									height: 8,
									decoration: BoxDecoration(color: _palette(i), shape: BoxShape.circle),
								),
								const SizedBox(width: 6),
								Text(
									'${series[i]['name']}',
									style: TextStyle(
										fontSize: 12,
										fontWeight: FontWeight.w600,
										color: fg.withValues(alpha: 0.8),
									),
								),
							],
						),
					),
			],
		);
	}

	Color _palette(int i) {
		const colors = [
			AppColors.accent,
			AppColors.brandPurple,
			AppColors.brandGreen,
			AppColors.brandOrange,
			Color(0xFF00B4D8),
			Color(0xFFE63946),
			Color(0xFFFF8A1A),
		];
		return colors[i % colors.length];
	}

	double _pointY(Map<String, dynamic> serie, String label) {
		final points = serie['points'];
		if (points is! List) return 0;
		for (final p in points.whereType<Map>()) {
			if ('${p['x']}' == label) return (p['y'] as num?)?.toDouble() ?? 0;
		}
		return 0;
	}

	Widget _buildChart(ColorScheme scheme, Color fg, Color muted) {
		final labels = (resultado['labels'] as List?)?.map((e) => '$e').toList() ?? [];
		final series = (resultado['series'] as List?)
						?.whereType<Map>()
						.map((e) => Map<String, dynamic>.from(e))
						.toList() ??
				[];
		if (labels.isEmpty || series.isEmpty) {
			return Center(child: Text('Sin datos para graficar', style: TextStyle(color: muted)));
		}

		final axisStyle = TextStyle(fontSize: 10, color: muted);

		if (_esTorta) {
			final first = series.first;
			final points = (first['points'] as List?)?.whereType<Map>().toList() ?? [];
			final sections = <PieChartSectionData>[];
			for (var i = 0; i < points.length; i++) {
				final y = (points[i]['y'] as num?)?.toDouble() ?? 0;
				if (y <= 0) continue;
				sections.add(
					PieChartSectionData(
						value: y,
						title: y >= 1 ? y.toStringAsFixed(y == y.roundToDouble() ? 0 : 1) : '',
						color: _palette(i),
						radius: es3d ? 92 : 80,
						titleStyle: const TextStyle(
							fontSize: 11,
							fontWeight: FontWeight.w700,
							color: Colors.white,
						),
					),
				);
			}
			return PieChart(
				PieChartData(
					sectionsSpace: 2,
					centerSpaceRadius: es3d ? 24 : 38,
					sections: sections.isEmpty
							? [
									PieChartSectionData(
										value: 1,
										color: scheme.outline.withValues(alpha: 0.2),
										title: '',
									),
								]
							: sections,
				),
			);
		}

		if (_esLinea) {
			return LineChart(
				LineChartData(
					gridData: FlGridData(
						show: true,
						drawVerticalLine: false,
						getDrawingHorizontalLine: (v) => FlLine(
							color: muted.withValues(alpha: 0.2),
							strokeWidth: 1,
						),
					),
					borderData: FlBorderData(show: false),
					titlesData: FlTitlesData(
						topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
						rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
						leftTitles: AxisTitles(
							sideTitles: SideTitles(
								showTitles: true,
								reservedSize: 36,
								getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: axisStyle),
							),
						),
						bottomTitles: AxisTitles(
							sideTitles: SideTitles(
								showTitles: true,
								reservedSize: 28,
								getTitlesWidget: (value, meta) {
									final i = value.toInt();
									if (i < 0 || i >= labels.length) return const SizedBox.shrink();
									return Padding(
										padding: const EdgeInsets.only(top: 6),
										child: Text(labels[i], style: axisStyle, overflow: TextOverflow.ellipsis),
									);
								},
							),
						),
					),
					lineBarsData: [
						for (var s = 0; s < series.length; s++)
							LineChartBarData(
								isCurved: true,
								barWidth: es3d ? 4 : 3,
								color: _palette(s),
								dotData: const FlDotData(show: true),
								belowBarData: BarAreaData(
									show: true,
									color: _palette(s).withValues(alpha: 0.08),
								),
								spots: [
									for (var i = 0; i < labels.length; i++)
										FlSpot(i.toDouble(), _pointY(series[s], labels[i])),
								],
							),
					],
				),
			);
		}

		return BarChart(
			BarChartData(
				gridData: FlGridData(
					show: true,
					drawVerticalLine: false,
					getDrawingHorizontalLine: (v) => FlLine(
						color: muted.withValues(alpha: 0.2),
						strokeWidth: 1,
					),
				),
				borderData: FlBorderData(show: false),
				titlesData: FlTitlesData(
					topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
					rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
					leftTitles: AxisTitles(
						sideTitles: SideTitles(
							showTitles: true,
							reservedSize: 36,
							getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: axisStyle),
						),
					),
					bottomTitles: AxisTitles(
						sideTitles: SideTitles(
							showTitles: true,
							reservedSize: 28,
							getTitlesWidget: (value, meta) {
								final i = value.toInt();
								if (i < 0 || i >= labels.length) return const SizedBox.shrink();
								return Padding(
									padding: const EdgeInsets.only(top: 6),
									child: Text(labels[i], style: axisStyle, overflow: TextOverflow.ellipsis),
								);
							},
						),
					),
				),
				barGroups: [
					for (var i = 0; i < labels.length; i++)
						BarChartGroupData(
							x: i,
							barsSpace: 3,
							barRods: [
								for (var s = 0; s < series.length; s++)
									BarChartRodData(
										toY: _pointY(series[s], labels[i]),
										width: es3d ? 14 : 11,
										borderRadius: BorderRadius.circular(es3d ? 2 : 6),
										color: _palette(s),
										backDrawRodData: es3d
												? BackgroundBarChartRodData(
														show: true,
														toY: _pointY(series[s], labels[i]) * 1.02,
														color: _palette(s).withValues(alpha: 0.22),
													)
												: BackgroundBarChartRodData(show: false),
									),
							],
						),
				],
			),
		);
	}
}

class _SectionCard extends StatelessWidget {
	const _SectionCard({
		required this.child,
		required this.bg,
		required this.border,
		required this.title,
	});

	final Widget child;
	final Color bg;
	final Color border;
	final String title;

	@override
	Widget build(BuildContext context) {
		final fg = Theme.of(context).colorScheme.onSurface;
		return Container(
			padding: const EdgeInsets.all(18),
			decoration: BoxDecoration(
				color: bg,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Text(
						title,
						style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: fg),
					),
					const SizedBox(height: 14),
					child,
				],
			),
		);
	}
}

class _ChoicePill extends StatelessWidget {
	const _ChoicePill({
		required this.label,
		required this.icon,
		required this.selected,
		required this.onTap,
	});

	final String label;
	final IconData icon;
	final bool selected;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final bg = selected
				? AppColors.accent.withValues(alpha: isDark ? 0.22 : 0.12)
				: (isDark ? AppColors.cardElevated : AppColors.surfaceMuted);
		final fg = selected
				? AppColors.accent
				: (isDark ? Colors.white70 : AppColors.ink.withValues(alpha: 0.7));

		return Material(
			color: bg,
			borderRadius: BorderRadius.circular(999),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(999),
				child: Container(
					padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(999),
						border: Border.all(
							color: selected
									? AppColors.accent.withValues(alpha: 0.45)
									: (isDark ? AppColors.cardBorder : const Color(0xFFE8E0F0)),
						),
					),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							Icon(icon, size: 16, color: fg),
							const SizedBox(width: 6),
							Text(
								label,
								style: TextStyle(
									color: fg,
									fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
									fontSize: 13,
								),
							),
						],
					),
				),
			),
		);
	}
}

class _KpiTile extends StatelessWidget {
	const _KpiTile({
		required this.label,
		required this.value,
		required this.icon,
		required this.bg,
		required this.border,
		required this.fg,
		required this.muted,
	});

	final String label;
	final String value;
	final IconData icon;
	final Color bg;
	final Color border;
	final Color fg;
	final Color muted;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: bg,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: border),
			),
			child: Row(
				children: [
					Container(
						width: 40,
						height: 40,
						decoration: BoxDecoration(
							color: AppColors.accent.withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(10),
						),
						child: Icon(icon, color: AppColors.accent, size: 20),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(label, style: TextStyle(fontSize: 12, color: muted)),
								const SizedBox(height: 2),
								Text(
									value,
									style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg),
								),
							],
						),
					),
				],
			),
		);
	}
}
