import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/collapsible_panel.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../planta/presentation/planta_equipo_picker_dialog.dart';
import 'ot_emitir_accion_dialog.dart';
import 'ot_pdf.dart';

class SolicitudesTrabajoPage extends ConsumerStatefulWidget {
	const SolicitudesTrabajoPage({super.key});

	@override
	ConsumerState<SolicitudesTrabajoPage> createState() =>
			_SolicitudesTrabajoPageState();
}

class _SolicitudesTrabajoPageState extends ConsumerState<SolicitudesTrabajoPage> {
	static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
	static const _listExpandedWidth = 380.0;
	static const _listCollapsedWidth = 56.0;

	List<Map<String, dynamic>> _solicitudes = [];
	List<Map<String, dynamic>> _tecnicos = [];
	Map<String, dynamic>? _selected;
	String? _filtroEstado;
	bool _loading = true;
	bool _listCollapsed = false;
	String? _error;

	AuthUser? get _user => ref.read(authControllerProvider).session?.usuario;

	bool get _canAgregar =>
			_user?.tieneDerecho('programacion.solicitudes_trabajo.agregar') == true ||
			_user?.esAdministrador == true;

	bool get _canConformidad =>
			_user?.tieneDerecho('programacion.solicitudes_trabajo.dar_conformidad') ==
					true ||
			_user?.esAdministrador == true;

	bool get _canEmitirOt =>
			_user?.tieneDerecho(
						'programacion.solicitudes_trabajo.emitir_ot_desde_solicitud',
					) ==
					true ||
			_user?.esAdministrador == true;

	List<Map<String, dynamic>> get _filtradas {
		if (_filtroEstado == null) return _solicitudes;
		return _solicitudes
				.where((s) => (s['estado'] as String? ?? '') == _filtroEstado)
				.toList();
	}

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
			final lista =
					(await api.getList('solicitudes-trabajo')).cast<Map<String, dynamic>>();
			final tecnicos = (await api.getList('ot/tecnicos')).cast<Map<String, dynamic>>();
			if (!mounted) return;
			setState(() {
				_solicitudes = lista;
				_tecnicos = tecnicos;
				if (_selected != null) {
					final id = _selected!['id'];
					_selected = lista
							.where((s) => s['id'] == id)
							.cast<Map<String, dynamic>?>()
							.firstOrNull;
				}
			});
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	void _toggleListPanel() => setState(() => _listCollapsed = !_listCollapsed);

	Future<void> _crearSolicitud() async {
		final solicitanteCtrl = TextEditingController();
		final descripcionCtrl = TextEditingController();
		var urgente = false;

		final creada = await showDialog<bool>(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setDialog) => AlertDialog(
					title: const Text('Nueva solicitud'),
					content: SizedBox(
						width: 420,
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								TextField(
									controller: solicitanteCtrl,
									decoration: const InputDecoration(
										labelText: 'Solicitante',
										border: OutlineInputBorder(),
									),
								),
								const SizedBox(height: 12),
								TextField(
									controller: descripcionCtrl,
									maxLines: 4,
									decoration: const InputDecoration(
										labelText: 'Descripción del trabajo',
										border: OutlineInputBorder(),
									),
								),
								const SizedBox(height: 8),
								CheckboxListTile(
									contentPadding: EdgeInsets.zero,
									value: urgente,
									onChanged: (v) => setDialog(() => urgente = v ?? false),
									title: const Text('Urgente'),
									controlAffinity: ListTileControlAffinity.leading,
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
							onPressed: () => Navigator.pop(context, true),
							child: const Text('Crear'),
						),
					],
				),
			),
		);

		if (creada != true) return;

		try {
			await ref.read(apiClientProvider).postJson('solicitudes-trabajo', {
				'solicitante': solicitanteCtrl.text.trim(),
				'descripcion': descripcionCtrl.text.trim(),
				'urgente': urgente,
			});
			await _cargar();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Solicitud creada')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	Future<void> _darConformidad(Map<String, dynamic> solicitud, bool conforme) async {
		String? calificacion = conforme ? 'bueno' : null;
		final observacionesCtrl = TextEditingController(
			text: solicitud['observaciones'] as String? ?? '',
		);

		final confirmado = await showDialog<bool>(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setDialog) => AlertDialog(
					title: Text(conforme ? 'Dar conformidad' : 'Rechazar solicitud'),
					content: SizedBox(
						width: 400,
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								if (conforme) ...[
									const Text('Calificación del pedido'),
									const SizedBox(height: 8),
									..._calificaciones.map(
										(c) => RadioListTile<String>(
											dense: true,
											contentPadding: EdgeInsets.zero,
											value: c.$1,
											groupValue: calificacion,
											onChanged: (v) => setDialog(() => calificacion = v),
											title: Text(c.$2),
										),
									),
									const SizedBox(height: 12),
								],
								TextField(
									controller: observacionesCtrl,
									maxLines: 3,
									decoration: InputDecoration(
										labelText: conforme ? 'Observaciones' : 'Motivo del rechazo',
										border: const OutlineInputBorder(),
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
							style: FilledButton.styleFrom(
								backgroundColor: conforme ? AppColors.success : AppColors.danger,
							),
							onPressed: () => Navigator.pop(context, true),
							child: Text(conforme ? 'Conformar' : 'Rechazar'),
						),
					],
				),
			),
		);

		if (confirmado != true) return;

		try {
			await ref.read(apiClientProvider).patchJson(
						'solicitudes-trabajo/${solicitud['id']}/conformidad',
						{
							'conforme': conforme,
							if (conforme && calificacion != null) 'calificacion': calificacion,
							if (observacionesCtrl.text.trim().isNotEmpty)
								'observaciones': observacionesCtrl.text.trim(),
						},
					);
			await _cargar();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(conforme ? 'Solicitud conformada' : 'Solicitud rechazada'),
				),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	Future<void> _emitirOt(Map<String, dynamic> solicitud) async {
		final picker = await showPlantaEquipoPickerDialog(
			context: context,
			ref: ref,
			excludedEquipoIds: const {},
			showEmitirPrimeraOt: false,
		);
		if (picker == null) return;

		var tipo = 'correctivo';
		var prioridad = 'media';
		String? tecnicoId;
		var fecha = DateTime.now();

		final confirmado = await showDialog<bool>(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setDialog) => AlertDialog(
					title: const Text('Emitir OT desde solicitud'),
					content: SizedBox(
						width: 400,
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								DropdownButtonFormField<String>(
									value: tipo,
									decoration: const InputDecoration(
										labelText: 'Tipo de trabajo',
										border: OutlineInputBorder(),
									),
									items: const [
										DropdownMenuItem(value: 'correctivo', child: Text('Correctivo')),
										DropdownMenuItem(value: 'predictivo', child: Text('Predictivo')),
										DropdownMenuItem(value: 'mejora', child: Text('Mejora')),
										DropdownMenuItem(value: 'preventivo', child: Text('Preventivo')),
									],
									onChanged: (v) => setDialog(() => tipo = v ?? tipo),
								),
								const SizedBox(height: 12),
								DropdownButtonFormField<String>(
									value: prioridad,
									decoration: const InputDecoration(
										labelText: 'Prioridad',
										border: OutlineInputBorder(),
									),
									items: const [
										DropdownMenuItem(value: 'baja', child: Text('Baja')),
										DropdownMenuItem(value: 'media', child: Text('Media')),
										DropdownMenuItem(value: 'alta', child: Text('Alta')),
										DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
									],
									onChanged: (v) => setDialog(() => prioridad = v ?? prioridad),
								),
								const SizedBox(height: 12),
								DropdownButtonFormField<String?>(
									value: tecnicoId,
									decoration: const InputDecoration(
										labelText: 'Recibe',
										border: OutlineInputBorder(),
									),
									items: [
										const DropdownMenuItem(value: null, child: Text('Sin asignar')),
										..._tecnicos.map(
											(t) => DropdownMenuItem(
												value: t['id'] as String,
												child: Text(t['nombreUsuario'] as String),
											),
										),
									],
									onChanged: (v) => setDialog(() => tecnicoId = v),
								),
								const SizedBox(height: 12),
								ListTile(
									contentPadding: EdgeInsets.zero,
									title: const Text('Fecha programación'),
									subtitle: Text(_toApiDate(fecha)),
									trailing: const Icon(Icons.calendar_today_rounded, size: 18),
									onTap: () async {
										final picked = await showDatePicker(
											context: context,
											initialDate: fecha,
											firstDate: DateTime(2020),
											lastDate: DateTime(2035),
										);
										if (picked != null) setDialog(() => fecha = picked);
									},
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
							onPressed: () => Navigator.pop(context, true),
							child: const Text('Emitir OT'),
						),
					],
				),
			),
		);

		if (confirmado != true) return;

		final recibeNombre = tecnicoId == null
				? null
				: _tecnicos.cast<Map<String, dynamic>>().firstWhere(
							(t) => t['id'] == tecnicoId,
							orElse: () => {'nombreUsuario': 'Técnico'},
						)['nombreUsuario'] as String?;

		final tieneRecibe = tecnicoId != null;
		final accion = await showOtEmitirAccionDialog(
			context,
			tieneRecibe: tieneRecibe,
			recibeNombre: tieneRecibe ? recibeNombre : null,
		);
		if (accion == null) return;

		try {
			final ot = await ref.read(apiClientProvider).postJson(
						'solicitudes-trabajo/${solicitud['id']}/emitir-ot',
						{
							'equipoId': picker.equipoId,
							'tipo': tipo,
							'prioridad': prioridad,
							if (tecnicoId != null) 'tecnicoAsignadoId': tecnicoId,
							if (tieneRecibe) 'notificarAsignacion': notificarSegunAccion(accion),
							'fechaProgramacion': _toApiDate(fecha),
						},
					);
			await _cargar();
			if (!mounted) return;
			if (generarPdfSegunAccion(accion)) {
				await abrirPdfOt(ref, ot['id'] as String);
			}
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('OT #${ot['numero']} emitida')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	String _toApiDate(DateTime date) {
		return '${date.year.toString().padLeft(4, '0')}-'
				'${date.month.toString().padLeft(2, '0')}-'
				'${date.day.toString().padLeft(2, '0')}';
	}

	static const _calificaciones = [
		('muy_bueno', 'Muy bueno'),
		('bueno', 'Bueno'),
		('regular', 'Regular'),
		('malo', 'Malo'),
	];

	@override
	Widget build(BuildContext context) {
		if (_loading && _solicitudes.isEmpty) {
			return const Center(child: CircularProgressIndicator());
		}

		if (_error != null && _solicitudes.isEmpty) {
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(_error!),
						const SizedBox(height: 12),
						FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
					],
				),
			);
		}

		final wide = MediaQuery.sizeOf(context).width >= 960;
		if (!wide) return _buildMobile();

		return Row(
			children: [
				AnimatedContainer(
					duration: const Duration(milliseconds: 220),
					curve: Curves.easeOutCubic,
					width: _listCollapsed ? _listCollapsedWidth : _listExpandedWidth,
					child: _buildListPanel(collapsed: _listCollapsed),
				),
				_buildListDivider(),
				Expanded(child: _buildDetailPanel()),
			],
		);
	}

	Widget _buildMobile() {
		if (_selected != null) {
			return Column(
				children: [
					Material(
						child: ListTile(
							leading: IconButton(
								icon: const Icon(Icons.arrow_back_rounded),
								onPressed: () => setState(() => _selected = null),
							),
							title: Text(_selected!['solicitante'] as String? ?? 'Solicitud'),
						),
					),
					Expanded(child: _buildDetailPanel()),
				],
			);
		}
		return _buildListPanel();
	}

	Widget _buildListDivider() {
		return PanelCollapseHandle(
			collapsed: _listCollapsed,
			onToggle: _toggleListPanel,
			edge: PanelCollapseEdge.start,
			expandTooltip: 'Expandir listado',
			collapseTooltip: 'Contraer listado',
		);
	}

	Widget _buildListPanel({bool collapsed = false}) {
		final scheme = Theme.of(context).colorScheme;

		if (collapsed) {
			return Material(
				color: scheme.surface,
				child: Column(
					children: [
						const Padding(
							padding: EdgeInsets.only(top: 16),
							child: Icon(Icons.campaign_rounded, color: AppColors.primary),
						),
						if (_canAgregar)
							IconButton(
								tooltip: 'Nueva solicitud',
								onPressed: _crearSolicitud,
								icon: const Icon(Icons.add_rounded),
							),
						Expanded(
							child: ListView.builder(
								padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
								itemCount: _filtradas.length,
								itemBuilder: (context, index) {
									final item = _filtradas[index];
									final selected = _selected?['id'] == item['id'];
									final urgente = item['urgente'] as bool? ?? false;
									return Tooltip(
										message: item['solicitante'] as String? ?? '',
										child: Padding(
											padding: const EdgeInsets.only(bottom: 6),
											child: InkWell(
												onTap: () => setState(() => _selected = item),
												borderRadius: BorderRadius.circular(8),
												child: Container(
													width: 40,
													height: 40,
													decoration: BoxDecoration(
														color: selected
																? AppColors.primary.withValues(alpha: 0.15)
																: (urgente
																		? AppColors.danger.withValues(alpha: 0.12)
																		: scheme.surfaceContainerHighest
																				.withValues(alpha: 0.4)),
														borderRadius: BorderRadius.circular(8),
													),
													child: Icon(
														urgente ? Icons.priority_high_rounded : Icons.mail_outline_rounded,
														size: 18,
														color: selected ? AppColors.primary : scheme.onSurfaceVariant,
													),
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
										'Solicitudes',
										style: Theme.of(context).textTheme.titleLarge?.copyWith(
													fontWeight: FontWeight.w700,
												),
									),
								),
								if (_canAgregar)
									FilledButton.icon(
										onPressed: _crearSolicitud,
										icon: const Icon(Icons.add_rounded, size: 18),
										label: const Text('Nueva'),
									),
							],
						),
					),
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 16),
						child: DropdownButtonFormField<String?>(
							value: _filtroEstado,
							isExpanded: true,
							decoration: const InputDecoration(
								labelText: 'Estado',
								isDense: true,
								border: OutlineInputBorder(),
							),
							items: const [
								DropdownMenuItem(value: null, child: Text('Todas')),
								DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
								DropdownMenuItem(value: 'conformada', child: Text('Conformadas')),
								DropdownMenuItem(value: 'rechazada', child: Text('Rechazadas')),
							],
							onChanged: (v) => setState(() => _filtroEstado = v),
						),
					),
					const SizedBox(height: 10),
					Expanded(
						child: _filtradas.isEmpty
								? const Center(child: Text('Sin solicitudes'))
								: ListView.separated(
										padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
										itemCount: _filtradas.length,
										separatorBuilder: (_, __) => const SizedBox(height: 6),
										itemBuilder: (context, index) {
											final item = _filtradas[index];
											return _SolicitudListTile(
												item: item,
												selected: _selected?['id'] == item['id'],
												formatDate: _dateFormat.format,
												onTap: () => setState(() => _selected = item),
											);
										},
									),
					),
				],
			),
		);
	}

	Widget _buildDetailPanel() {
		final solicitud = _selected;
		if (solicitud == null) {
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						const Icon(Icons.campaign_outlined, size: 56, color: AppColors.primary),
						const SizedBox(height: 12),
						const Text('Seleccioná una solicitud del listado'),
						if (_canAgregar) ...[
							const SizedBox(height: 16),
							FilledButton.icon(
								onPressed: _crearSolicitud,
								icon: const Icon(Icons.add_rounded),
								label: const Text('Nueva solicitud'),
							),
						],
					],
				),
			);
		}

		final estado = solicitud['estado'] as String? ?? 'pendiente';
		final urgente = solicitud['urgente'] as bool? ?? false;
		final fecha = DateTime.tryParse(solicitud['createdAt'] as String? ?? '');
		final ot = solicitud['otGenerada'] as Map<String, dynamic>?;

		return ListView(
			padding: const EdgeInsets.all(24),
			children: [
				Row(
					children: [
						Chip(
							label: Text(_estadoLabel(estado)),
							backgroundColor: _estadoColor(estado).withValues(alpha: 0.12),
							labelStyle: TextStyle(
								color: _estadoColor(estado),
								fontWeight: FontWeight.w700,
							),
						),
						if (urgente) ...[
							const SizedBox(width: 8),
							const Chip(
								label: Text('Urgente'),
								backgroundColor: Color(0x1AFEE2E2),
								labelStyle: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
							),
						],
						const Spacer(),
						if (fecha != null)
							Text(
								_dateFormat.format(fecha.toLocal()),
								style: TextStyle(
									color: Theme.of(context).colorScheme.onSurfaceVariant,
									fontSize: 13,
								),
							),
					],
				),
				const SizedBox(height: 16),
				Text(
					solicitud['solicitante'] as String? ?? '',
					style: Theme.of(context).textTheme.headlineSmall?.copyWith(
								fontWeight: FontWeight.w800,
							),
				),
				const SizedBox(height: 12),
				Text(solicitud['descripcion'] as String? ?? ''),
				if (solicitud['calificacion'] != null) ...[
					const SizedBox(height: 16),
					Text(
						'Calificación: ${_calificacionLabel(solicitud['calificacion'] as String)}',
						style: const TextStyle(fontWeight: FontWeight.w600),
					),
				],
				if ((solicitud['observaciones'] as String? ?? '').isNotEmpty) ...[
					const SizedBox(height: 12),
					Text(
						'Observaciones: ${solicitud['observaciones']}',
						style: TextStyle(
							color: Theme.of(context).colorScheme.onSurfaceVariant,
						),
					),
				],
				if (ot != null) ...[
					const SizedBox(height: 20),
					FilledButton.icon(
						onPressed: () => context.go('/ot'),
						icon: const Icon(Icons.open_in_new_rounded, size: 18),
						label: Text('Ver OT #${ot['numero']}'),
					),
				],
				const SizedBox(height: 24),
				if (estado == 'pendiente' && _canConformidad)
					Wrap(
						spacing: 12,
						runSpacing: 12,
						children: [
							FilledButton.icon(
								style: FilledButton.styleFrom(backgroundColor: AppColors.success),
								onPressed: () => _darConformidad(solicitud, true),
								icon: const Icon(Icons.check_rounded),
								label: const Text('Dar conformidad'),
							),
							OutlinedButton.icon(
								onPressed: () => _darConformidad(solicitud, false),
								icon: const Icon(Icons.close_rounded),
								label: const Text('Rechazar'),
							),
						],
					),
				if (estado == 'conformada' && ot == null && _canEmitirOt)
					FilledButton.icon(
						onPressed: () => _emitirOt(solicitud),
						icon: const Icon(Icons.play_arrow_rounded),
						label: const Text('Emitir OT'),
					),
			],
		);
	}

	String _estadoLabel(String estado) => switch (estado) {
		'conformada' => 'Conformada',
		'rechazada' => 'Rechazada',
		_ => 'Pendiente',
	};

	Color _estadoColor(String estado) => switch (estado) {
		'conformada' => AppColors.success,
		'rechazada' => AppColors.danger,
		_ => AppColors.warning,
	};

	String _calificacionLabel(String value) => switch (value) {
		'muy_bueno' => 'Muy bueno',
		'bueno' => 'Bueno',
		'regular' => 'Regular',
		'malo' => 'Malo',
		_ => value,
	};
}

class _SolicitudListTile extends StatelessWidget {
	const _SolicitudListTile({
		required this.item,
		required this.selected,
		required this.formatDate,
		required this.onTap,
	});

	final Map<String, dynamic> item;
	final bool selected;
	final String Function(DateTime) formatDate;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final estado = item['estado'] as String? ?? 'pendiente';
		final urgente = item['urgente'] as bool? ?? false;
		final fecha = DateTime.tryParse(item['createdAt'] as String? ?? '');

		return Material(
			color: selected
					? AppColors.primary.withValues(alpha: 0.1)
					: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
			borderRadius: BorderRadius.circular(14),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(14),
				child: Padding(
					padding: const EdgeInsets.all(14),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Container(
										width: 8,
										height: 8,
										decoration: BoxDecoration(
											shape: BoxShape.circle,
											color: switch (estado) {
												'conformada' => AppColors.success,
												'rechazada' => AppColors.danger,
												_ => AppColors.warning,
											},
										),
									),
									const SizedBox(width: 8),
									Expanded(
										child: Text(
											item['solicitante'] as String? ?? '',
											style: const TextStyle(fontWeight: FontWeight.w700),
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
										),
									),
									if (urgente)
										const Icon(Icons.priority_high_rounded,
												size: 16, color: AppColors.danger),
								],
							),
							const SizedBox(height: 6),
							Text(
								item['descripcion'] as String? ?? '',
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
								style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
							),
							if (fecha != null) ...[
								const SizedBox(height: 6),
								Text(
									formatDate(fecha.toLocal()),
									style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
								),
							],
						],
					),
				),
			),
		);
	}
}
