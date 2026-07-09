import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/collapsible_panel.dart';
import '../../../core/theme/app_colors.dart';
import '../../planta/presentation/planta_equipo_picker_dialog.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';

class ProcedimientosPage extends ConsumerStatefulWidget {
	const ProcedimientosPage({super.key});

	@override
	ConsumerState<ProcedimientosPage> createState() => _ProcedimientosPageState();
}

class _ProcedimientosPageState extends ConsumerState<ProcedimientosPage> {
	static const _accent = Color(0xFF0F766E);
	static const _listExpandedWidth = 360.0;
	static const _listCollapsedWidth = 56.0;

	List<Map<String, dynamic>> _procedimientos = [];
	Map<String, dynamic>? _selected;
	bool _loading = true;
	bool _saving = false;
	bool _creating = false;
	bool _listCollapsed = false;
	String? _error;
	String _search = '';

	AuthUser? get _user => ref.read(authControllerProvider).session?.usuario;

	bool get _canListar =>
			_user?.tieneDerecho('archivos.procedimientos.listar') == true ||
			_user?.esAdministrador == true;

	bool get _canAgregar =>
			_user?.tieneDerecho('archivos.procedimientos.agregar') == true ||
			_user?.esAdministrador == true;

	bool get _canModificar =>
			_user?.tieneDerecho('archivos.procedimientos.modificar') == true ||
			_user?.esAdministrador == true;

	bool get _canAsociar =>
			_user?.tieneDerecho('archivos.procedimientos.asociar_a_equipo') == true ||
			_user?.esAdministrador == true;

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
			if (_user?.sucursalId == null) {
				throw Exception('Tu usuario no tiene planta asignada.');
			}

			final api = ref.read(apiClientProvider);
			final sucursalId = _user!.sucursalId!;
			final procedimientos =
					(await api.getList('procedimientos?sucursalId=$sucursalId'))
							.cast<Map<String, dynamic>>();

			if (!mounted) return;
			setState(() => _procedimientos = procedimientos);
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	List<Map<String, dynamic>> get _filtrados {
		if (_search.isEmpty) return _procedimientos;
		final q = _search.toLowerCase();
		return _procedimientos.where((p) {
			final codigo = '${p['codigo'] ?? ''}';
			final nombre = (p['nombre'] as String? ?? '').toLowerCase();
			final tipo = (p['tipo'] as String? ?? '').toLowerCase();
			return codigo.contains(q) || nombre.contains(q) || tipo.contains(q);
		}).toList();
	}

	void _nuevo() {
		setState(() {
			_creating = true;
			_selected = null;
		});
	}

	void _toggleListPanel() => setState(() => _listCollapsed = !_listCollapsed);

	Future<void> _seleccionar(Map<String, dynamic> proc) async {
		setState(() {
			_creating = false;
			_selected = null;
		});
		try {
			final detalle =
					await ref.read(apiClientProvider).getJson('procedimientos/${proc['id']}');
			if (!mounted) return;
			setState(() => _selected = detalle);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	Future<void> _guardar(Map<String, dynamic> payload, {String? id}) async {
		setState(() => _saving = true);
		try {
			final api = ref.read(apiClientProvider);
			final result = id == null
					? await api.postJson('procedimientos', payload)
					: await api.patchJson('procedimientos/$id', payload);

			await _bootstrap();
			if (!mounted) return;

			setState(() {
				_creating = false;
				_selected = result;
			});

			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(
						id == null
								? 'Procedimiento #${result['codigo']} creado'
								: 'Procedimiento #${result['codigo']} actualizado',
					),
				),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		} finally {
			if (mounted) setState(() => _saving = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		if (!_canListar) {
			return const Center(child: Text('No tenés permiso para ver procedimientos.'));
		}

		if (_loading) {
			return const Center(child: CircularProgressIndicator());
		}

		if (_error != null) {
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(_error!, textAlign: TextAlign.center),
						const SizedBox(height: 12),
						FilledButton(onPressed: _bootstrap, child: const Text('Reintentar')),
					],
				),
			);
		}

		final wide = MediaQuery.sizeOf(context).width >= 960;
		if (!wide) return _buildMobile(context);

		final showForm = _creating || _selected != null;
		if (!showForm) {
			return _buildListPanel(context);
		}

		return Row(
			children: [
				AnimatedContainer(
					duration: const Duration(milliseconds: 220),
					curve: Curves.easeOutCubic,
					width: _listCollapsed ? _listCollapsedWidth : _listExpandedWidth,
					child: _buildListPanel(context, collapsed: _listCollapsed),
				),
				_buildListDivider(context),
				Expanded(child: _buildFormPanel(context)),
			],
		);
	}

	Widget _buildListDivider(BuildContext context) {
		return PanelCollapseHandle(
			collapsed: _listCollapsed,
			onToggle: _toggleListPanel,
			edge: PanelCollapseEdge.start,
			expandTooltip: 'Expandir listado',
			collapseTooltip: 'Contraer listado',
		);
	}

	Widget _buildMobile(BuildContext context) {
		if (_creating || _selected != null) {
			return Column(
				children: [
					Material(
						color: Theme.of(context).colorScheme.surface,
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 4),
							child: Row(
								children: [
									IconButton(
										onPressed: () => setState(() {
											_creating = false;
											_selected = null;
										}),
										icon: const Icon(Icons.arrow_back_rounded),
									),
									Text(
										_creating
												? 'Nuevo procedimiento'
												: 'Proc. #${_selected?['codigo']}',
										style: const TextStyle(fontWeight: FontWeight.w700),
									),
								],
							),
						),
					),
					Expanded(child: _buildFormPanel(context)),
				],
			);
		}
		return _buildListPanel(context);
	}

	Widget _buildListPanel(BuildContext context, {bool collapsed = false}) {
		final scheme = Theme.of(context).colorScheme;

		if (collapsed) {
			return Material(
				color: scheme.surface,
				child: Column(
					children: [
						Padding(
							padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
							child: Column(
								children: [
									Icon(Icons.description_rounded, color: _accent, size: 22),
									if (_canAgregar) ...[
										const SizedBox(height: 8),
										IconButton(
											tooltip: 'Nuevo procedimiento',
											onPressed: _nuevo,
											style: IconButton.styleFrom(
												backgroundColor: _accent.withValues(alpha: 0.12),
											),
											icon: const Icon(Icons.add_rounded, size: 20),
										),
									],
								],
							),
						),
						Expanded(
							child: _filtrados.isEmpty
									? const SizedBox.shrink()
									: ListView.builder(
											padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
											itemCount: _filtrados.length,
											itemBuilder: (context, index) {
												final proc = _filtrados[index];
												final selected =
														_selected?['id'] == proc['id'] && !_creating;
												return _ProcCompactTile(
													proc: proc,
													selected: selected,
													onTap: () => _seleccionar(proc),
												);
											},
										),
						),
					],
				),
			);
		}

		return Material(
			color: scheme.surface,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
						child: Row(
							children: [
								Expanded(
									child: Text(
										'Procedimientos',
										style: Theme.of(context).textTheme.titleLarge?.copyWith(
													fontWeight: FontWeight.w700,
												),
									),
								),
								if (_canAgregar)
									FilledButton.icon(
										style: FilledButton.styleFrom(backgroundColor: _accent),
										onPressed: _nuevo,
										icon: const Icon(Icons.add_rounded, size: 18),
										label: const Text('Nuevo'),
									),
							],
						),
					),
					if (_user?.sucursalNombre != null)
						Padding(
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
							child: Container(
								padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
								decoration: BoxDecoration(
									color: _accent.withValues(alpha: 0.1),
									borderRadius: BorderRadius.circular(999),
								),
								child: Text(
									_user!.sucursalNombre!,
									style: const TextStyle(
										color: _accent,
										fontWeight: FontWeight.w600,
										fontSize: 12,
									),
								),
							),
						),
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 16),
						child: TextField(
							decoration: InputDecoration(
								hintText: 'Buscar por código, nombre o tipo…',
								prefixIcon: const Icon(Icons.search_rounded, size: 20),
								isDense: true,
								filled: true,
								fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
								border: OutlineInputBorder(
									borderRadius: BorderRadius.circular(12),
									borderSide: BorderSide.none,
								),
							),
							onChanged: (value) => setState(() => _search = value),
						),
					),
					const SizedBox(height: 10),
					Expanded(
						child: _filtrados.isEmpty
								? const Center(child: Text('Sin procedimientos'))
								: ListView.builder(
										padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
										itemCount: _filtrados.length,
										itemBuilder: (context, index) {
											final proc = _filtrados[index];
											final selected =
													_selected?['id'] == proc['id'] && !_creating;
											return _ProcListTile(
												proc: proc,
												selected: selected,
												onTap: () => _seleccionar(proc),
											);
										},
									),
					),
				],
			),
		);
	}

	Widget _buildFormPanel(BuildContext context) {
		if (!_creating && _selected == null) {
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(
							Icons.description_outlined,
							size: 56,
							color: Theme.of(context).colorScheme.onSurfaceVariant,
						),
						const SizedBox(height: 12),
						const Text('Seleccioná un procedimiento o creá uno nuevo'),
						if (_canAgregar) ...[
							const SizedBox(height: 16),
							FilledButton.icon(
								style: FilledButton.styleFrom(backgroundColor: _accent),
								onPressed: _nuevo,
								icon: const Icon(Icons.add_rounded),
								label: const Text('Nuevo procedimiento'),
							),
						],
					],
				),
			);
		}

		return _ProcedimientoForm(
			key: ValueKey(_creating ? 'new' : _selected!['id']),
			plantaNombre: _user?.sucursalNombre ?? 'Planta',
			initial: _creating ? null : _selected,
			saving: _saving,
			canSave: _creating ? _canAgregar : _canModificar,
			canAsociar: _canAsociar,
			onEquiposChanged: () async {
				if (_selected?['id'] != null) {
					await _seleccionar({'id': _selected!['id'] as String});
				}
			},
			onCancel: () => setState(() {
				_creating = false;
				_selected = null;
			}),
			onSave: _guardar,
			onReservaMateriales: () {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(
						content: Text('Reserva de materiales — disponible cuando se implemente Pañol (M4)'),
					),
				);
			},
		);
	}
}

class _ProcListTile extends StatelessWidget {
	const _ProcListTile({
		required this.proc,
		required this.selected,
		required this.onTap,
	});

	final Map<String, dynamic> proc;
	final bool selected;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final tipo = proc['tipo'] as String? ?? '';
		final codigo = proc['codigo'];

		return Padding(
			padding: const EdgeInsets.only(bottom: 6),
			child: Material(
				color: selected
						? const Color(0xFF0F766E).withValues(alpha: 0.1)
						: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
				borderRadius: BorderRadius.circular(14),
				child: InkWell(
					onTap: onTap,
					borderRadius: BorderRadius.circular(14),
					child: Padding(
						padding: const EdgeInsets.all(14),
						child: Row(
							children: [
								Container(
									width: 44,
									height: 44,
									decoration: BoxDecoration(
										color: _ProcUi.tipoColor(tipo).withValues(alpha: 0.15),
										borderRadius: BorderRadius.circular(12),
									),
									child: Center(
										child: Text(
											'$codigo',
											style: TextStyle(
												fontWeight: FontWeight.w800,
												fontSize: 13,
												color: _ProcUi.tipoColor(tipo),
											),
										),
									),
								),
								const SizedBox(width: 12),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												proc['nombre'] as String? ?? '',
												style: const TextStyle(fontWeight: FontWeight.w700),
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
											),
											const SizedBox(height: 4),
											Text(
												[
													_ProcUi.tipoLabel(tipo),
													_ProcUi.periodicidadLabel(proc),
												].where((s) => s.isNotEmpty).join(' · '),
												style: TextStyle(
													fontSize: 12,
													color: scheme.onSurfaceVariant,
												),
											),
										],
									),
								),
							],
						),
					),
				),
			),
		);
	}
}

class _ProcCompactTile extends StatelessWidget {
	const _ProcCompactTile({
		required this.proc,
		required this.selected,
		required this.onTap,
	});

	final Map<String, dynamic> proc;
	final bool selected;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final tipo = proc['tipo'] as String? ?? '';
		final codigo = proc['codigo'];
		final nombre = proc['nombre'] as String? ?? '';

		return Padding(
			padding: const EdgeInsets.only(bottom: 6),
			child: Tooltip(
				message: '$codigo — $nombre',
				waitDuration: const Duration(milliseconds: 400),
				child: Material(
					color: selected
							? const Color(0xFF0F766E).withValues(alpha: 0.18)
							: Colors.transparent,
					borderRadius: BorderRadius.circular(10),
					child: InkWell(
						onTap: onTap,
						borderRadius: BorderRadius.circular(10),
						child: Container(
							width: 40,
							height: 40,
							alignment: Alignment.center,
							decoration: BoxDecoration(
								color: _ProcUi.tipoColor(tipo).withValues(alpha: 0.15),
								borderRadius: BorderRadius.circular(10),
								border: selected
										? Border.all(color: const Color(0xFF0F766E), width: 2)
										: null,
							),
							child: Text(
								'$codigo',
								style: TextStyle(
									fontWeight: FontWeight.w800,
									fontSize: 11,
									color: _ProcUi.tipoColor(tipo),
								),
							),
						),
					),
				),
			),
		);
	}
}

class _ProcedimientoForm extends ConsumerStatefulWidget {
	const _ProcedimientoForm({
		super.key,
		required this.plantaNombre,
		required this.saving,
		required this.canSave,
		required this.onCancel,
		required this.onSave,
		required this.onReservaMateriales,
		this.canAsociar = false,
		this.onEquiposChanged,
		this.initial,
	});

	final String plantaNombre;
	final Map<String, dynamic>? initial;
	final bool saving;
	final bool canSave;
	final bool canAsociar;
	final VoidCallback onCancel;
	final Future<void> Function(Map<String, dynamic> payload, {String? id}) onSave;
	final VoidCallback onReservaMateriales;
	final Future<void> Function()? onEquiposChanged;

	@override
	ConsumerState<_ProcedimientoForm> createState() => _ProcedimientoFormState();
}

class _ProcedimientoFormState extends ConsumerState<_ProcedimientoForm> {
	static const _tipos = [
		('correctivo', 'Correctivo'),
		('mejora', 'Mejora'),
		('preventivo', 'Preventivo'),
		('preventivo_no_periodico', 'Preventivo no periódico'),
	];

	String _tipo = 'correctivo';
	final _descripcionCtrl = TextEditingController();
	final _observacionesCtrl = TextEditingController();
	final List<TextEditingController> _planillaKeyCtrls = [];
	final List<TextEditingController> _planillaLabelCtrls = [];
	int _hhHoras = 0;
	int _hhMinutos = 0;
	int _cantOperarios = 1;
	int _durHoras = 0;
	int _durMinutos = 0;
	int _indHoras = 0;
	int _indMinutos = 0;
	final _costoCtrl = TextEditingController(text: '0');
	bool _periodicidadActiva = false;
	String _periodicidadModo = 'tiempo';
	final _periodicidadDiasCtrl = TextEditingController(text: '30');
	String _criterio = 'fecha_finalizacion';
	final _toleranciaCtrl = TextEditingController(text: '0');

	bool get _esPreventivo => _tipo == 'preventivo';
	bool get _sinPeriodicidad => _tipo == 'preventivo_no_periodico';
	bool get _periodicidadHabilitada => !_sinPeriodicidad;

	String get _sectorResponsableLabel => widget.plantaNombre.isNotEmpty
			? 'SIKA SAIC · ${widget.plantaNombre}'
			: 'SIKA SAIC';

	@override
	void initState() {
		super.initState();
		_applyInitial(widget.initial);
	}

	@override
	void dispose() {
		_descripcionCtrl.dispose();
		_observacionesCtrl.dispose();
		for (final ctrl in _planillaKeyCtrls) {
			ctrl.dispose();
		}
		for (final ctrl in _planillaLabelCtrls) {
			ctrl.dispose();
		}
		_costoCtrl.dispose();
		_periodicidadDiasCtrl.dispose();
		_toleranciaCtrl.dispose();
		super.dispose();
	}

	void _clearPlanillaControllers() {
		for (final ctrl in _planillaKeyCtrls) {
			ctrl.dispose();
		}
		for (final ctrl in _planillaLabelCtrls) {
			ctrl.dispose();
		}
		_planillaKeyCtrls.clear();
		_planillaLabelCtrls.clear();
	}

	void _setPlanillaFromData(List<dynamic> items) {
		_clearPlanillaControllers();
		for (final item in items) {
			final map = item as Map<String, dynamic>;
			_planillaKeyCtrls.add(TextEditingController(text: '${map['key'] ?? ''}'));
			_planillaLabelCtrls.add(TextEditingController(text: '${map['label'] ?? ''}'));
		}
	}

	void _applyInitial(Map<String, dynamic>? data) {
		if (data == null) {
			_clearPlanillaControllers();
			return;
		}

		_tipo = data['tipo'] as String? ?? 'correctivo';
		_descripcionCtrl.text = data['descripcion'] as String? ?? '';
		_observacionesCtrl.text = data['observaciones'] as String? ?? '';
		_setPlanillaFromData(data['planillaLecturas'] as List<dynamic>? ?? []);

		final hsHombre = _toDouble(data['hsHombre']);
		_hhHoras = hsHombre.floor();
		_hhMinutos = ((hsHombre - _hhHoras) * 60).round();

		_cantOperarios = data['cantOperarios'] as int? ?? 1;

		final dur = data['duracionEstimada'] as int? ?? 0;
		_durHoras = dur ~/ 60;
		_durMinutos = dur % 60;

		final ind = data['indisponibilidadEstimada'] as int? ?? 0;
		_indHoras = ind ~/ 60;
		_indMinutos = ind % 60;

		_costoCtrl.text = '${_toDouble(data['costoEstimado'])}';

		_periodicidadActiva =
				data['periodicidadTipo'] != null && data['periodicidadValor'] != null;
		_periodicidadModo = data['periodicidadTipo'] as String? ?? 'tiempo';
		_periodicidadDiasCtrl.text = '${data['periodicidadValor'] ?? 30}';
		_criterio = data['criterioProgramacion'] as String? ?? 'fecha_finalizacion';
		_toleranciaCtrl.text = '${data['tolerancia'] ?? 0}';
	}

	double _toDouble(dynamic value) {
		if (value == null) return 0;
		if (value is num) return value.toDouble();
		return double.tryParse(value.toString()) ?? 0;
	}

	int _toMinutes(int hours, int minutes) => hours * 60 + minutes;

	double _toHsHombre() => _hhHoras + (_hhMinutos / 60);

	void _agregarPlanillaItem() {
		setState(() {
			_planillaKeyCtrls.add(
				TextEditingController(text: 'item_${_planillaKeyCtrls.length + 1}'),
			);
			_planillaLabelCtrls.add(TextEditingController());
		});
	}

	void _quitarPlanillaItem(int index) {
		setState(() {
			_planillaKeyCtrls.removeAt(index).dispose();
			_planillaLabelCtrls.removeAt(index).dispose();
		});
	}

	Future<void> _submit() async {
		if (_descripcionCtrl.text.trim().isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('La descripción es obligatoria')),
			);
			return;
		}

		if (_esPreventivo) {
			if (!_periodicidadActiva) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(
						content: Text('Los preventivos requieren periodicidad en días'),
					),
				);
				return;
			}
			final dias = int.tryParse(_periodicidadDiasCtrl.text);
			if (dias == null || dias < 1) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Indicá la periodicidad en días')),
				);
				return;
			}
		} else if (_periodicidadActiva && _periodicidadHabilitada) {
			final dias = int.tryParse(_periodicidadDiasCtrl.text);
			if (dias == null || dias < 1) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Indicá la periodicidad en días')),
				);
				return;
			}
		}

		final payload = <String, dynamic>{
			'tipo': _tipo,
			'descripcion': _descripcionCtrl.text.trim(),
			if (_observacionesCtrl.text.trim().isNotEmpty)
				'observaciones': _observacionesCtrl.text.trim(),
			'planillaLecturas': [
				for (var i = 0; i < _planillaLabelCtrls.length; i++)
					if (_planillaLabelCtrls[i].text.trim().isNotEmpty)
						{
							'key': _planillaKeyCtrls[i].text.trim().isNotEmpty
									? _planillaKeyCtrls[i].text.trim()
									: _planillaLabelCtrls[i].text
											.trim()
											.toLowerCase()
											.replaceAll(' ', '_'),
							'label': _planillaLabelCtrls[i].text.trim(),
							'done': false,
						},
			],
			'hsHombre': _toHsHombre(),
			'cantOperarios': _cantOperarios,
			'duracionEstimada': _toMinutes(_durHoras, _durMinutos),
			'indisponibilidadEstimada': _toMinutes(_indHoras, _indMinutos),
			'costoEstimado': double.tryParse(_costoCtrl.text.replaceAll(',', '.')) ?? 0,
			'tolerancia': int.tryParse(_toleranciaCtrl.text) ?? 0,
		};

		if (_periodicidadActiva && _periodicidadHabilitada) {
			payload['periodicidadTipo'] = _periodicidadModo;
			payload['periodicidadValor'] = int.parse(_periodicidadDiasCtrl.text);
			if (_periodicidadModo == 'tiempo') {
				payload['criterioProgramacion'] = _criterio;
			}
		}

		await widget.onSave(
			payload,
			id: widget.initial?['id'] as String?,
		);
	}

	@override
	Widget build(BuildContext context) {
		final codigo = widget.initial?['codigo'];
		final isNew = widget.initial == null;

		return ListView(
			padding: const EdgeInsets.all(24),
			children: [
				Container(
					padding: const EdgeInsets.all(24),
					decoration: BoxDecoration(
						gradient: const LinearGradient(
							colors: [Color(0xFF115E59), Color(0xFF0F766E)],
							begin: Alignment.topLeft,
							end: Alignment.bottomRight,
						),
						borderRadius: BorderRadius.circular(20),
					),
					child: Row(
						children: [
							Container(
								width: 52,
								height: 52,
								decoration: BoxDecoration(
									color: Colors.white.withValues(alpha: 0.18),
									borderRadius: BorderRadius.circular(14),
								),
								child: const Icon(Icons.description_rounded, color: Colors.white),
							),
							const SizedBox(width: 16),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											isNew
													? 'Nuevo procedimiento'
													: 'Procedimiento #$codigo',
											style: Theme.of(context).textTheme.titleLarge?.copyWith(
														color: Colors.white,
														fontWeight: FontWeight.w800,
													),
										),
										const SizedBox(height: 4),
										Text(
											'Planta: ${widget.plantaNombre}',
											style: TextStyle(
												color: Colors.white.withValues(alpha: 0.85),
												fontSize: 13,
											),
										),
									],
								),
							),
						],
					),
				),
				const SizedBox(height: 20),
				_SectionCard(
					title: 'Datos generales',
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							InputDecorator(
								decoration: const InputDecoration(
									labelText: 'Sector responsable',
									border: OutlineInputBorder(),
									helperText: 'La empresa es responsable del procedimiento',
								),
								child: Text(
									_sectorResponsableLabel,
									style: const TextStyle(fontWeight: FontWeight.w600),
								),
							),
							const SizedBox(height: 16),
							DropdownButtonFormField<String>(
								value: _tipo,
								decoration: const InputDecoration(
									labelText: 'Tipo de procedimiento',
									border: OutlineInputBorder(),
								),
								items: _tipos
										.map(
											(t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)),
										)
										.toList(),
								onChanged: (value) {
									if (value == null) return;
									setState(() {
										_tipo = value;
										if (value == 'preventivo') {
											_periodicidadActiva = true;
										} else if (value == 'preventivo_no_periodico') {
											_periodicidadActiva = false;
										}
									});
								},
							),
							const SizedBox(height: 16),
							TextField(
								controller: _observacionesCtrl,
								decoration: const InputDecoration(
									labelText: 'Observaciones',
									alignLabelWithHint: true,
									border: OutlineInputBorder(),
									hintText: 'Notas internas del procedimiento',
								),
								maxLines: 3,
							),
							const SizedBox(height: 16),
							TextField(
								controller: _descripcionCtrl,
								decoration: const InputDecoration(
									labelText: 'Descripción',
									alignLabelWithHint: true,
									border: OutlineInputBorder(),
								),
								maxLines: 5,
							),
							const SizedBox(height: 16),
							OutlinedButton.icon(
								onPressed: widget.onReservaMateriales,
								icon: const Icon(Icons.inventory_2_outlined, size: 18),
								label: const Text('Reserva de materiales'),
							),
						],
					),
				),
				const SizedBox(height: 16),
				_SectionCard(
					title: 'Planilla de lecturas',
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							Text(
								'Ítems que el técnico debe completar al cerrar la OT',
								style: TextStyle(
									fontSize: 13,
									color: Theme.of(context).colorScheme.onSurfaceVariant,
								),
							),
							const SizedBox(height: 12),
							if (_planillaLabelCtrls.isEmpty)
								Text(
									'Sin ítems definidos',
									style: TextStyle(
										color: Theme.of(context).colorScheme.onSurfaceVariant,
									),
								)
							else
								...List.generate(_planillaLabelCtrls.length, (index) {
									return Padding(
										padding: const EdgeInsets.only(bottom: 10),
										child: Row(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Expanded(
													flex: 2,
													child: TextField(
														controller: _planillaKeyCtrls[index],
														decoration: const InputDecoration(
															labelText: 'Clave',
															border: OutlineInputBorder(),
															isDense: true,
														),
													),
												),
												const SizedBox(width: 8),
												Expanded(
													flex: 4,
													child: TextField(
														controller: _planillaLabelCtrls[index],
														decoration: const InputDecoration(
															labelText: 'Descripción',
															border: OutlineInputBorder(),
															isDense: true,
														),
													),
												),
												IconButton(
													tooltip: 'Quitar ítem',
													onPressed: () => _quitarPlanillaItem(index),
													icon: const Icon(Icons.close_rounded, size: 20),
												),
											],
										),
									);
								}),
							Align(
								alignment: Alignment.centerLeft,
								child: TextButton.icon(
									onPressed: _agregarPlanillaItem,
									icon: const Icon(Icons.add_rounded, size: 18),
									label: const Text('Agregar ítem'),
								),
							),
						],
					),
				),
				const SizedBox(height: 16),
				_SectionCard(
					title: 'Valores estimados',
					child: Column(
						children: [
							Row(
								children: [
									Expanded(
										child: _TimeField(
											label: 'H.H. necesarias',
											hours: _hhHoras,
											minutes: _hhMinutos,
											onChanged: (h, m) => setState(() {
												_hhHoras = h;
												_hhMinutos = m;
											}),
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: TextFormField(
											initialValue: '$_cantOperarios',
											decoration: const InputDecoration(
												labelText: 'Cant. operarios',
												border: OutlineInputBorder(),
											),
											keyboardType: TextInputType.number,
											inputFormatters: [FilteringTextInputFormatter.digitsOnly],
											onChanged: (v) =>
													_cantOperarios = int.tryParse(v) ?? 1,
										),
									),
								],
							),
							const SizedBox(height: 16),
							Row(
								children: [
									Expanded(
										child: _TimeField(
											label: 'Duración (hs)',
											hours: _durHoras,
											minutes: _durMinutos,
											onChanged: (h, m) => setState(() {
												_durHoras = h;
												_durMinutos = m;
											}),
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: _TimeField(
											label: 'Indisponibilidad',
											hours: _indHoras,
											minutes: _indMinutos,
											onChanged: (h, m) => setState(() {
												_indHoras = h;
												_indMinutos = m;
											}),
										),
									),
								],
							),
							const SizedBox(height: 16),
							TextFormField(
								controller: _costoCtrl,
								decoration: const InputDecoration(
									labelText: 'Costo estimado',
									border: OutlineInputBorder(),
									prefixText: '\$ ',
								),
								keyboardType: const TextInputType.numberWithOptions(decimal: true),
							),
						],
					),
				),
				const SizedBox(height: 16),
				_SectionCard(
					title: 'Periodicidad',
					child: _sinPeriodicidad
							? Text(
									'No aplica para procedimientos preventivos no periódicos.',
									style: TextStyle(
										color: Theme.of(context).colorScheme.onSurfaceVariant,
									),
								)
							: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										CheckboxListTile(
											contentPadding: EdgeInsets.zero,
											value: _periodicidadActiva && _periodicidadModo == 'tiempo',
											onChanged: (value) => setState(() {
												_periodicidadActiva = value ?? false;
												if (_periodicidadActiva) _periodicidadModo = 'tiempo';
											}),
											title: const Text('Tiempo'),
											subtitle: const Text('Cada cuántos días debe realizarse'),
											controlAffinity: ListTileControlAffinity.leading,
										),
										if (_periodicidadActiva && _periodicidadModo == 'tiempo')
											Padding(
												padding: const EdgeInsets.only(left: 16, bottom: 12),
												child: Row(
													children: [
														SizedBox(
															width: 100,
															child: TextField(
																controller: _periodicidadDiasCtrl,
																decoration: const InputDecoration(
																	labelText: 'Día/s',
																	border: OutlineInputBorder(),
																	isDense: true,
																),
																keyboardType: TextInputType.number,
																inputFormatters: [
																	FilteringTextInputFormatter.digitsOnly,
																],
															),
														),
														const SizedBox(width: 8),
														const Expanded(
															child: Text(
																'días entre cada ejecución programada',
																style: TextStyle(fontSize: 13),
															),
														),
													],
												),
											),
										CheckboxListTile(
											contentPadding: EdgeInsets.zero,
											value: _periodicidadActiva && _periodicidadModo == 'contador',
											onChanged: (value) => setState(() {
												_periodicidadActiva = value ?? false;
												if (_periodicidadActiva) _periodicidadModo = 'contador';
											}),
											title: const Text('Contador'),
											subtitle: const Text(
												'Umbral en unidades del contador (horas, km…)',
											),
											controlAffinity: ListTileControlAffinity.leading,
										),
										if (_periodicidadActiva && _periodicidadModo == 'contador')
											Padding(
												padding: const EdgeInsets.only(left: 16, bottom: 12),
												child: Row(
													children: [
														SizedBox(
															width: 100,
															child: TextField(
																controller: _periodicidadDiasCtrl,
																decoration: const InputDecoration(
																	labelText: 'Umbral',
																	border: OutlineInputBorder(),
																	isDense: true,
																),
																keyboardType: TextInputType.number,
																inputFormatters: [
																	FilteringTextInputFormatter.digitsOnly,
																],
															),
														),
														const SizedBox(width: 8),
														const Expanded(
															child: Text(
																'unidades desde la última OT realizada',
																style: TextStyle(fontSize: 13),
															),
														),
													],
												),
											),
										const SizedBox(height: 8),
										if (_periodicidadActiva && _periodicidadModo == 'tiempo') ...[
										Text(
											'Criterio a utilizar para programar',
											style: Theme.of(context).textTheme.titleSmall?.copyWith(
														fontWeight: FontWeight.w700,
													),
										),
										const SizedBox(height: 8),
										RadioListTile<String>(
											contentPadding: EdgeInsets.zero,
											value: 'fecha_finalizacion',
											groupValue: _criterio,
											onChanged: _periodicidadActiva
													? (value) {
															if (value != null) {
																setState(() => _criterio = value);
															}
														}
													: null,
											title: const Text('Fecha de finalización'),
											subtitle: const Text(
												'Cuenta la periodicidad desde que se cerró la OT',
											),
										),
										RadioListTile<String>(
											contentPadding: EdgeInsets.zero,
											value: 'fecha_inicio',
											groupValue: _criterio,
											onChanged: _periodicidadActiva
													? (value) {
															if (value != null) {
																setState(() => _criterio = value);
															}
														}
													: null,
											title: const Text('Fecha de inicio'),
											subtitle: const Text(
												'Cuenta la periodicidad desde la fecha programada',
											),
										),
										],
									],
								),
				),
				const SizedBox(height: 16),
				_SectionCard(
					title: 'Tolerancia',
					child: Row(
						children: [
							SizedBox(
								width: 120,
								child: TextField(
									controller: _toleranciaCtrl,
									decoration: const InputDecoration(
										labelText: 'Días',
										border: OutlineInputBorder(),
									),
									keyboardType: TextInputType.number,
									inputFormatters: [FilteringTextInputFormatter.digitsOnly],
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Text(
									'Días de tolerancia para realizar el procedimiento',
									style: TextStyle(
										fontSize: 13,
										color: Theme.of(context).colorScheme.onSurfaceVariant,
									),
								),
							),
						],
					),
				),
				if (!isNew && widget.initial != null) ...[
					const SizedBox(height: 20),
					_EquiposAsociadosCard(
						procedimiento: widget.initial!,
						canAsociar: widget.canAsociar,
						onChanged: widget.onEquiposChanged,
					),
				],
				const SizedBox(height: 24),
				Row(
					children: [
						OutlinedButton(
							onPressed: widget.saving ? null : widget.onCancel,
							child: const Text('Cancelar'),
						),
						const Spacer(),
						FilledButton.icon(
							style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
							onPressed: widget.saving || !widget.canSave ? null : _submit,
							icon: widget.saving
									? const SizedBox(
											width: 18,
											height: 18,
											child: CircularProgressIndicator(
												strokeWidth: 2,
												color: Colors.white,
											),
										)
									: const Icon(Icons.save_rounded, size: 18),
							label: Text(isNew ? 'Crear procedimiento' : 'Guardar cambios'),
						),
					],
				),
			],
		);
	}
}

class _SectionCard extends StatelessWidget {
	const _SectionCard({required this.title, required this.child});

	final String title;
	final Widget child;

	@override
	Widget build(BuildContext context) {
		return Material(
			color: Theme.of(context).colorScheme.surface,
			borderRadius: BorderRadius.circular(20),
			child: Container(
				padding: const EdgeInsets.all(20),
				decoration: BoxDecoration(
					borderRadius: BorderRadius.circular(20),
					border: Border.all(
						color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
					),
				),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Text(
							title,
							style: Theme.of(context).textTheme.titleMedium?.copyWith(
										fontWeight: FontWeight.w700,
									),
						),
						const SizedBox(height: 16),
						child,
					],
				),
			),
		);
	}
}

class _TimeField extends StatelessWidget {
	const _TimeField({
		required this.label,
		required this.hours,
		required this.minutes,
		required this.onChanged,
	});

	final String label;
	final int hours;
	final int minutes;
	final void Function(int hours, int minutes) onChanged;

	@override
	Widget build(BuildContext context) {
		return InputDecorator(
			decoration: InputDecoration(
				labelText: label,
				border: const OutlineInputBorder(),
			),
			child: Row(
				children: [
					Expanded(
						child: TextFormField(
							initialValue: '$hours',
							decoration: const InputDecoration(
								isDense: true,
								border: InputBorder.none,
								suffixText: 'h',
							),
							keyboardType: TextInputType.number,
							inputFormatters: [FilteringTextInputFormatter.digitsOnly],
							onChanged: (v) => onChanged(int.tryParse(v) ?? 0, minutes),
						),
					),
					const Text(' : '),
					Expanded(
						child: TextFormField(
							initialValue: '$minutes',
							decoration: const InputDecoration(
								isDense: true,
								border: InputBorder.none,
								suffixText: 'm',
							),
							keyboardType: TextInputType.number,
							inputFormatters: [FilteringTextInputFormatter.digitsOnly],
							onChanged: (v) {
								final m = (int.tryParse(v) ?? 0).clamp(0, 59);
								onChanged(hours, m);
							},
						),
					),
				],
			),
		);
	}
}

class _ProcUi {
	static String periodicidadLabel(Map<String, dynamic> proc) {
		if (proc['tipo'] == 'preventivo_no_periodico') return 'Sin periodicidad';
		if (proc['periodicidadTipo'] == 'contador' && proc['periodicidadValor'] != null) {
			return 'Cada ${proc['periodicidadValor']} u. contador';
		}
		if (proc['periodicidadTipo'] == 'tiempo' && proc['periodicidadValor'] != null) {
			final dias = proc['periodicidadValor'];
			final criterio = proc['criterioProgramacion'] == 'fecha_inicio'
					? 'desde inicio'
					: 'desde fin';
			return 'Cada $dias días ($criterio)';
		}
		return 'Sin periodicidad';
	}

	static String tipoLabel(String tipo) {
		return switch (tipo) {
			'correctivo' => 'Correctivo',
			'mejora' => 'Mejora',
			'preventivo' => 'Preventivo',
			'preventivo_no_periodico' => 'Preventivo no periódico',
			'predictivo' => 'Predictivo',
			_ => tipo,
		};
	}

	static Color tipoColor(String tipo) {
		return switch (tipo) {
			'preventivo' => AppColors.primary,
			'preventivo_no_periodico' => const Color(0xFF0369A1),
			'correctivo' => AppColors.warning,
			'mejora' => AppColors.success,
			'predictivo' => AppColors.accent,
			_ => AppColors.primary,
		};
	}
}

class _EquiposAsociadosCard extends ConsumerStatefulWidget {
	const _EquiposAsociadosCard({
		required this.procedimiento,
		required this.canAsociar,
		this.onChanged,
	});

	final Map<String, dynamic> procedimiento;
	final bool canAsociar;
	final Future<void> Function()? onChanged;

	@override
	ConsumerState<_EquiposAsociadosCard> createState() =>
			_EquiposAsociadosCardState();
}

class _EquiposAsociadosCardState extends ConsumerState<_EquiposAsociadosCard> {
	bool _busy = false;

	List<Map<String, dynamic>> get _asociados {
		return (widget.procedimiento['equipos'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>()
				.where((item) => (item['estado'] as String? ?? 'activo') == 'activo')
				.toList();
	}

	List<Map<String, dynamic>> get _alcances {
		return (widget.procedimiento['alcances'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>()
				.where((item) => (item['estado'] as String? ?? 'activo') == 'activo')
				.toList();
	}

	bool get _puedeEmitirPrimeraOt {
		final tipo = widget.procedimiento['tipo'] as String?;
		return tipo == 'preventivo' &&
				widget.procedimiento['periodicidadTipo'] == 'tiempo' &&
				widget.procedimiento['periodicidadValor'] != null;
	}

	Future<void> _asociar() async {
		final asociadosIds = _asociados
				.map((a) => (a['equipo'] as Map<String, dynamic>)['id'] as String)
				.toSet();
		final asociadosUbicacionIds = _alcances
				.where((a) => a['tipo'] == 'ubicacion' && a['ubicacionId'] != null)
				.map((a) => a['ubicacionId'] as String)
				.toSet();
		final plantaAsociada = _alcances.any(
			(a) => a['tipo'] == 'planta' && (a['estado'] as String? ?? 'activo') == 'activo',
		);

		final result = await showPlantaEquipoPickerDialog(
			context: context,
			ref: ref,
			excludedEquipoIds: asociadosIds,
			asociadosUbicacionIds: asociadosUbicacionIds,
			plantaYaAsociada: plantaAsociada,
			showEmitirPrimeraOt: _puedeEmitirPrimeraOt,
			allowScopeSelection: true,
		);

		if (result == null) return;

		setState(() => _busy = true);
		try {
			final api = ref.read(apiClientProvider);

			switch (result.tipo) {
				case PlantaPickerTargetTipo.equipo:
					final equipoId = result.equipoId;
					if (equipoId == null) return;
					await api.postJson(
						'procedimientos/${widget.procedimiento['id']}/asociar-equipo',
						{
							'equipoId': equipoId,
						},
					);
				case PlantaPickerTargetTipo.ubicacion:
					await api.postJson(
						'procedimientos/${widget.procedimiento['id']}/asociar-alcance',
						{
							'tipo': 'ubicacion',
							'targetId': result.ubicacionId,
						},
					);
				case PlantaPickerTargetTipo.planta:
					await api.postJson(
						'procedimientos/${widget.procedimiento['id']}/asociar-alcance',
						{
							'tipo': 'planta',
							'targetId': result.sucursalId,
						},
					);
			}

			await widget.onChanged?.call();
			if (!mounted) return;
			if (_puedeEmitirPrimeraOt) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: const Text(
							'Preventiva asociada. Aparece en OT necesarias '
							'(usá «Necesarias al» fin de mes).',
						),
						action: SnackBarAction(
							label: 'OT necesarias',
							onPressed: () => context.go('/ot/necesarias'),
						),
					),
				);
			} else {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Asociación guardada')),
				);
			}
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		} finally {
			if (mounted) setState(() => _busy = false);
		}
	}

	Future<void> _desasociar(Map<String, dynamic> asociacion) async {
		final equipo = asociacion['equipo'] as Map<String, dynamic>;
		final confirmado = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Desasociar equipo'),
				content: Text(
					'¿Quitar ${equipo['codigo']} — ${equipo['nombre']} de este procedimiento?',
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Desasociar'),
					),
				],
			),
		);

		if (confirmado != true) return;

		setState(() => _busy = true);
		try {
			await ref.read(apiClientProvider).postJson(
						'procedimientos/${widget.procedimiento['id']}/desasociar-equipo',
						{'equipoId': equipo['id']},
					);
			await widget.onChanged?.call();
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		} finally {
			if (mounted) setState(() => _busy = false);
		}
	}

	Future<void> _desasociarAlcance(Map<String, dynamic> alcance) async {
		final label = alcance['tipo'] == 'planta'
				? (alcance['sucursalAlcance']?['nombre'] as String? ?? 'Planta')
				: (alcance['ubicacion']?['nombre'] as String? ?? 'Sector');
		final confirmado = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Desasociar alcance'),
				content: Text('¿Quitar $label de este procedimiento?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Desasociar'),
					),
				],
			),
		);

		if (confirmado != true) return;

		setState(() => _busy = true);
		try {
			await ref.read(apiClientProvider).postJson(
						'procedimientos/${widget.procedimiento['id']}/desasociar-alcance',
						{'alcanceId': alcance['id']},
					);
			await widget.onChanged?.call();
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		} finally {
			if (mounted) setState(() => _busy = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final asociados = _asociados;
		final alcances = _alcances;
		final sinAsociaciones = asociados.isEmpty && alcances.isEmpty;

		return _SectionCard(
			title: 'Asociaciones',
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					if (widget.canAsociar)
						Align(
							alignment: Alignment.centerRight,
							child: FilledButton.icon(
								onPressed: _busy ? null : _asociar,
								icon: const Icon(Icons.link_rounded, size: 18),
								label: const Text('Asociar equipo o sector'),
							),
						),
					if (widget.canAsociar) const SizedBox(height: 12),
					if (sinAsociaciones)
						Text(
							'Sin asociaciones. Vinculá equipos, sectores o la planta completa.',
							style: TextStyle(
								color: Theme.of(context).colorScheme.onSurfaceVariant,
								fontSize: 13,
							),
						)
					else ...[
						...alcances.map((alcance) {
							final esPlanta = alcance['tipo'] == 'planta';
							final nombre = esPlanta
									? (alcance['sucursalAlcance']?['nombre'] as String? ?? 'Planta')
									: (alcance['ubicacion']?['nombre'] as String? ?? 'Sector');
							return ListTile(
								contentPadding: EdgeInsets.zero,
								leading: Icon(
									esPlanta ? Icons.factory_outlined : Icons.folder_outlined,
								),
								title: Text(nombre),
								subtitle: Text(esPlanta ? 'Planta completa' : 'Sector'),
								trailing: widget.canAsociar
										? IconButton(
												tooltip: 'Desasociar',
												onPressed: _busy
														? null
														: () => _desasociarAlcance(alcance),
												icon: const Icon(Icons.link_off_rounded),
											)
										: null,
							);
						}),
						...asociados.map((asociacion) {
							final equipo = asociacion['equipo'] as Map<String, dynamic>;
							final ubicacion =
									equipo['ubicacion'] as Map<String, dynamic>?;
							return ListTile(
								contentPadding: EdgeInsets.zero,
								leading: const Icon(Icons.precision_manufacturing_outlined),
								title: Text('${equipo['codigo']} — ${equipo['nombre']}'),
								subtitle: Text(ubicacion?['nombre'] as String? ?? 'Equipo'),
								trailing: widget.canAsociar
										? IconButton(
												tooltip: 'Desasociar',
												onPressed: _busy
														? null
														: () => _desasociar(asociacion),
												icon: const Icon(Icons.link_off_rounded),
											)
										: null,
							);
						}),
					],
				],
			),
		);
	}
}
