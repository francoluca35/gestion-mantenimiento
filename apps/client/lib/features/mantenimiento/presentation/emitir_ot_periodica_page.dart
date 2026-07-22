import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import 'emitir_ot_catalogo.dart';
import 'emitir_ot_shell.dart';
import 'ot_emitir_accion_dialog.dart';
import 'ot_pdf.dart';

enum _PrioridadOt { baja, media, alta, urgente }

class EmitirOtPeriodicaPage extends ConsumerStatefulWidget {
	const EmitirOtPeriodicaPage({super.key});

	@override
	ConsumerState<EmitirOtPeriodicaPage> createState() =>
			_EmitirOtPeriodicaPageState();
}

class _EmitirOtPeriodicaPageState extends ConsumerState<EmitirOtPeriodicaPage> {
	static final _dateFormat = DateFormat('dd/MM/yyyy');

	EmitirOtCatalogo? _catalogo;
	Map<String, dynamic>? _procedimientoDetalle;
	bool _loading = true;
	bool _loadingDetalle = false;
	bool _submitting = false;
	String? _error;

	String? _procedimientoId;
	String? _equipoId;
	_PrioridadOt _prioridad = _PrioridadOt.media;
	String? _tecnicoId;
	DateTime _fechaProgramacion = DateTime.now();
	final _comentariosCtrl = TextEditingController();

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
	}

	@override
	void dispose() {
		_comentariosCtrl.dispose();
		super.dispose();
	}

	Future<void> _cargar() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final catalogo = await EmitirOtCatalogo.cargar(ref);
			final periodicos = catalogo.procedimientosPeriodicos();
			if (!mounted) return;
			setState(() {
				_catalogo = catalogo;
				_procedimientoId =
						periodicos.isNotEmpty ? periodicos.first['id'] as String? : null;
			});
			if (_procedimientoId != null) {
				await _cargarProcedimiento(_procedimientoId!);
			}
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	Future<void> _cargarProcedimiento(String id) async {
		setState(() => _loadingDetalle = true);
		try {
			final detalle = await ref.read(apiClientProvider).getJson('procedimientos/$id');
			final equiposAsociados = (detalle['equipos'] as List<dynamic>? ?? [])
					.cast<Map<String, dynamic>>();
			final primerEquipo = equiposAsociados.isNotEmpty
					? equiposAsociados.first['equipo'] as Map<String, dynamic>?
					: null;

			if (!mounted) return;
			setState(() {
				_procedimientoDetalle = detalle;
				_equipoId = primerEquipo?['id'] as String?;
			});
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		} finally {
			if (mounted) setState(() => _loadingDetalle = false);
		}
	}

	List<Map<String, dynamic>> get _equiposAsociados {
		final equipos = (_procedimientoDetalle?['equipos'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>();
		return equipos
				.map((item) => item['equipo'] as Map<String, dynamic>)
				.whereType<Map<String, dynamic>>()
				.toList();
	}

	Future<void> _pickFecha() async {
		final picked = await showDatePicker(
			context: context,
			initialDate: _fechaProgramacion,
			firstDate: DateTime(2020),
			lastDate: DateTime(2035),
		);
		if (picked != null && mounted) {
			setState(() => _fechaProgramacion = picked);
		}
	}

	Future<void> _emitir() async {
		if (_procedimientoId == null || _equipoId == null) return;

		final recibeNombre = _tecnicoId == null
				? null
				: (_catalogo?.tecnicos ?? [])
						.cast<Map<String, dynamic>>()
						.firstWhere(
							(t) => t['id'] == _tecnicoId,
							orElse: () => {'nombreUsuario': 'Técnico'},
						)['nombreUsuario'] as String?;

		final tieneRecibe = _tecnicoId != null;
		final accion = await showOtEmitirAccionDialog(
			context,
			tieneRecibe: tieneRecibe,
			recibeNombre: tieneRecibe ? recibeNombre : null,
		);
		if (accion == null || !mounted) return;

		setState(() => _submitting = true);
		try {
			final ot = await ref.read(apiClientProvider).postJson('ot/emitir-periodica', {
				'procedimientoId': _procedimientoId,
				'equipoId': _equipoId,
				'prioridad': _prioridad.name,
				if (_tecnicoId != null) 'tecnicoAsignadoId': _tecnicoId,
				if (tieneRecibe) 'notificarAsignacion': notificarSegunAccion(accion),
				'fechaProgramacion': _toApiDate(_fechaProgramacion),
				if (_comentariosCtrl.text.isNotEmpty) 'comentarios': _comentariosCtrl.text,
			});
			if (!mounted) return;
			if (generarPdfSegunAccion(accion)) {
				await abrirPdfOt(ref, ot['id'] as String);
			}
			navegarTrasEmitir(context, ot);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		} finally {
			if (mounted) setState(() => _submitting = false);
		}
	}

	String _toApiDate(DateTime date) {
		return '${date.year.toString().padLeft(4, '0')}-'
				'${date.month.toString().padLeft(2, '0')}-'
				'${date.day.toString().padLeft(2, '0')}';
	}

	String _periodicidadLabel(Map<String, dynamic> proc) {
		final tipo = proc['periodicidadTipo'] as String?;
		final valor = proc['periodicidadValor'];
		if (tipo == 'tiempo') return 'Cada $valor días';
		if (tipo == 'contador') return 'Cada $valor unidades';
		return 'Sin periodicidad';
	}

	@override
	Widget build(BuildContext context) {
		if (_error != null) {
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

		final catalogo = _catalogo;
		final periodicos = catalogo?.procedimientosPeriodicos() ?? [];

		return EmitirOtPageShell(
			titulo: 'Emitir OT periódica',
			subtitulo: 'Mantenimiento preventivo según procedimiento y periodicidad',
			gradient: const [AppColors.brandYellow, AppColors.accent],
			icon: Icons.event_repeat_rounded,
			loading: _loading,
			child: catalogo == null
					? const SizedBox.shrink()
					: periodicos.isEmpty
							? const Text(
									'No hay procedimientos con periodicidad configurada. '
									'Creá uno desde Archivos → Procedimientos.',
								)
							: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										DropdownButtonFormField<String>(
											value: _procedimientoId,
											decoration: const InputDecoration(
												labelText: 'Procedimiento',
												border: OutlineInputBorder(),
											),
											items: periodicos
													.map(
														(p) => DropdownMenuItem(
															value: p['id'] as String,
															child: Text(p['nombre'] as String),
														),
													)
													.toList(),
											onChanged: (value) async {
												if (value == null) return;
												setState(() => _procedimientoId = value);
												await _cargarProcedimiento(value);
											},
										),
										if (_loadingDetalle)
											const Padding(
												padding: EdgeInsets.symmetric(vertical: 16),
												child: Center(child: CircularProgressIndicator()),
											)
										else if (_procedimientoDetalle != null) ...[
											const SizedBox(height: 12),
											Container(
												padding: const EdgeInsets.all(14),
												decoration: BoxDecoration(
													color: AppColors.primary.withValues(alpha: 0.06),
													borderRadius: BorderRadius.circular(12),
													border: Border.all(
														color: AppColors.primary.withValues(alpha: 0.15),
													),
												),
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Text(
															_periodicidadLabel(_procedimientoDetalle!),
															style: const TextStyle(
																fontWeight: FontWeight.w700,
																color: AppColors.primary,
															),
														),
														if (_procedimientoDetalle!['descripcion'] != null) ...[
															const SizedBox(height: 6),
															Text(
																_procedimientoDetalle!['descripcion'] as String,
																style: TextStyle(
																	fontSize: 13,
																	color: Theme.of(context)
																			.colorScheme
																			.onSurfaceVariant,
																),
															),
														],
													],
												),
											),
										],
										const SizedBox(height: 16),
										DropdownButtonFormField<String>(
											value: _equipoId,
											decoration: const InputDecoration(
												labelText: 'Equipo asociado',
												border: OutlineInputBorder(),
											),
											items: _equiposAsociados.isEmpty
													? catalogo.equipos
															.map(
																(e) => DropdownMenuItem(
																	value: e['id'] as String,
																	child: Text('${e['codigo']} — ${e['nombre']}'),
																),
															)
															.toList()
													: _equiposAsociados
															.map(
																(e) => DropdownMenuItem(
																	value: e['id'] as String,
																	child: Text('${e['codigo']} — ${e['nombre']}'),
																),
															)
															.toList(),
											onChanged: (value) => setState(() => _equipoId = value),
										),
										if (_equiposAsociados.isEmpty && _procedimientoDetalle != null)
											Padding(
												padding: const EdgeInsets.only(top: 8),
												child: Text(
													'Este procedimiento no tiene equipos asociados. '
													'Seleccioná un equipo manualmente.',
													style: TextStyle(
														fontSize: 12,
														color: Theme.of(context).colorScheme.onSurfaceVariant,
													),
												),
											),
										const SizedBox(height: 16),
										ResponsivePair(
											first: InkWell(
												onTap: _pickFecha,
												borderRadius: BorderRadius.circular(8),
												child: InputDecorator(
													decoration: const InputDecoration(
														labelText: 'Fecha de programación',
														border: OutlineInputBorder(),
														suffixIcon: Icon(
															Icons.calendar_today_rounded,
															size: 18,
														),
													),
													child: Text(_dateFormat.format(_fechaProgramacion)),
												),
											),
											second: DropdownButtonFormField<_PrioridadOt>(
												value: _prioridad,
												decoration: const InputDecoration(
													labelText: 'Prioridad',
													border: OutlineInputBorder(),
												),
												items: _PrioridadOt.values
														.map(
															(p) => DropdownMenuItem(
																value: p,
																child: Text(_prioridadLabel(p)),
															),
														)
														.toList(),
												onChanged: (value) {
													if (value != null) {
														setState(() => _prioridad = value);
													}
												},
											),
										),
										const SizedBox(height: 16),
										DropdownButtonFormField<String?>(
											value: _tecnicoId,
											decoration: const InputDecoration(
												labelText: 'Recibe',
												border: OutlineInputBorder(),
											),
											items: [
												const DropdownMenuItem(
													value: null,
													child: Text('Sin asignar'),
												),
												...catalogo.tecnicos.map(
													(t) => DropdownMenuItem(
														value: t['id'] as String,
														child: Text(t['nombreUsuario'] as String),
													),
												),
											],
											onChanged: (value) => setState(() => _tecnicoId = value),
										),
										const SizedBox(height: 16),
										TextField(
											controller: _comentariosCtrl,
											decoration: const InputDecoration(
												labelText: 'Comentarios',
												border: OutlineInputBorder(),
											),
											maxLines: 3,
										),
										const SizedBox(height: 24),
										EmitirOtFormActions(
											submitting: _submitting,
											submitLabel: 'Emitir OT periódica',
											onCancel: () => context.go('/ot'),
											onSubmit: _emitir,
										),
									],
								),
		);
	}

	String _prioridadLabel(_PrioridadOt prioridad) {
		return switch (prioridad) {
			_PrioridadOt.baja => 'Baja',
			_PrioridadOt.media => 'Media',
			_PrioridadOt.alta => 'Alta',
			_PrioridadOt.urgente => 'Urgente',
		};
	}
}
