import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../components/sika_ui.dart';
import '../../../core/config/app_config.dart';
import '../../../core/layout/collapsible_panel.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../planta/presentation/planta_map_panel.dart';
import 'ot_ejecucion_sheet.dart';
import 'ot_export.dart';
import 'ot_firma_sheet.dart';
import 'ot_list_toolbar.dart';
import 'ot_motivo_pendiente_dialog.dart';
import 'ot_pdf.dart';
import 'ot_print.dart';
import 'ot_ui.dart';
import '../../panol/presentation/solicitar_materiales_sheet.dart';

enum OtModo { buscar, necesarias }

class OtPage extends ConsumerStatefulWidget {
	const OtPage({
		super.key,
		this.modo = OtModo.buscar,
		this.misOtOnly = false,
		this.numeroInicial,
	});

	final OtModo modo;
	final bool misOtOnly;

	/// Si viene (p. ej. deep-link FCM), selecciona esa OT tras cargar.
	final String? numeroInicial;

	@override
	ConsumerState<OtPage> createState() => _OtPageState();
}

class _OtPageState extends ConsumerState<OtPage> {
	static final _dateFormat = DateFormat('dd/MM/yyyy');

	static const _listExpandedWidth = 360.0;
	static const _listCollapsedWidth = 56.0;
	static const _mapExpandedWidth = 300.0;
	static const _mapCollapsedWidth = 0.0;

	List<Map<String, dynamic>> _ordenes = [];
	List<Map<String, dynamic>> _tecnicos = [];
	Map<String, dynamic>? _selected;
	Map<String, dynamic>? _resumen;
	String? _filtroEstado;
	String? _filtroTipo;
	String? _filtroTecnicoId;
	String? _filtroPrioridad;
	String? _filtroSectorId;
	String? _filtroMotivoId;
	String? _filtroTipoEquipoId;
	String _filtroNumero = '';
	List<Map<String, dynamic>> _tiposEquipo = [];
	List<Map<String, dynamic>> _sectores = [];
	List<Map<String, dynamic>> _motivos = [];
	final Set<String> _checkedIds = {};
	bool _batchBusy = false;
	late DateTime _fechaDesde;
	late DateTime _fechaHasta;
	String _search = '';
	bool _loading = true;
	bool _loadingDetail = false;
	bool _showFiltros = false;
	bool _showMapaMobile = false;
	String? _error;
	PlantaMapSelection? _mapSelection;
	String? _mapFiltroEquipoId;
	String? _mapFiltroUbicacionId;
	String? _highlightEquipoId;
	bool _listCollapsed = false;
	bool _mapCollapsed = false;

	static (DateTime, DateTime) _rangoMesActual() {
		final now = DateTime.now();
		final desde = now.subtract(const Duration(days: 90));
		return (
			DateTime(desde.year, desde.month, desde.day),
			DateTime(now.year, now.month + 1, 0),
		);
	}

	/// Técnico: ventana amplia para no “perder” OT abiertas fuera del mes.
	static (DateTime, DateTime) _rangoMisOt() {
		final now = DateTime.now();
		final desde = now.subtract(const Duration(days: 365));
		final hasta = now.add(const Duration(days: 60));
		return (
			DateTime(desde.year, desde.month, desde.day),
			DateTime(hasta.year, hasta.month, hasta.day),
		);
	}

	AuthUser? get _user => ref.read(authControllerProvider).session?.usuario;

	bool get _canAnular =>
			_user?.tieneDerecho('programacion.ordenes_trabajo.anular') == true ||
			_user?.esAdministrador == true;

	bool get _canReabrir =>
			_user?.tieneDerecho('programacion.ordenes_trabajo.reabrir') == true ||
			_user?.esAdministrador == true ||
			_user?.supervisaSucursales == true;

	bool get _canEmitirNoPeriodica =>
			_user?.tieneDerecho('programacion.ordenes_trabajo.emitir_no_periodica') == true ||
			_user?.esAdministrador == true;

	bool get _canSolicitarMateriales =>
			_user?.tieneDerecho('stock.pañol.solicitudes_materiales.solicitar') == true ||
			_user?.esAdministrador == true;

	bool get _canManage =>
			_user?.tieneDerecho('programacion.ordenes_trabajo.buscar_y_actualizar') == true;

	bool _puedeEjecutarOt(Map<String, dynamic> ot) {
		final estado = ot['estado'] as String?;
		if (!['pendiente', 'en_ejecucion'].contains(estado)) return false;
		if (_user?.esAdministrador == true || _user?.supervisaSucursales == true) {
			return true;
		}
		final tecnicoId =
				ot['tecnicoAsignado']?['id'] as String? ?? ot['tecnicoAsignadoId'] as String?;
		return tecnicoId != null && tecnicoId == _user?.id;
	}

	@override
	void initState() {
		super.initState();
		final (desde, hasta) =
				widget.misOtOnly ? _rangoMisOt() : _rangoMesActual();
		_fechaDesde = desde;
		_fechaHasta = hasta;
		if (widget.modo == OtModo.necesarias) {
			_filtroEstado = 'necesaria_de_emitir';
			_showFiltros = true;
		}
		if (widget.misOtOnly) {
			_filtroEstado = null; // muestra abiertas + cerradas del rango
		}
		WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
	}

	String get _tituloListado => widget.misOtOnly
			? 'Mis órdenes de trabajo'
			: widget.modo == OtModo.necesarias
					? 'OT necesarias de emitir'
					: 'Órdenes de trabajo';

	String _toApiDate(DateTime date) {
		return '${date.year.toString().padLeft(4, '0')}-'
				'${date.month.toString().padLeft(2, '0')}-'
				'${date.day.toString().padLeft(2, '0')}';
	}

	String _buildOtQuery() {
		final params = <String>[
			'fechaDesde=${_toApiDate(_fechaDesde)}',
			'fechaHasta=${_toApiDate(_fechaHasta)}',
		];
		if (_filtroTipo != null) params.add('tipo=$_filtroTipo');
		if (_filtroTecnicoId != null) params.add('tecnicoId=$_filtroTecnicoId');
		if (_filtroEstado != null) params.add('estado=$_filtroEstado');
		if (_filtroPrioridad != null) params.add('prioridad=$_filtroPrioridad');
		if (_filtroSectorId != null) {
			params.add('sectorResponsableId=$_filtroSectorId');
		}
		if (_filtroMotivoId != null) {
			params.add('motivoPendienteId=$_filtroMotivoId');
		}
		if (_filtroTipoEquipoId != null) {
			params.add('tipoEquipoId=$_filtroTipoEquipoId');
		}
		if (_filtroNumero.trim().isNotEmpty) {
			params.add('numero=${Uri.encodeComponent(_filtroNumero.trim())}');
		}
		if (widget.misOtOnly) params.add('misOt=true');
		if (_mapFiltroEquipoId != null) params.add('equipoId=$_mapFiltroEquipoId');
		if (_mapFiltroUbicacionId != null) {
			params.add('ubicacionId=$_mapFiltroUbicacionId');
		}
		return '?${params.join('&')}';
	}

	void _aplicarFiltroMapa([PlantaMapSelection? selection]) {
		final sel = selection ?? _mapSelection;
		if (sel == null) {
			setState(() {
				_mapFiltroEquipoId = null;
				_mapFiltroUbicacionId = null;
			});
		} else {
			setState(() {
				_mapSelection = sel;
				switch (sel.scope) {
					case PlantaMapScope.planta:
						_mapFiltroEquipoId = null;
						_mapFiltroUbicacionId = null;
					case PlantaMapScope.ubicacion:
						_mapFiltroEquipoId = null;
						_mapFiltroUbicacionId = sel.ubicacionId;
					case PlantaMapScope.equipo:
						_mapFiltroEquipoId = sel.equipoId;
						_mapFiltroUbicacionId = null;
				}
			});
		}
		_bootstrap();
	}

	void _onMapSelectionChanged(PlantaMapSelection sel) {
		String? newUbicacion;
		String? newEquipo;
		switch (sel.scope) {
			case PlantaMapScope.planta:
				newUbicacion = null;
				newEquipo = null;
			case PlantaMapScope.ubicacion:
				newUbicacion = sel.ubicacionId;
				newEquipo = null;
			case PlantaMapScope.equipo:
				newUbicacion = null;
				newEquipo = sel.equipoId;
		}

		final sinCambio = _mapFiltroUbicacionId == newUbicacion &&
				_mapFiltroEquipoId == newEquipo;

		setState(() {
			_mapSelection = sel;
			_mapFiltroUbicacionId = newUbicacion;
			_mapFiltroEquipoId = newEquipo;
			_highlightEquipoId =
					sel.scope == PlantaMapScope.equipo ? sel.equipoId : null;
		});

		if (!sinCambio) _bootstrap();
	}

	Future<void> _bootstrap({bool keepSelection = false}) async {
		setState(() {
			_loading = true;
			_error = null;
			if (!keepSelection) {
				_selected = null;
				_checkedIds.clear();
			}
		});

		try {
			final api = ref.read(apiClientProvider);
			final query = _buildOtQuery();
			final resumen = await api.getJson('ot/resumen$query');
			final ordenes = await api.getList('ot$query');
			final tecnicos = (await api.getList('ot/tecnicos')).cast<Map<String, dynamic>>();
			var motivos = <Map<String, dynamic>>[];
			try {
				motivos =
						(await api.getList('motivos-ot-pendiente'))
								.cast<Map<String, dynamic>>();
			} catch (_) {
				motivos = [];
			}
			final user = ref.read(authControllerProvider).session?.usuario;
			if (user?.sucursalId != null) {
				final tree = await api.getList('ubicaciones/tree?sucursalId=${user!.sucursalId}');
				_sectores = _flattenUbicaciones(tree.cast<Map<String, dynamic>>());
			}
			try {
				_tiposEquipo =
						(await api.getList('tipos-equipo')).cast<Map<String, dynamic>>();
			} catch (_) {
				_tiposEquipo = [];
			}

			if (!mounted) return;
			final lista = ordenes.cast<Map<String, dynamic>>();
			setState(() {
				_resumen = resumen;
				_ordenes = lista;
				_tecnicos = tecnicos;
				_motivos = motivos;
			});

			final targetNumero = widget.numeroInicial?.trim();
			if (targetNumero != null && targetNumero.isNotEmpty) {
				Map<String, dynamic>? match;
				for (final ot in lista) {
					if ('${ot['numero']}' == targetNumero) {
						match = ot;
						break;
					}
				}
				if (match != null) {
					await _selectOt(match, silent: true);
					return;
				}
			}

			if (lista.isNotEmpty && MediaQuery.sizeOf(context).width >= 900) {
				await _selectOt(lista.first, silent: true);
			}
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	Future<void> _aplicarFiltros() => _bootstrap();

	void _resetMesActual() {
		final (desde, hasta) =
				widget.misOtOnly ? _rangoMisOt() : _rangoMesActual();
		setState(() {
			_fechaDesde = desde;
			_fechaHasta = hasta;
			_filtroEstado = null;
			_filtroTipo = null;
			_filtroTecnicoId = null;
			_filtroPrioridad = null;
			_filtroSectorId = null;
			_filtroMotivoId = null;
			_filtroTipoEquipoId = null;
			_filtroNumero = '';
			_search = '';
		});
		_bootstrap();
	}

	Future<void> _pickFecha({required bool desde}) async {
		final initial = desde ? _fechaDesde : _fechaHasta;
		final picked = await showDatePicker(
			context: context,
			initialDate: initial,
			firstDate: DateTime(2020),
			lastDate: DateTime(2035),
		);
		if (picked == null || !mounted) return;

		setState(() {
			if (desde) {
				_fechaDesde = picked;
				if (_fechaHasta.isBefore(_fechaDesde)) {
					_fechaHasta = _fechaDesde;
				}
			} else {
				_fechaHasta = picked;
				if (_fechaDesde.isAfter(_fechaHasta)) {
					_fechaDesde = _fechaHasta;
				}
			}
		});
	}

	List<Map<String, dynamic>> get _filtradas {
		final query = _search.trim().toLowerCase();
		return _ordenes.where((ot) {
			if (_filtroEstado != null && ot['estado'] != _filtroEstado) return false;
			if (query.isEmpty) return true;
			final equipo = ot['equipo'] as Map<String, dynamic>?;
			final numero = '${ot['numero'] ?? ''}';
			final codigo = equipo?['codigo'] as String? ?? '';
			final nombre = equipo?['nombre'] as String? ?? '';
			final tecnico = ot['tecnicoAsignado']?['nombreUsuario'] as String? ?? '';
			return numero.contains(query) ||
					codigo.toLowerCase().contains(query) ||
					nombre.toLowerCase().contains(query) ||
					tecnico.toLowerCase().contains(query);
		}).toList();
	}

	int _countEstado(String? estado) {
		if (estado == null) return _ordenes.length;
		return _ordenes.where((ot) => ot['estado'] == estado).length;
	}

	bool get _hayFiltrosActivos =>
			_filtroEstado != null ||
			_filtroTipo != null ||
			_filtroTecnicoId != null ||
			_filtroPrioridad != null ||
			_filtroSectorId != null ||
			_filtroMotivoId != null ||
			_filtroNumero.trim().isNotEmpty ||
			_search.isNotEmpty;

	List<Map<String, dynamic>> _flattenUbicaciones(
		List<Map<String, dynamic>> nodes, [
		int depth = 0,
	]) {
		final out = <Map<String, dynamic>>[];
		for (final node in nodes) {
			out.add({
				'id': node['id'],
				'nombre': '${'  ' * depth}${node['nombre']}',
			});
			final children = node['children'] as List<dynamic>? ?? [];
			out.addAll(
				_flattenUbicaciones(children.cast<Map<String, dynamic>>(), depth + 1),
			);
		}
		return out;
	}

	List<Map<String, dynamic>> get _selectedOts => _filtradas
			.where((ot) => _checkedIds.contains(ot['id'] as String))
			.toList();

	bool get _allVisibleSelected =>
			_filtradas.isNotEmpty &&
			_filtradas.every((ot) => _checkedIds.contains(ot['id'] as String));

	void _toggleCheck(String id) {
		setState(() {
			if (_checkedIds.contains(id)) {
				_checkedIds.remove(id);
			} else {
				_checkedIds.add(id);
			}
		});
	}

	void _toggleSelectAllVisible() {
		setState(() {
			if (_allVisibleSelected) {
				for (final ot in _filtradas) {
					_checkedIds.remove(ot['id'] as String);
				}
			} else {
				for (final ot in _filtradas) {
					_checkedIds.add(ot['id'] as String);
				}
			}
		});
	}

	void _clearChecked() => setState(_checkedIds.clear);

	Future<void> _runBatch(Future<void> Function() action, String okMessage) async {
		setState(() => _batchBusy = true);
		try {
			await action();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(okMessage)),
			);
			await _bootstrap(keepSelection: true);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('$error')),
			);
		} finally {
			if (mounted) setState(() => _batchBusy = false);
		}
	}

	Future<void> _batchReasignar() async {
		final ots = _selectedOts;
		if (ots.isEmpty) return;

		final tecnicoId = await showDialog<String>(
			context: context,
			builder: (context) => SimpleDialog(
				title: const Text('Reasignar técnico'),
				children: _tecnicos
						.map(
							(t) => SimpleDialogOption(
								onPressed: () => Navigator.pop(context, t['id'] as String),
								child: Text(t['nombreUsuario'] as String),
							),
						)
						.toList(),
			),
		);
		if (tecnicoId == null || !mounted) return;

		await _runBatch(() async {
			final api = ref.read(apiClientProvider);
			for (final ot in ots) {
				await api.patchJson(
					'ot/${ot['id']}/asignar',
					{'tecnicoAsignadoId': tecnicoId},
				);
			}
		}, 'Técnico reasignado en ${ots.length} OT');
	}

	Future<void> _batchMotivoPendiente() async {
		final ots = _selectedOts;
		if (ots.isEmpty) return;

		final motivoId = await OtMotivoPendienteDialog.show(
			context,
			motivos: _motivos,
		);
		if (!mounted) return;

		await _runBatch(() async {
			final api = ref.read(apiClientProvider);
			for (final ot in ots) {
				await api.patchJson(
					'ot/${ot['id']}/motivo-pendiente',
					{'motivoPendienteId': motivoId},
				);
			}
			if (motivoId != null) {
				final motivos =
						(await api.getList('motivos-ot-pendiente'))
								.cast<Map<String, dynamic>>();
				if (mounted) setState(() => _motivos = motivos);
			}
		}, 'Motivo aplicado en ${ots.length} OT');
	}

	Future<void> _batchCambiarEstado() async {
		final ots = _selectedOts;
		if (ots.isEmpty) return;

		const estados = ['pendiente', 'en_ejecucion', 'realizada'];
		final estado = await showDialog<String>(
			context: context,
			builder: (context) => SimpleDialog(
				title: const Text('Cambiar estado'),
				children: estados
						.map(
							(e) => SimpleDialogOption(
								onPressed: () => Navigator.pop(context, e),
								child: Text(OtUi.estadoLabel(e)),
							),
						)
						.toList(),
			),
		);
		if (estado == null || !mounted) return;

		await _runBatch(() async {
			final api = ref.read(apiClientProvider);
			for (final ot in ots) {
				await api.patchJson(
					'ot/${ot['id']}/estado',
					{'estado': estado},
				);
			}
		}, 'Estado actualizado en ${ots.length} OT');
	}

	Future<void> _batchAnular() async {
		final ots = _selectedOts;
		if (ots.isEmpty) return;

		final ok = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Anular OT seleccionadas'),
				content: Text('¿Anular ${ots.length} orden(es) de trabajo?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Anular'),
					),
				],
			),
		);
		if (ok != true || !mounted) return;

		await _runBatch(() async {
			final api = ref.read(apiClientProvider);
			for (final ot in ots) {
				await api.postJson(
					'ot/${ot['id']}/anular',
					{'motivo': 'Anulación masiva desde toolbar'},
				);
			}
		}, '${ots.length} OT anulada(s)');
	}

	void _exportSelected() {
		final ots = _selectedOts;
		if (ots.isEmpty) return;
		OtExport.download(ots, suffix: 'seleccion');
	}

	void _exportFiltradas() {
		if (_filtradas.isEmpty) return;
		OtExport.download(_filtradas, suffix: 'listado');
	}

	void _imprimirListado() {
		final ots = _checkedIds.isNotEmpty ? _selectedOts : _filtradas;
		if (ots.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('No hay OT para imprimir')),
			);
			return;
		}
		final periodo =
				'${_dateFormat.format(_fechaDesde)} — ${_dateFormat.format(_fechaHasta)}';
		OtPrint.previewList(
			titulo: _tituloListado,
			periodo: periodo,
			ordenes: ots,
			filtroExtra: _checkedIds.isNotEmpty ? '${ots.length} seleccionadas' : null,
		);
	}

	Future<void> _imprimirPdfSeleccion() async {
		final ots = _selectedOts;
		if (ots.isEmpty) return;
		setState(() => _batchBusy = true);
		try {
			for (final ot in ots) {
				await abrirPdfOt(ref, ot['id'] as String);
			}
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('${ots.length} PDF abierto(s)')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('$error')),
			);
		} finally {
			if (mounted) setState(() => _batchBusy = false);
		}
	}

	Future<void> _derivarOt(Map<String, dynamic> ot) async {
		try {
			await ref.read(apiClientProvider).postJson(
						'ot/${ot['id']}/derivar',
						{},
					);
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('OT derivada emitida')),
			);
			await _bootstrap(keepSelection: false);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('$error')),
			);
		}
	}

	Future<void> _selectOt(Map<String, dynamic> ot, {bool silent = false}) async {
		final equipoId = ot['equipo']?['id'] as String?;
		if (equipoId != null) {
			setState(() => _highlightEquipoId = equipoId);
		}
		setState(() => _loadingDetail = true);
		try {
			final detalle =
					await ref.read(apiClientProvider).getJson('ot/${ot['id']}');
			if (!mounted) return;
			setState(() => _selected = detalle);
		} catch (error) {
			if (!mounted) return;
			if (!silent) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text(error.toString())),
				);
			}
		} finally {
			if (mounted) setState(() => _loadingDetail = false);
		}
	}

	Future<void> _cambiarEstado(String otId, String estado, {String? comentario}) async {
		try {
			final detalle = await ref.read(apiClientProvider).patchJson(
						'ot/$otId/estado',
						{
							'estado': estado,
							if (comentario != null) 'comentario': comentario,
						},
					);
			await _bootstrap(keepSelection: true);
			if (!mounted) return;
			setState(() => _selected = detalle);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	Future<void> _reabrirOt(Map<String, dynamic> ot) async {
		final comentarioCtrl = TextEditingController();
		final confirmed = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Reabrir OT'),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Text(
							'La OT #${ot['numero']} volverá a pendiente. '
							'Se limpiará la firma y la fecha de ejecución.',
						),
						const SizedBox(height: 16),
						TextField(
							controller: comentarioCtrl,
							decoration: const InputDecoration(
								labelText: 'Motivo (opcional)',
								border: OutlineInputBorder(),
							),
							maxLines: 3,
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
						child: const Text('Reabrir'),
					),
				],
			),
		);

		final comentario = comentarioCtrl.text.trim();
		comentarioCtrl.dispose();
		if (confirmed != true || !mounted) return;

		try {
			final detalle = await ref.read(apiClientProvider).postJson(
						'ot/${ot['id']}/reabrir',
						{
							if (comentario.isNotEmpty) 'comentario': comentario,
						},
					);
			await _bootstrap(keepSelection: true);
			if (!mounted) return;
			setState(() => _selected = detalle);
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('OT reabierta')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	Future<void> _solicitarMateriales(Map<String, dynamic> ot) async {
		final ok = await showSolicitarMaterialesSheet(
			context,
			ref,
			otId: ot['id'] as String,
			otNumero: ot['numero'] as int? ?? 0,
		);
		if (!mounted) return;
		if (ok) {
			await _bootstrap(keepSelection: true);
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Solicitud de materiales enviada')),
			);
		}
	}

	void _navegarEmitirNoPeriodicaDesdeOt(Map<String, dynamic> ot) {
		final equipo = ot['equipo'] as Map<String, dynamic>?;
		final procedimiento = ot['procedimiento'] as Map<String, dynamic>?;
		final numero = ot['numero'];
		final comentariosPrevios = ot['comentarios'] as String?;
		final comentarios = StringBuffer('Seguimiento OT #$numero');
		if (comentariosPrevios != null && comentariosPrevios.trim().isNotEmpty) {
			comentarios.write(' — $comentariosPrevios');
		}

		final params = <String, String>{
			if (equipo?['id'] != null) 'equipoId': equipo!['id'] as String,
			if (procedimiento?['id'] != null) 'procedimientoId': procedimiento!['id'] as String,
			'comentarios': comentarios.toString(),
			if (numero != null) 'otReferencia': '$numero',
		};

		final uri = Uri(path: '/ot/emitir-no-periodica', queryParameters: params);
		context.push(uri.toString());
	}

	Future<void> _firmarYCerrar(Map<String, dynamic> ot) async {
		final firma = await OtFirmaSheet.show(context);
		if (firma == null || !mounted) return;

		try {
			final detalle = await ref.read(apiClientProvider).postJson(
						'ot/${ot['id']}/firma',
						{'firmaDigital': firma},
					);
			await _bootstrap(keepSelection: true);
			if (!mounted) return;
			setState(() => _selected = detalle);
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text(
						'OT completada. El supervisor puede descargar el PDF desde Buscar OT.',
					),
				),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('$error')),
			);
		}
	}

	Future<void> _abrirEjecucion(Map<String, dynamic> ot) async {
		final detalle = await OtEjecucionSheet.show(context, ot);
		if (detalle == null || !mounted) return;
		setState(() => _selected = detalle);
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(content: Text('Trabajo guardado')),
		);
	}

	@override
	Widget build(BuildContext context) {
		if (_loading) {
			return const Center(child: CircularProgressIndicator());
		}

		if (_error != null) {
			return Center(
				child: Padding(
					padding: const EdgeInsets.all(24),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
							const SizedBox(height: 12),
							Text(_error!, textAlign: TextAlign.center),
							const SizedBox(height: 12),
							FilledButton(onPressed: _bootstrap, child: const Text('Reintentar')),
						],
					),
				),
			);
		}

		final scheme = Theme.of(context).colorScheme;
		final width = MediaQuery.sizeOf(context).width;
		final wide = width >= 900;
		final tablet = width >= 700 && width < 900;

		if (!wide && !(widget.misOtOnly && tablet)) {
			return _wrapTecnicoShell(_buildMobile(scheme));
		}

		if (widget.misOtOnly) {
			final listFlex = width >= 1100 ? 2 : 3;
			final detailFlex = width >= 1100 ? 5 : 4;
			return _wrapTecnicoShell(
				Row(
					children: [
						Expanded(
							flex: listFlex,
							child: _buildListPanel(scheme, comfortable: true),
						),
						const VerticalDivider(width: 1),
						Expanded(
							flex: detailFlex,
							child: _buildMainPanel(scheme, mobile: width < 1100),
						),
					],
				),
			);
		}

		return Row(
			children: [
				CollapsiblePanel(
					collapsed: _listCollapsed,
					expandedWidth: _listExpandedWidth,
					collapsedWidth: _listCollapsedWidth,
					collapsedChild: Material(
						color: scheme.surface,
						child: Column(
							children: [
								const SizedBox(height: 16),
								Icon(Icons.assignment_rounded, color: AppColors.accent, size: 22),
								const Spacer(),
							],
						),
					),
					child: _buildListPanel(scheme),
				),
				PanelCollapseHandle(
					collapsed: _listCollapsed,
					onToggle: () => setState(() => _listCollapsed = !_listCollapsed),
					edge: PanelCollapseEdge.start,
					expandTooltip: 'Expandir listado',
					collapseTooltip: 'Contraer listado',
				),
				Expanded(flex: 3, child: _buildMainPanel(scheme)),
				PanelCollapseHandle(
					collapsed: _mapCollapsed,
					onToggle: () => setState(() => _mapCollapsed = !_mapCollapsed),
					edge: PanelCollapseEdge.end,
					topOffset: 16,
					expandTooltip: 'Mostrar mapa',
					collapseTooltip: 'Ocultar mapa',
				),
				CollapsiblePanel(
					collapsed: _mapCollapsed,
					expandedWidth: _mapExpandedWidth,
					collapsedWidth: _mapCollapsedWidth,
					child: PlantaMapPanel(
						compact: true,
						selection: _mapSelection,
						highlightEquipoId:
								_showMapaMobile ? null : _highlightEquipoId,
						onSelectionChanged: _onMapSelectionChanged,
						onSearch: () => _aplicarFiltroMapa(),
					),
				),
			],
		);
	}

	Future<void> _abrirPdf(String otId) async {
		try {
			await abrirPdfOt(ref, otId);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('$error')),
			);
		}
	}

	Widget _wrapTecnicoShell(Widget child) {
		if (!widget.misOtOnly) return child;

		return Column(
			children: [
				_TecnicoTopBar(
					userName: _user?.nombreUsuario ?? '',
					onRefresh: () => _bootstrap(keepSelection: true),
					onPerfil: () => context.go('/perfil'),
					onLogout: () async {
						await ref.read(authControllerProvider.notifier).logout();
						if (mounted) context.go('/login');
					},
				),
				Expanded(child: child),
			],
		);
	}

	Widget _buildMobile(ColorScheme scheme) {
		if (_showMapaMobile) {
			return Column(
				children: [
					Material(
						color: scheme.surface,
						child: ListTile(
							leading: IconButton(
								onPressed: () => setState(() => _showMapaMobile = false),
								icon: const Icon(Icons.arrow_back_rounded),
							),
							title: const Text('Mapa de planta'),
							trailing: FilledButton.tonalIcon(
								onPressed: () {
									setState(() => _showMapaMobile = false);
								},
								icon: const Icon(Icons.check_rounded, size: 18),
								label: const Text('Listo'),
							),
						),
					),
					Expanded(
						child: PlantaMapPanel(
							selection: _mapSelection,
							showSearchButton: false,
							onSelectionChanged: _onMapSelectionChanged,
						),
					),
				],
			);
		}

		if (_selected == null) {
			return Column(
				children: [
					Expanded(
						child: _buildListPanel(
							scheme,
							comfortable: widget.misOtOnly,
						),
					),
					if (!widget.misOtOnly)
						SafeArea(
							child: Padding(
								padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
								child: SizedBox(
									width: double.infinity,
									child: FilledButton.tonalIcon(
										onPressed: () => setState(() => _showMapaMobile = true),
										icon: const Icon(Icons.map_rounded),
										label: const Text('Ver mapa de planta'),
									),
								),
							),
						),
				],
			);
		}

		return Column(
			children: [
				Material(
					color: scheme.surface,
					child: SafeArea(
						bottom: false,
						child: Padding(
							padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
							child: Row(
								children: [
									IconButton(
										onPressed: () => setState(() => _selected = null),
										icon: const Icon(Icons.arrow_back_rounded),
									),
									const SizedBox(width: 4),
									Expanded(
										child: Text(
											'OT #${_selected?['numero']}',
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: const TextStyle(
												fontWeight: FontWeight.w700,
												fontSize: 18,
											),
										),
									),
								],
							),
						),
					),
				),
				Expanded(child: _buildMainPanel(scheme, mobile: true)),
			],
		);
	}

	Widget _buildListPanel(ColorScheme scheme, {bool comfortable = false}) {
		final plantaLine = _user?.sucursalNombre != null
				? '${_user!.sucursalNombre!} · ${_dateFormat.format(_fechaDesde)} – ${_dateFormat.format(_fechaHasta)}'
				: null;
		final hPad = comfortable ? 20.0 : 16.0;
		final titleSize = comfortable ? 24.0 : 22.0;

		return Container(
			color: AppColors.black,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: EdgeInsets.fromLTRB(hPad, comfortable ? 24 : 20, 12, comfortable ? 10 : 4),
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												_tituloListado,
												style: TextStyle(
													fontWeight: FontWeight.w700,
													fontSize: titleSize,
													color: Colors.white,
													height: 1.2,
												),
											),
											if (plantaLine != null) ...[
												const SizedBox(height: 8),
												Text(
													plantaLine,
													maxLines: 2,
													overflow: TextOverflow.ellipsis,
													style: const TextStyle(
														color: AppColors.accent,
														fontSize: 13,
														fontWeight: FontWeight.w500,
														height: 1.35,
													),
												),
											],
										],
									),
								),
								if (!widget.misOtOnly)
									IconButton(
										tooltip: _showFiltros ? 'Ocultar filtros' : 'Mostrar filtros',
										onPressed: () => setState(() => _showFiltros = !_showFiltros),
										icon: Icon(
											_showFiltros
													? Icons.filter_list_off_rounded
													: Icons.filter_list_rounded,
											color: _hayFiltrosActivos
													? AppColors.brandYellow
													: Colors.white.withValues(alpha: 0.7),
										),
									),
							],
						),
					),
					if (_showFiltros && !widget.misOtOnly)
						Padding(
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
							child: _FiltrosPanel(
								fechaDesde: _fechaDesde,
								fechaHasta: _fechaHasta,
								filtroTipo: _filtroTipo,
								filtroTecnicoId: _filtroTecnicoId,
								filtroPrioridad: _filtroPrioridad,
								filtroSectorId: _filtroSectorId,
								filtroMotivoId: _filtroMotivoId,
								filtroTipoEquipoId: _filtroTipoEquipoId,
								filtroNumero: _filtroNumero,
								tecnicos: _tecnicos,
								sectores: _sectores,
								motivos: _motivos,
								tiposEquipo: _tiposEquipo,
								formatDate: _dateFormat.format,
								onPickDesde: () => _pickFecha(desde: true),
								onPickHasta: () => _pickFecha(desde: false),
								onMesActual: _resetMesActual,
								onTipoChanged: (value) => setState(() => _filtroTipo = value),
								onTecnicoChanged: (value) => setState(() => _filtroTecnicoId = value),
								onPrioridadChanged: (value) => setState(() => _filtroPrioridad = value),
								onSectorChanged: (value) => setState(() => _filtroSectorId = value),
								onMotivoChanged: (value) => setState(() => _filtroMotivoId = value),
								onTipoEquipoChanged: (value) =>
										setState(() => _filtroTipoEquipoId = value),
								onNumeroChanged: (value) => setState(() => _filtroNumero = value),
								onAplicar: _aplicarFiltros,
							),
						),
					Padding(
						padding: EdgeInsets.symmetric(horizontal: hPad),
						child: TextField(
							style: const TextStyle(color: Colors.white),
							decoration: SikaUi.searchDecoration(
								context: context,
								hint: widget.misOtOnly
										? 'Buscar OT o equipo…'
										: 'Buscar OT, equipo o técnico…',
							),
							onChanged: (value) => setState(() => _search = value),
						),
					),
					SizedBox(height: comfortable ? 14 : 10),
					_FiltrosEstado(
						valor: _filtroEstado,
						countFor: _countEstado,
						onChanged: (value) => setState(() => _filtroEstado = value),
					),
					if (_canManage && !widget.misOtOnly) ...[
						const SizedBox(height: 6),
						OtListToolbar(
							selectedCount: _checkedIds.length,
							totalCount: _filtradas.length,
							allSelected: _allVisibleSelected,
							canAnular: _canAnular,
							enabled: !_batchBusy,
							onToggleSelectAll: _toggleSelectAllVisible,
							onClearSelection: _clearChecked,
							onReasignar: _batchReasignar,
							onMotivoPendiente: _batchMotivoPendiente,
							onCambiarEstado: _batchCambiarEstado,
							onAnular: _batchAnular,
							onExportar: _exportSelected,
							onExportarFiltradas: _exportFiltradas,
							onImprimir: _imprimirListado,
							onImprimirPdf: _checkedIds.isNotEmpty ? _imprimirPdfSeleccion : null,
						),
					],
					Expanded(
						child: RefreshIndicator(
							color: AppColors.brandYellow,
							onRefresh: () => _bootstrap(keepSelection: true),
							child: _filtradas.isEmpty
									? ListView(
											physics: const AlwaysScrollableScrollPhysics(),
											children: [
												SizedBox(
													height: 280,
													child: _EmptyListState(
														hasFiltro: _filtroEstado != null || _search.isNotEmpty,
														misOt: widget.misOtOnly,
													),
												),
											],
										)
									: _filtroEstado == null && _search.isEmpty
											? _buildGroupedList(comfortable: comfortable)
											: ListView.builder(
													physics: const AlwaysScrollableScrollPhysics(),
													padding: EdgeInsets.fromLTRB(
														comfortable ? 16 : 12,
														comfortable ? 8 : 4,
														comfortable ? 16 : 12,
														comfortable ? 28 : 16,
													),
													itemCount: _filtradas.length,
													itemBuilder: (context, index) {
														final ot = _filtradas[index];
														return _OtListTile(
															ot: ot,
															selected: _selected?['id'] == ot['id'],
															checked: _checkedIds.contains(ot['id'] as String),
															showCheckbox: _canManage && !widget.misOtOnly,
															hideTecnico: widget.misOtOnly,
															comfortable: comfortable,
															formatDate: _formatDate,
															onTap: () => _selectOt(ot),
															onCheckChanged: _canManage && !widget.misOtOnly
																	? () => _toggleCheck(ot['id'] as String)
																	: null,
														);
													},
												),
						),
					),
				],
			),
		);
	}

	Widget _buildGroupedList({bool comfortable = false}) {
		const secciones = [
			('realizada', 'No hay órdenes realizadas', Icons.check_circle_outline_rounded),
			('pendiente', 'No hay órdenes pendientes', Icons.schedule_rounded),
			('en_ejecucion', 'No hay órdenes en ejecución', Icons.play_circle_outline_rounded),
			('anulada', 'No hay órdenes anuladas', Icons.cancel_outlined),
		];

		return ListView(
			physics: const AlwaysScrollableScrollPhysics(),
			padding: EdgeInsets.fromLTRB(
				comfortable ? 16 : 12,
				comfortable ? 8 : 4,
				comfortable ? 16 : 12,
				comfortable ? 28 : 16,
			),
			children: [
				for (final (estado, emptyMsg, icon) in secciones) ...[
					..._ordenes
							.where((ot) => ot['estado'] == estado)
							.map(
								(ot) => _OtListTile(
									ot: ot,
									selected: _selected?['id'] == ot['id'],
									checked: _checkedIds.contains(ot['id'] as String),
									showCheckbox: _canManage && !widget.misOtOnly,
									hideTecnico: widget.misOtOnly,
									comfortable: comfortable,
									formatDate: _formatDate,
									onTap: () => _selectOt(ot),
									onCheckChanged: _canManage && !widget.misOtOnly
											? () => _toggleCheck(ot['id'] as String)
											: null,
								),
							),
					if (!_ordenes.any((ot) => ot['estado'] == estado))
						SikaEmptyState(message: emptyMsg, icon: icon, compact: true),
				],
			],
		);
	}

	Widget _buildMainPanel(ColorScheme scheme, {bool mobile = false}) {
		Widget buildDetailContent({required bool includeActionBar}) {
			return _OtDetailContent(
				ot: _selected!,
				canManage: _canManage,
				canEjecutar: _puedeEjecutarOt(_selected!),
				canAnular: _canAnular,
				canReabrir: _canReabrir,
				canEmitirNoPeriodica: _canEmitirNoPeriodica,
				canSolicitarMateriales: _canSolicitarMateriales,
				formatDate: _formatDate,
				includeActionBar: includeActionBar,
				onPdf: () => _abrirPdf(_selected!['id'] as String),
				onIniciar: () => _cambiarEstado(
					_selected!['id'] as String,
					'en_ejecucion',
					comentario: 'Técnico inició ejecución',
				),
				onEjecucion: () => _abrirEjecucion(_selected!),
				onFirmar: () => _firmarYCerrar(_selected!),
				onAnular: () => _cambiarEstado(
					_selected!['id'] as String,
					'anulada',
					comentario: 'OT anulada',
				),
				onReabrir: () => _reabrirOt(_selected!),
				onEmitirNoPeriodica: () => _navegarEmitirNoPeriodicaDesdeOt(_selected!),
				onDerivar: () => _derivarOt(_selected!),
				onSolicitarMateriales: () => _solicitarMateriales(_selected!),
				ocultarPdf: widget.misOtOnly,
			);
		}

		Widget buildActionBar() {
			final ot = _selected!;
			return _ActionBar(
				estado: ot['estado'] as String? ?? '',
				canManage: _canManage,
				canEjecutar: _puedeEjecutarOt(ot),
				canAnular: _canAnular,
				canReabrir: _canReabrir,
				canEmitirNoPeriodica: _canEmitirNoPeriodica,
				canSolicitarMateriales: _canSolicitarMateriales,
				onPdf: () => _abrirPdf(ot['id'] as String),
				onIniciar: () => _cambiarEstado(
					ot['id'] as String,
					'en_ejecucion',
					comentario: 'Técnico inició ejecución',
				),
				onEjecucion: () => _abrirEjecucion(ot),
				onFirmar: () => _firmarYCerrar(ot),
				onAnular: () => _cambiarEstado(
					ot['id'] as String,
					'anulada',
					comentario: 'OT anulada',
				),
				onReabrir: () => _reabrirOt(ot),
				onEmitirNoPeriodica: () => _navegarEmitirNoPeriodicaDesdeOt(ot),
				onDerivar: () => _derivarOt(ot),
				onSolicitarMateriales: () => _solicitarMateriales(ot),
				ocultarPdf: widget.misOtOnly,
			);
		}

		return Container(
			color: AppColors.black,
			child: Column(
				children: [
					if (!widget.misOtOnly)
						_MainTopBar(
							plantaNombre: _user?.sucursalNombre ?? '',
							onRefresh: _bootstrap,
						),
					Expanded(
						child: _loadingDetail
								? const Center(child: CircularProgressIndicator())
								: _selected == null
										? _EmptyDetailState()
										: widget.misOtOnly
												? Column(
														children: [
															Expanded(
																child: ListView(
																	padding: EdgeInsets.fromLTRB(
																		mobile ? 16 : 24,
																		mobile ? 16 : 24,
																		mobile ? 16 : 24,
																		mobile ? 12 : 16,
																	),
																	children: [
																		buildDetailContent(includeActionBar: false),
																	],
																),
															),
															SafeArea(
																top: false,
																child: Padding(
																	padding: EdgeInsets.fromLTRB(
																		mobile ? 16 : 24,
																		8,
																		mobile ? 16 : 24,
																		mobile ? 16 : 20,
																	),
																	child: buildActionBar(),
																),
															),
														],
													)
												: ListView(
														padding: EdgeInsets.all(mobile ? 16 : 20),
														children: [
															if (_resumen != null && !mobile) ...[
																_StatsRow(resumen: _resumen!),
																const SizedBox(height: 20),
															],
															buildDetailContent(includeActionBar: true),
														],
													),
					),
				],
			),
		);
	}

	String _formatDate(dynamic value) {
		if (value == null) return '—';
		final parsed = DateTime.tryParse(value.toString());
		if (parsed == null) return value.toString();
		return _dateFormat.format(parsed.toLocal());
	}
}

class _TecnicoTopBar extends StatelessWidget {
	const _TecnicoTopBar({
		required this.userName,
		required this.onRefresh,
		required this.onPerfil,
		required this.onLogout,
	});

	final String userName;
	final VoidCallback onRefresh;
	final VoidCallback onPerfil;
	final VoidCallback onLogout;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Material(
			color: scheme.surface,
			child: SafeArea(
				bottom: false,
				child: Container(
					height: 60,
					padding: const EdgeInsets.symmetric(horizontal: 12),
					decoration: BoxDecoration(
						border: Border(
							bottom: BorderSide(
								color: scheme.outlineVariant.withValues(alpha: 0.4),
							),
						),
					),
					child: Row(
						children: [
							const SizedBox(width: 4),
							Text(
								'SIKA',
								style: Theme.of(context).textTheme.titleMedium?.copyWith(
											fontWeight: FontWeight.w800,
											color: AppColors.accent,
										),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Text(
									userName,
									maxLines: 1,
									overflow: TextOverflow.ellipsis,
									style: Theme.of(context).textTheme.bodyMedium?.copyWith(
												color: scheme.onSurfaceVariant,
												fontWeight: FontWeight.w500,
											),
								),
							),
							IconButton(
								tooltip: 'Actualizar',
								onPressed: onRefresh,
								icon: const Icon(Icons.refresh_rounded),
							),
							IconButton(
								tooltip: 'Perfil',
								onPressed: onPerfil,
								icon: const Icon(Icons.person_outline_rounded),
							),
							IconButton(
								tooltip: 'Cerrar sesión',
								onPressed: onLogout,
								icon: Icon(Icons.logout_rounded, color: scheme.error),
							),
						],
					),
				),
			),
		);
	}
}

class _MainTopBar extends StatelessWidget {
	const _MainTopBar({
		required this.plantaNombre,
		required this.onRefresh,
	});

	final String plantaNombre;
	final VoidCallback onRefresh;

	@override
	Widget build(BuildContext context) {
		return Container(
			height: 64,
			padding: const EdgeInsets.symmetric(horizontal: 20),
			decoration: const BoxDecoration(
				color: AppColors.black,
				border: Border(
					bottom: BorderSide(color: AppColors.cardBorder),
				),
			),
			child: Row(
				children: [
					const Icon(Icons.assignment_rounded, color: AppColors.accent),
					const SizedBox(width: 10),
					const Text(
						'Detalle de OT',
						style: TextStyle(
							fontWeight: FontWeight.w700,
							fontSize: 20,
							color: Colors.white,
						),
					),
					if (plantaNombre.isNotEmpty) ...[
						const SizedBox(width: 12),
						Container(
							padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
							decoration: BoxDecoration(
								color: AppColors.accent.withValues(alpha: 0.1),
								borderRadius: BorderRadius.circular(999),
							),
							child: Text(
								plantaNombre,
								style: const TextStyle(
									color: AppColors.accent,
									fontWeight: FontWeight.w600,
									fontSize: 12,
								),
							),
						),
					],
					const Spacer(),
					IconButton(
						onPressed: onRefresh,
						icon: const Icon(Icons.refresh_rounded),
						tooltip: 'Actualizar',
					),
				],
			),
		);
	}
}

class _StatsRow extends StatelessWidget {
	const _StatsRow({required this.resumen});

	final Map<String, dynamic> resumen;

	@override
	Widget build(BuildContext context) {
		return LayoutBuilder(
			builder: (context, constraints) {
				final cards = [
					_StatCard(
						label: 'Pendientes',
						value: '${resumen['pendientes'] ?? 0}',
						icon: Icons.pending_actions_rounded,
						color: AppColors.danger,
					),
					_StatCard(
						label: 'En ejecución',
						value: '${resumen['enEjecucion'] ?? 0}',
						icon: Icons.play_circle_outline_rounded,
						color: AppColors.warning,
					),
					_StatCard(
						label: 'Realizadas',
						value: '${resumen['realizadas'] ?? resumen['realizadasHoy'] ?? 0}',
						icon: Icons.check_circle_outline_rounded,
						color: AppColors.success,
					),
					_StatCard(
						label: 'Total período',
						value: '${resumen['totalPeriodo'] ?? 0}',
						icon: Icons.assignment_rounded,
						color: AppColors.primary,
					),
				];

				if (constraints.maxWidth < 700) {
					return Wrap(
						spacing: 12,
						runSpacing: 12,
						children: cards
								.map(
									(card) => SizedBox(
										width: (constraints.maxWidth - 12) / 2,
										child: card,
									),
								)
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
		required this.icon,
		required this.color,
	});

	final String label;
	final String value;
	final IconData icon;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: SikaUi.cardDecoration(),
			child: Row(
				children: [
					Container(
						width: 40,
						height: 40,
						decoration: BoxDecoration(
							color: color.withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(12),
						),
						child: Icon(icon, color: color, size: 20),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(label, style: Theme.of(context).textTheme.bodySmall),
								Text(
									value,
									style: Theme.of(context).textTheme.headlineSmall?.copyWith(
												color: color,
												fontWeight: FontWeight.w700,
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

class _FiltrosPanel extends StatelessWidget {
	const _FiltrosPanel({
		required this.fechaDesde,
		required this.fechaHasta,
		required this.filtroTipo,
		required this.filtroTecnicoId,
		required this.filtroPrioridad,
		required this.filtroSectorId,
		required this.filtroMotivoId,
		required this.filtroTipoEquipoId,
		required this.filtroNumero,
		required this.tecnicos,
		required this.sectores,
		required this.motivos,
		required this.tiposEquipo,
		required this.formatDate,
		required this.onPickDesde,
		required this.onPickHasta,
		required this.onMesActual,
		required this.onTipoChanged,
		required this.onTecnicoChanged,
		required this.onPrioridadChanged,
		required this.onSectorChanged,
		required this.onMotivoChanged,
		required this.onTipoEquipoChanged,
		required this.onNumeroChanged,
		required this.onAplicar,
	});

	final DateTime fechaDesde;
	final DateTime fechaHasta;
	final String? filtroTipo;
	final String? filtroTecnicoId;
	final String? filtroPrioridad;
	final String? filtroSectorId;
	final String? filtroMotivoId;
	final String? filtroTipoEquipoId;
	final String filtroNumero;
	final List<Map<String, dynamic>> tecnicos;
	final List<Map<String, dynamic>> sectores;
	final List<Map<String, dynamic>> motivos;
	final List<Map<String, dynamic>> tiposEquipo;
	final String Function(DateTime) formatDate;
	final VoidCallback onPickDesde;
	final VoidCallback onPickHasta;
	final VoidCallback onMesActual;
	final ValueChanged<String?> onTipoChanged;
	final ValueChanged<String?> onTecnicoChanged;
	final ValueChanged<String?> onPrioridadChanged;
	final ValueChanged<String?> onSectorChanged;
	final ValueChanged<String?> onMotivoChanged;
	final ValueChanged<String?> onTipoEquipoChanged;
	final ValueChanged<String> onNumeroChanged;
	final VoidCallback onAplicar;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Row(
						children: [
							Expanded(
								child: _DateField(
									label: 'Desde',
									value: formatDate(fechaDesde),
									onTap: onPickDesde,
								),
							),
							const SizedBox(width: 10),
							Expanded(
								child: _DateField(
									label: 'Hasta',
									value: formatDate(fechaHasta),
									onTap: onPickHasta,
								),
							),
						],
					),
					const SizedBox(height: 10),
					DropdownButtonFormField<String?>(
						value: filtroTipo,
						isExpanded: true,
						decoration: const InputDecoration(
							labelText: 'Tipo',
							isDense: true,
							border: OutlineInputBorder(),
						),
						items: const [
							DropdownMenuItem(value: null, child: Text('Todos los tipos')),
							DropdownMenuItem(value: 'preventivo', child: Text('Preventivo')),
							DropdownMenuItem(value: 'correctivo', child: Text('Correctivo')),
							DropdownMenuItem(value: 'predictivo', child: Text('Predictivo')),
							DropdownMenuItem(value: 'mejora', child: Text('Mejora')),
						],
						onChanged: onTipoChanged,
					),
					const SizedBox(height: 10),
					DropdownButtonFormField<String?>(
						value: filtroTecnicoId,
						isExpanded: true,
						decoration: const InputDecoration(
							labelText: 'Técnico',
							isDense: true,
							border: OutlineInputBorder(),
						),
						items: [
							const DropdownMenuItem(value: null, child: Text('Todos los técnicos')),
							...tecnicos.map(
								(t) => DropdownMenuItem(
									value: t['id'] as String,
									child: Text(t['nombreUsuario'] as String),
								),
							),
						],
						onChanged: onTecnicoChanged,
					),
					const SizedBox(height: 10),
					DropdownButtonFormField<String?>(
						value: filtroPrioridad,
						isExpanded: true,
						decoration: const InputDecoration(
							labelText: 'Prioridad',
							isDense: true,
							border: OutlineInputBorder(),
						),
						items: const [
							DropdownMenuItem(value: null, child: Text('Todas')),
							DropdownMenuItem(value: 'baja', child: Text('Baja')),
							DropdownMenuItem(value: 'media', child: Text('Media')),
							DropdownMenuItem(value: 'alta', child: Text('Alta')),
							DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
						],
						onChanged: onPrioridadChanged,
					),
					const SizedBox(height: 10),
					DropdownButtonFormField<String?>(
						value: filtroSectorId,
						isExpanded: true,
						decoration: const InputDecoration(
							labelText: 'Sector responsable',
							isDense: true,
							border: OutlineInputBorder(),
						),
						items: [
							const DropdownMenuItem(value: null, child: Text('Todos los sectores')),
							...sectores.map(
								(s) => DropdownMenuItem(
									value: s['id'] as String,
									child: Text(s['nombre'] as String),
								),
							),
						],
						onChanged: onSectorChanged,
					),
					const SizedBox(height: 10),
					DropdownButtonFormField<String?>(
						value: filtroMotivoId,
						isExpanded: true,
						decoration: const InputDecoration(
							labelText: 'Motivo pendiente',
							isDense: true,
							border: OutlineInputBorder(),
						),
						items: [
							const DropdownMenuItem(value: null, child: Text('Todos los motivos')),
							...motivos.map(
								(m) => DropdownMenuItem(
									value: m['id'] as String,
									child: Text(m['descripcion'] as String),
								),
							),
						],
						onChanged: onMotivoChanged,
					),
					if (tiposEquipo.isNotEmpty) ...[
						const SizedBox(height: 10),
						DropdownButtonFormField<String?>(
							value: filtroTipoEquipoId,
							isExpanded: true,
							decoration: const InputDecoration(
								labelText: 'Tipo de equipo',
								isDense: true,
								border: OutlineInputBorder(),
							),
							items: [
								const DropdownMenuItem(
									value: null,
									child: Text('Todos los tipos de equipo'),
								),
								...tiposEquipo.map(
									(t) => DropdownMenuItem(
										value: t['id'] as String,
										child: Text(t['nombre'] as String),
									),
								),
							],
							onChanged: onTipoEquipoChanged,
						),
					],
					const SizedBox(height: 10),
					TextField(
						decoration: const InputDecoration(
							labelText: 'Nº OT',
							isDense: true,
							border: OutlineInputBorder(),
						),
						keyboardType: TextInputType.number,
						onChanged: onNumeroChanged,
					),
					const SizedBox(height: 12),
					Row(
						children: [
							TextButton.icon(
								onPressed: onMesActual,
								icon: const Icon(Icons.calendar_month_rounded, size: 18),
								label: const Text('Mes actual'),
							),
							const Spacer(),
							FilledButton.icon(
								style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
								onPressed: onAplicar,
								icon: const Icon(Icons.search_rounded, size: 18),
								label: const Text('Buscar'),
							),
						],
					),
				],
			),
		);
	}
}

class _DateField extends StatelessWidget {
	const _DateField({
		required this.label,
		required this.value,
		required this.onTap,
	});

	final String label;
	final String value;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(8),
			child: InputDecorator(
				decoration: InputDecoration(
					labelText: label,
					isDense: true,
					border: const OutlineInputBorder(),
					suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
				),
				child: Text(value, style: const TextStyle(fontSize: 13)),
			),
		);
	}
}

class _FiltrosEstado extends StatelessWidget {
	const _FiltrosEstado({
		required this.valor,
		required this.countFor,
		required this.onChanged,
	});

	final String? valor;
	final int Function(String?) countFor;
	final ValueChanged<String?> onChanged;

	@override
	Widget build(BuildContext context) {
		const estados = [null, 'pendiente', 'en_ejecucion'];

		return Padding(
			padding: const EdgeInsets.only(bottom: 4),
			child: SingleChildScrollView(
				scrollDirection: Axis.horizontal,
				padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
				child: Row(
					children: estados.map((estado) {
						final selected = valor == estado;
						final label = estado == null ? 'Todas' : OtUi.estadoLabel(estado);
						final count = countFor(estado);
						final chipColor = estado != null
								? OtUi.estadoColor(estado)
								: Theme.of(context).colorScheme.onSurfaceVariant;

						return Padding(
							padding: const EdgeInsets.only(right: 8),
							child: FilterChip(
								label: Text('$label ($count)'),
								selected: selected,
								showCheckmark: false,
								visualDensity: VisualDensity.comfortable,
								selectedColor: chipColor.withValues(alpha: 0.15),
								backgroundColor: AppColors.cardElevated,
								side: BorderSide(
									color: selected
											? (estado == null
													? AppColors.brandYellow
													: chipColor.withValues(alpha: 0.5))
											: AppColors.cardBorder,
								),
								labelStyle: TextStyle(
									fontSize: 13,
									fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
									color: selected
											? (estado == null ? AppColors.brandYellow : chipColor)
											: AppColors.mutedText,
								),
								onSelected: (_) => onChanged(estado),
							),
						);
					}).toList(),
				),
			),
		);
	}
}

class _OtListTile extends StatelessWidget {
	const _OtListTile({
		required this.ot,
		required this.selected,
		required this.formatDate,
		required this.onTap,
		this.checked = false,
		this.showCheckbox = false,
		this.hideTecnico = false,
		this.comfortable = false,
		this.onCheckChanged,
	});

	final Map<String, dynamic> ot;
	final bool selected;
	final bool checked;
	final bool showCheckbox;
	final bool hideTecnico;
	final bool comfortable;
	final String Function(dynamic) formatDate;
	final VoidCallback onTap;
	final VoidCallback? onCheckChanged;

	@override
	Widget build(BuildContext context) {
		final equipo = ot['equipo'] as Map<String, dynamic>?;
		final ubicacion = ot['ubicacion'] as Map<String, dynamic>? ?? equipo?['ubicacion'];
		final estado = ot['estado'] as String? ?? '';
		final tipo = ot['tipo'] as String? ?? '';
		final prioridad = ot['prioridad'] as String? ?? 'media';
		final tecnico = ot['tecnicoAsignado'] as Map<String, dynamic>?;
		final motivo = ot['motivoPendiente'] as Map<String, dynamic>?;
		final procedimiento = ot['procedimiento'] as Map<String, dynamic>?;
		final gut = OtUi.formatDuracionMinutos(procedimiento?['duracionEstimada']);
		final color = OtUi.estadoColor(estado);
		final isRealizada = estado == 'realizada';
		final cardBg = switch (estado) {
			'realizada' => const Color(0xFF14532D),
			'pendiente' => const Color(0xFF3D2020),
			'en_ejecucion' => const Color(0xFF3D3018),
			'anulada' => const Color(0xFF2A2A2A),
			_ => AppColors.cardDark,
		};
		final onCard = isRealizada || estado == 'pendiente' || estado == 'en_ejecucion';
		final pad = comfortable ? 18.0 : 16.0;

		return Padding(
			padding: EdgeInsets.only(bottom: comfortable ? 14 : 10),
			child: Material(
				color: cardBg,
				borderRadius: BorderRadius.circular(16),
				clipBehavior: Clip.antiAlias,
				child: InkWell(
					onTap: onTap,
					child: Container(
						decoration: selected
								? BoxDecoration(
										border: Border.all(color: AppColors.brandYellow, width: 2),
										borderRadius: BorderRadius.circular(16),
									)
								: null,
						padding: EdgeInsets.all(pad),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										if (showCheckbox) ...[
											Checkbox(
												value: checked,
												onChanged: (_) => onCheckChanged?.call(),
												side: const BorderSide(color: Colors.white54),
												activeColor: AppColors.brandYellow,
												materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
											),
											const SizedBox(width: 4),
										],
										Expanded(
											child: Wrap(
												spacing: 6,
												runSpacing: 6,
												children: [
													SikaBadge(
														label: OtUi.estadoLabel(estado),
														color: onCard ? Colors.white : color,
													),
													SikaBadge(
														label: tipo.toUpperCase(),
														color: onCard
																? Colors.white.withValues(alpha: 0.65)
																: AppColors.mutedText,
													),
													SikaBadge(
														label: prioridad.toUpperCase(),
														color: onCard
																? Colors.white.withValues(alpha: 0.55)
																: AppColors.secondary,
													),
												],
											),
										),
										if (isRealizada)
											Container(
												width: 32,
												height: 32,
												decoration: BoxDecoration(
													color: Colors.white.withValues(alpha: 0.12),
													shape: BoxShape.circle,
													border: Border.all(
														color: Colors.white.withValues(alpha: 0.35),
													),
												),
												child: const Icon(
													Icons.check_rounded,
													color: Colors.white,
													size: 18,
												),
											),
									],
								),
								SizedBox(height: comfortable ? 14 : 12),
								Text(
									'OT #${ot['numero']}',
									style: TextStyle(
										color: Colors.white,
										fontWeight: FontWeight.w800,
										fontSize: comfortable ? 22 : 20,
									),
								),
								const SizedBox(height: 6),
								Text(
									equipo != null
											? '${equipo['codigo']} — ${equipo['nombre']}'
											: 'Sin equipo',
									maxLines: 2,
									overflow: TextOverflow.ellipsis,
									style: TextStyle(
										color: onCard
												? Colors.white.withValues(alpha: 0.85)
												: AppColors.mutedText,
										fontSize: 14,
										height: 1.3,
									),
								),
								if (ubicacion != null) ...[
									const SizedBox(height: 4),
									Text(
										ubicacion['nombre'] as String? ?? '',
										maxLines: 1,
										overflow: TextOverflow.ellipsis,
										style: TextStyle(
											color: onCard
													? Colors.white.withValues(alpha: 0.65)
													: AppColors.mutedText.withValues(alpha: 0.8),
											fontSize: 13,
										),
									),
								],
								SizedBox(height: comfortable ? 10 : 6),
								Text(
									'Prog: ${formatDate(ot['fechaProgramacion'])}'
											'${ot['fechaEjecucion'] != null ? ' · Ejec: ${formatDate(ot['fechaEjecucion'])}' : ''}',
									style: TextStyle(
										color: onCard
												? Colors.white.withValues(alpha: 0.6)
												: AppColors.mutedText,
										fontSize: 12,
									),
								),
								if (!hideTecnico && tecnico != null) ...[
									const SizedBox(height: 4),
									Text(
										'Recibe: ${tecnico['nombreUsuario']}',
										maxLines: 1,
										overflow: TextOverflow.ellipsis,
										style: TextStyle(
											color: onCard
													? Colors.white.withValues(alpha: 0.75)
													: AppColors.mutedText,
											fontSize: 12,
											fontWeight: FontWeight.w600,
										),
									),
								],
								if (motivo != null) ...[
									const SizedBox(height: 4),
									Text(
										'Motivo: ${motivo['descripcion']}',
										maxLines: 2,
										overflow: TextOverflow.ellipsis,
										style: TextStyle(
											color: onCard
													? AppColors.warning.withValues(alpha: 0.9)
													: AppColors.warning,
											fontSize: 12,
											fontWeight: FontWeight.w600,
										),
									),
								],
								if (gut != '—') ...[
									const SizedBox(height: 4),
									Text(
										'GUT est.: $gut',
										style: TextStyle(
											color: onCard
													? Colors.white.withValues(alpha: 0.55)
													: AppColors.mutedText,
											fontSize: 12,
										),
									),
								],
							],
						),
					),
				),
			),
		);
	}
}

class _OtDetailContent extends StatelessWidget {
	const _OtDetailContent({
		required this.ot,
		required this.canManage,
		required this.canEjecutar,
		required this.canAnular,
		required this.canReabrir,
		required this.canEmitirNoPeriodica,
		required this.formatDate,
		required this.includeActionBar,
		required this.onPdf,
		required this.onIniciar,
		required this.onEjecucion,
		required this.onFirmar,
		required this.onAnular,
		required this.onReabrir,
		required this.onEmitirNoPeriodica,
		required this.onDerivar,
		this.onSolicitarMateriales,
		this.canSolicitarMateriales = false,
		this.ocultarPdf = false,
	});

	final Map<String, dynamic> ot;
	final bool canManage;
	final bool canEjecutar;
	final bool canAnular;
	final bool canReabrir;
	final bool canEmitirNoPeriodica;
	final bool canSolicitarMateriales;
	final bool ocultarPdf;
	final String Function(dynamic) formatDate;
	final bool includeActionBar;
	final VoidCallback onPdf;
	final VoidCallback onIniciar;
	final VoidCallback onEjecucion;
	final VoidCallback onFirmar;
	final VoidCallback onAnular;
	final VoidCallback onReabrir;
	final VoidCallback onEmitirNoPeriodica;
	final VoidCallback onDerivar;
	final VoidCallback? onSolicitarMateriales;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final estado = ot['estado'] as String? ?? '';
		final tipo = ot['tipo'] as String? ?? '';
		final prioridad = ot['prioridad'] as String? ?? 'media';
		final equipo = ot['equipo'] as Map<String, dynamic>?;
		final ubicacion = ot['ubicacion'] as Map<String, dynamic>? ?? equipo?['ubicacion'];
		final procedimiento = ot['procedimiento'] as Map<String, dynamic>?;
		final tecnico = ot['tecnicoAsignado'] as Map<String, dynamic>?;
		final motivo = ot['motivoPendiente'] as Map<String, dynamic>?;
		final historial = (ot['historialEstados'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>();
		final checklist = (ot['checklistCompletado'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>();
		final planilla = (procedimiento?['planillaLecturas'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>();
		final novedades = ot['novedadesFueraDePrograma'] as String?;
		final fotos = (ot['fotos'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

		final estadoColor = OtUi.estadoColor(estado);
		final heroBg = estado == 'realizada'
				? const Color(0xFF14532D)
				: estadoColor;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				ClipRRect(
					borderRadius: BorderRadius.circular(20),
					child: Stack(
						children: [
							Container(
								width: double.infinity,
								padding: EdgeInsets.all(
									MediaQuery.sizeOf(context).width < 600 ? 18 : 24,
								),
								color: heroBg,
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Wrap(
											spacing: 8,
											runSpacing: 8,
											children: [
												SikaBadge(
													label: OtUi.estadoLabel(estado),
													color: Colors.white,
												),
												SikaBadge(
													label: tipo.toUpperCase(),
													color: AppColors.mutedText,
												),
												SikaBadge(
													label: OtUi.prioridadLabel(prioridad),
													color: Colors.white.withValues(alpha: 0.7),
												),
											],
										),
										const SizedBox(height: 16),
										Text(
											'OT #${ot['numero']}',
											style: Theme.of(context).textTheme.headlineMedium?.copyWith(
														color: Colors.white,
														fontWeight: FontWeight.w800,
													),
										),
										const SizedBox(height: 8),
										Text(
											equipo != null
													? '${equipo['codigo']} — ${equipo['nombre']}'
													: 'Sin equipo',
											style: TextStyle(
												color: Colors.white.withValues(alpha: 0.9),
												fontSize: 16,
												height: 1.35,
											),
										),
										if (ubicacion != null) ...[
											const SizedBox(height: 6),
											Text(
												ubicacion['nombre'] as String? ?? '',
												style: TextStyle(
													color: Colors.white.withValues(alpha: 0.7),
													fontSize: 13,
												),
											),
										],
									],
								),
							),
							if (estado == 'realizada')
								Positioned(
									right: 12,
									top: 0,
									bottom: 0,
									child: Icon(
										Icons.check_circle_outline_rounded,
										size: 120,
										color: Colors.white.withValues(alpha: 0.08),
									),
								),
						],
					),
				),
				if (estado == 'realizada' && !ocultarPdf) ...[
					const SizedBox(height: 16),
					Container(
						padding: const EdgeInsets.all(14),
						decoration: BoxDecoration(
							color: AppColors.success.withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(12),
							border: Border.all(
								color: AppColors.success.withValues(alpha: 0.35),
							),
						),
						child: Row(
							children: [
								const Icon(Icons.check_circle_rounded, color: AppColors.success),
								const SizedBox(width: 12),
								Expanded(
									child: Text(
										'OT completada y firmada. Usá «Descargar PDF completado» '
										'para imprimir el documento con checklist, novedades y firma.',
										style: TextStyle(
											color: Colors.white.withValues(alpha: 0.9),
											fontSize: 13,
										),
									),
								),
							],
						),
					),
				],
				const SizedBox(height: 20),
				LayoutBuilder(
					builder: (context, constraints) {
						final cards = [
							_InfoTile(
								icon: Icons.calendar_today_rounded,
								label: 'Programación',
								value: formatDate(ot['fechaProgramacion']),
							),
							_InfoTile(
								icon: Icons.flag_rounded,
								label: 'Prioridad',
								value: OtUi.prioridadLabel(prioridad),
								valueColor: OtUi.prioridadColor(prioridad),
							),
							_InfoTile(
								icon: Icons.person_rounded,
								label: 'Técnico',
								value: tecnico?['nombreUsuario'] as String? ?? 'Sin asignar',
							),
							if (motivo != null)
								_InfoTile(
									icon: Icons.help_outline_rounded,
									label: 'Motivo pendiente',
									value: motivo['descripcion'] as String? ?? '',
									valueColor: AppColors.warning,
								),
							if (procedimiento != null)
								_InfoTile(
									icon: Icons.description_outlined,
									label: 'Procedimiento',
									value: procedimiento['nombre'] as String? ?? '',
								),
							if (procedimiento?['duracionEstimada'] != null)
								_InfoTile(
									icon: Icons.schedule_rounded,
									label: 'GUT estimada',
									value: OtUi.formatDuracionMinutos(procedimiento!['duracionEstimada']),
								),
						];

						final narrow = constraints.maxWidth < 520;
						if (narrow) {
							return Column(
								children: [
									for (var i = 0; i < cards.length; i++) ...[
										SizedBox(width: double.infinity, child: cards[i]),
										if (i < cards.length - 1) const SizedBox(height: 10),
									],
								],
							);
						}

						final gap = 12.0;
						final cols = constraints.maxWidth < 800 ? 2 : 3;
						final itemWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;

						return Wrap(
							spacing: gap,
							runSpacing: gap,
							children: cards
									.map((c) => SizedBox(width: itemWidth, child: c))
									.toList(),
						);
					},
				),
				if (ot['comentarios'] != null &&
						(ot['comentarios'] as String).trim().isNotEmpty) ...[
					const SizedBox(height: 16),
					_DetailCard(
						title: 'Comentarios',
						icon: Icons.notes_rounded,
						child: Text(
							ot['comentarios'] as String,
							style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
						),
					),
				],
				if (novedades != null && novedades.trim().isNotEmpty) ...[
					const SizedBox(height: 16),
					_DetailCard(
						title: 'Novedades del técnico',
						icon: Icons.report_outlined,
						child: Text(
							novedades,
							style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
						),
					),
				],
				if (fotos.isNotEmpty) ...[
					const SizedBox(height: 16),
					_DetailCard(
						title: 'Fotos del trabajo',
						icon: Icons.photo_library_outlined,
						child: Wrap(
							spacing: 8,
							runSpacing: 8,
							children: fotos.map((foto) {
								final url = foto['url'] as String? ?? '';
								final resolved = url.startsWith('http')
										? url
										: '${AppConfig.apiBaseUrl.replaceAll(RegExp(r'/v1/?$'), '')}$url';
								return ClipRRect(
									borderRadius: BorderRadius.circular(10),
									child: Image.network(
										resolved,
										width: 96,
										height: 96,
										fit: BoxFit.cover,
										errorBuilder: (_, __, ___) => Container(
											width: 96,
											height: 96,
											color: AppColors.surfaceMuted,
											child: const Icon(Icons.broken_image_outlined),
										),
									),
								);
							}).toList(),
						),
					),
				],
				if (planilla.isNotEmpty || checklist.isNotEmpty) ...[
					const SizedBox(height: 16),
					_DetailCard(
						title: 'Checklist',
						icon: Icons.checklist_rounded,
						child: Column(
							children: (checklist.isNotEmpty ? checklist : planilla).map((item) {
								final done = item['done'] == true;
								return Padding(
									padding: const EdgeInsets.only(bottom: 8),
									child: Row(
										children: [
											Icon(
												done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
												size: 18,
												color: done ? AppColors.success : scheme.onSurfaceVariant,
											),
											const SizedBox(width: 10),
											Expanded(
												child: Text(
													item['label'] as String? ?? item['key'] as String? ?? '',
													style: TextStyle(
														decoration: done ? TextDecoration.lineThrough : null,
														color: done ? scheme.onSurfaceVariant : null,
													),
												),
											),
										],
									),
								);
							}).toList(),
						),
					),
				],
				const SizedBox(height: 16),
				_DetailCard(
					title: 'Historial de estados',
					icon: Icons.timeline_rounded,
					child: _VerticalTimeline(items: historial),
				),
				const SizedBox(height: 20),
				if (includeActionBar)
					_ActionBar(
						estado: estado,
						canManage: canManage,
						canEjecutar: canEjecutar,
						canAnular: canAnular,
						canReabrir: canReabrir,
						canEmitirNoPeriodica: canEmitirNoPeriodica,
						canSolicitarMateriales: canSolicitarMateriales,
						onPdf: onPdf,
						onIniciar: onIniciar,
						onEjecucion: onEjecucion,
						onFirmar: onFirmar,
						onAnular: onAnular,
						onReabrir: onReabrir,
						onEmitirNoPeriodica: onEmitirNoPeriodica,
						onDerivar: onDerivar,
						onSolicitarMateriales: onSolicitarMateriales,
						ocultarPdf: ocultarPdf,
					),
			],
		);
	}
}

class _InfoTile extends StatelessWidget {
	const _InfoTile({
		required this.icon,
		required this.label,
		required this.value,
		this.valueColor,
	});

	final IconData icon;
	final String label;
	final String value;
	final Color? valueColor;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(14),
			decoration: SikaUi.cardDecoration(),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Icon(icon, size: 18, color: AppColors.accent),
					const SizedBox(height: 8),
					Text(
						label,
						style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
					),
					const SizedBox(height: 2),
					Text(
						value,
						style: TextStyle(
							fontWeight: FontWeight.w700,
							color: valueColor ?? Colors.white,
						),
						maxLines: 2,
						overflow: TextOverflow.ellipsis,
					),
				],
			),
		);
	}
}

class _VerticalTimeline extends StatelessWidget {
	const _VerticalTimeline({required this.items});

	final List<Map<String, dynamic>> items;

	@override
	Widget build(BuildContext context) {
		if (items.isEmpty) {
			return Text(
				'Sin movimientos registrados',
				style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
			);
		}

		return Column(
			children: List.generate(items.length, (index) {
				final item = items[index];
				final isLast = index == items.length - 1;
				final estado = item['estado'] as String? ?? '';
				final color = OtUi.estadoColor(estado);
				final fecha = item['createdAt'] as String?;
				final parsed = fecha != null ? DateTime.tryParse(fecha) : null;

				return IntrinsicHeight(
					child: Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							SizedBox(
								width: 24,
								child: Column(
									children: [
										Container(
											width: 12,
											height: 12,
											decoration: BoxDecoration(
												color: color,
												shape: BoxShape.circle,
												border: Border.all(color: Colors.white, width: 2),
												boxShadow: [
													BoxShadow(
														color: color.withValues(alpha: 0.4),
														blurRadius: 4,
													),
												],
											),
										),
										if (!isLast)
											Expanded(
												child: Container(
													width: 2,
													color: Theme.of(context)
															.colorScheme
															.outlineVariant
															.withValues(alpha: 0.5),
												),
											),
									],
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Padding(
									padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Row(
												children: [
													_EstadoChip(estado: estado, compact: true),
													if (parsed != null) ...[
														const SizedBox(width: 8),
														Text(
															DateFormat('dd/MM HH:mm').format(parsed.toLocal()),
															style: TextStyle(
																fontSize: 11,
																color: Theme.of(context).colorScheme.onSurfaceVariant,
															),
														),
													],
												],
											),
											const SizedBox(height: 4),
											Text(
												item['comentario'] as String? ?? '',
												style: const TextStyle(fontSize: 13),
											),
											if (item['usuario']?['nombreUsuario'] != null)
												Text(
													item['usuario']['nombreUsuario'] as String,
													style: TextStyle(
														fontSize: 12,
														color: Theme.of(context).colorScheme.onSurfaceVariant,
													),
												),
										],
									),
								),
							),
						],
					),
				);
			}),
		);
	}
}

class _ActionBar extends StatelessWidget {
	const _ActionBar({
		required this.estado,
		required this.canManage,
		required this.canEjecutar,
		required this.canAnular,
		required this.canReabrir,
		required this.canEmitirNoPeriodica,
		required this.onPdf,
		required this.onIniciar,
		required this.onEjecucion,
		required this.onFirmar,
		required this.onAnular,
		required this.onReabrir,
		required this.onEmitirNoPeriodica,
		required this.onDerivar,
		this.onSolicitarMateriales,
		this.canSolicitarMateriales = false,
		this.ocultarPdf = false,
	});

	final String estado;
	final bool canManage;
	final bool canEjecutar;
	final bool canAnular;
	final bool canReabrir;
	final bool canEmitirNoPeriodica;
	final bool canSolicitarMateriales;
	final bool ocultarPdf;
	final VoidCallback onPdf;
	final VoidCallback onIniciar;
	final VoidCallback onEjecucion;
	final VoidCallback onFirmar;
	final VoidCallback onAnular;
	final VoidCallback onReabrir;
	final VoidCallback onEmitirNoPeriodica;
	final VoidCallback onDerivar;
	final VoidCallback? onSolicitarMateriales;

	@override
	Widget build(BuildContext context) {
		final narrow = MediaQuery.sizeOf(context).width < 700;
		final minSize = Size(narrow ? double.infinity : 0, 52);
		final pad = const EdgeInsets.symmetric(horizontal: 20, vertical: 14);

		final actions = <Widget>[];

		if (!ocultarPdf && estado == 'realizada') {
			actions.add(
				FilledButton.icon(
					style: FilledButton.styleFrom(
						backgroundColor: AppColors.success,
						minimumSize: minSize,
						padding: pad,
					),
					onPressed: onPdf,
					icon: const Icon(Icons.picture_as_pdf_rounded),
					label: const Text('Descargar PDF completado'),
				),
			);
		}

		if (['pendiente', 'en_ejecucion', 'pendiente_panol'].contains(estado) &&
				canSolicitarMateriales &&
				onSolicitarMateriales != null) {
			actions.add(
				FilledButton.tonalIcon(
					style: FilledButton.styleFrom(minimumSize: minSize, padding: pad),
					onPressed: onSolicitarMateriales,
					icon: const Icon(Icons.inventory_2_outlined),
					label: const Text('Solicitar materiales'),
				),
			);
		}

		if (estado == 'pendiente' && (canManage || canEjecutar)) {
			actions.add(
				FilledButton.icon(
					style: FilledButton.styleFrom(
						backgroundColor: AppColors.accent,
						minimumSize: minSize,
						padding: pad,
					),
					onPressed: onIniciar,
					icon: const Icon(Icons.play_arrow_rounded),
					label: const Text('Iniciar ejecución'),
				),
			);
		}

		if (['pendiente', 'en_ejecucion'].contains(estado) && canEjecutar) {
			actions.add(
				FilledButton.tonalIcon(
					style: FilledButton.styleFrom(minimumSize: minSize, padding: pad),
					onPressed: onEjecucion,
					icon: const Icon(Icons.edit_note_rounded),
					label: const Text('Registrar trabajo'),
				),
			);
		}

		if (['pendiente', 'en_ejecucion'].contains(estado) && canEjecutar) {
			actions.add(
				FilledButton.icon(
					style: FilledButton.styleFrom(
						backgroundColor: AppColors.success,
						minimumSize: minSize,
						padding: pad,
					),
					onPressed: onFirmar,
					icon: const Icon(Icons.draw_rounded),
					label: const Text('Firmar y cerrar'),
				),
			);
		}

		if (canAnular && estado != 'realizada' && estado != 'anulada') {
			actions.add(
				OutlinedButton.icon(
					style: OutlinedButton.styleFrom(
						foregroundColor: AppColors.danger,
						minimumSize: minSize,
						padding: pad,
					),
					onPressed: onAnular,
					icon: const Icon(Icons.cancel_outlined),
					label: const Text('Anular'),
				),
			);
		}

		if (canReabrir && (estado == 'realizada' || estado == 'anulada')) {
			actions.add(
				FilledButton.tonalIcon(
					style: FilledButton.styleFrom(minimumSize: minSize, padding: pad),
					onPressed: onReabrir,
					icon: const Icon(Icons.replay_rounded),
					label: const Text('Reabrir OT'),
				),
			);
		}

		if (canEmitirNoPeriodica && estado == 'realizada') {
			actions.add(
				FilledButton.tonalIcon(
					style: FilledButton.styleFrom(minimumSize: minSize, padding: pad),
					onPressed: onDerivar,
					icon: const Icon(Icons.call_split_rounded),
					label: const Text('OT derivada'),
				),
			);
		}

		if (canEmitirNoPeriodica && (estado == 'realizada' || estado == 'anulada')) {
			actions.add(
				FilledButton.icon(
					style: FilledButton.styleFrom(
						backgroundColor: AppColors.warning,
						minimumSize: minSize,
						padding: pad,
					),
					onPressed: onEmitirNoPeriodica,
					icon: const Icon(Icons.build_circle_outlined),
					label: const Text('Nueva OT no periódica'),
				),
			);
		}

		if (actions.isEmpty) return const SizedBox.shrink();

		return Container(
			padding: EdgeInsets.all(narrow ? 14 : 16),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(
					color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
				),
			),
			child: narrow
					? Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								for (var i = 0; i < actions.length; i++) ...[
									actions[i],
									if (i < actions.length - 1) const SizedBox(height: 10),
								],
							],
						)
					: Wrap(spacing: 10, runSpacing: 10, children: actions),
		);
	}
}

class _DetailCard extends StatelessWidget {
	const _DetailCard({
		required this.title,
		required this.icon,
		required this.child,
	});

	final String title;
	final IconData icon;
	final Widget child;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(18),
			decoration: SikaUi.cardDecoration(),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Icon(icon, size: 18, color: AppColors.accent),
							const SizedBox(width: 8),
							Text(
								title,
								style: const TextStyle(
									fontWeight: FontWeight.w700,
									color: Colors.white,
								),
							),
						],
					),
					const SizedBox(height: 14),
					DefaultTextStyle(
						style: const TextStyle(color: AppColors.mutedText),
						child: child,
					),
				],
			),
		);
	}
}

class _EstadoChip extends StatelessWidget {
	const _EstadoChip({required this.estado, this.compact = false});

	final String estado;
	final bool compact;

	@override
	Widget build(BuildContext context) {
		final color = OtUi.estadoColor(estado);
		return Container(
			padding: EdgeInsets.symmetric(
				horizontal: compact ? 8 : 10,
				vertical: compact ? 3 : 5,
			),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				OtUi.estadoLabel(estado),
				style: TextStyle(
					color: color,
					fontSize: compact ? 11 : 12,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}
}

class _EmptyListState extends StatelessWidget {
	const _EmptyListState({
		required this.hasFiltro,
		this.misOt = false,
	});

	final bool hasFiltro;
	final bool misOt;

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.all(24),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(
							hasFiltro ? Icons.search_off_rounded : Icons.assignment_outlined,
							size: 40,
							color: Theme.of(context).colorScheme.onSurfaceVariant,
						),
						const SizedBox(height: 12),
						Text(
							hasFiltro
									? 'Sin resultados'
									: misOt
											? 'No tenés OT asignadas'
											: 'No hay OT',
							style: const TextStyle(fontWeight: FontWeight.w600),
						),
						const SizedBox(height: 4),
						Text(
							hasFiltro
									? 'Probá con otro filtro o búsqueda'
									: misOt
											? 'Cuando te asignen una orden, va a aparecer acá. Deslizá hacia abajo para actualizar.'
											: 'Las órdenes aparecerán acá',
							style: TextStyle(
								fontSize: 13,
								color: Theme.of(context).colorScheme.onSurfaceVariant,
							),
							textAlign: TextAlign.center,
						),
					],
				),
			),
		);
	}
}

class _EmptyDetailState extends StatelessWidget {
	const _EmptyDetailState();

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.all(32),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Container(
							width: 72,
							height: 72,
							decoration: BoxDecoration(
								color: AppColors.accent.withValues(alpha: 0.1),
								borderRadius: BorderRadius.circular(20),
							),
							child: const Icon(
								Icons.assignment_rounded,
								size: 36,
								color: AppColors.accent,
							),
						),
						const SizedBox(height: 16),
						Text(
							'Seleccioná una OT',
							style: Theme.of(context).textTheme.titleLarge?.copyWith(
										fontWeight: FontWeight.w700,
									),
						),
						const SizedBox(height: 8),
						Text(
							'Elegí una orden del listado para ver el detalle,\n'
							'el historial y las acciones disponibles.',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: Theme.of(context).colorScheme.onSurfaceVariant,
							),
						),
					],
				),
			),
		);
	}
}
