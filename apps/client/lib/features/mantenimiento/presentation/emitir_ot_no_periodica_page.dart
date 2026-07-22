import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../planta/presentation/planta_equipo_picker_dialog.dart';
import 'emitir_ot_catalogo.dart';
import 'emitir_ot_shell.dart';
import 'ot_emitir_accion_dialog.dart';
import 'ot_pdf.dart';

enum _PrioridadOt { baja, media, alta, urgente }

class EmitirOtNoPeriodicaPage extends ConsumerStatefulWidget {
	const EmitirOtNoPeriodicaPage({
		super.key,
		this.equipoIdInicial,
		this.procedimientoIdInicial,
		this.comentariosInicial,
		this.otReferencia,
	});

	final String? equipoIdInicial;
	final String? procedimientoIdInicial;
	final String? comentariosInicial;
	final String? otReferencia;

	@override
	ConsumerState<EmitirOtNoPeriodicaPage> createState() =>
			_EmitirOtNoPeriodicaPageState();
}

class _EmitirOtNoPeriodicaPageState extends ConsumerState<EmitirOtNoPeriodicaPage> {
	static final _dateFormat = DateFormat('dd/MM/yyyy');

	EmitirOtCatalogo? _catalogo;
	bool _loading = true;
	bool _submitting = false;
	String? _error;

	String? _equipoId;
	String? _equipoLabel;
	String? _procedimientoId;
	String _tipo = 'correctivo';
	_PrioridadOt _prioridad = _PrioridadOt.media;
	String? _tecnicoId;
	DateTime _fechaProgramacion = DateTime.now();
	DateTime? _fechaLimite;
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
			if (!mounted) return;
			setState(() {
				_catalogo = catalogo;
				final equipoInicial = widget.equipoIdInicial;
				if (equipoInicial != null) {
					final equipo = catalogo.equipos.cast<Map<String, dynamic>>().firstWhere(
						(e) => e['id'] == equipoInicial,
						orElse: () => <String, dynamic>{},
					);
					if (equipo.isNotEmpty) {
						_equipoId = equipoInicial;
						_equipoLabel = '${equipo['codigo']} — ${equipo['nombre']}';
					}
				} else if (catalogo.equipos.isNotEmpty) {
					final first = catalogo.equipos.first;
					_equipoId = first['id'] as String?;
					_equipoLabel = '${first['codigo']} — ${first['nombre']}';
				}
				_procedimientoId = widget.procedimientoIdInicial;
				if (widget.comentariosInicial != null) {
					_comentariosCtrl.text = widget.comentariosInicial!;
				}
			});
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	Future<void> _seleccionarEquipo() async {
		final picker = await showPlantaEquipoPickerDialog(
			context: context,
			ref: ref,
			excludedEquipoIds: const {},
			showEmitirPrimeraOt: false,
		);
		if (picker == null || !mounted) return;

		final equipo = (_catalogo?.equipos ?? []).cast<Map<String, dynamic>>().firstWhere(
			(e) => e['id'] == picker.equipoId,
			orElse: () => {'codigo': '', 'nombre': 'Equipo seleccionado'},
		);

		setState(() {
			_equipoId = picker.equipoId;
			_equipoLabel = '${equipo['codigo']} — ${equipo['nombre']}';
		});
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

	Future<void> _pickFechaLimite() async {
		final picked = await showDatePicker(
			context: context,
			initialDate: _fechaLimite ?? _fechaProgramacion.add(const Duration(days: 7)),
			firstDate: _fechaProgramacion,
			lastDate: DateTime(2035),
		);
		if (picked != null && mounted) {
			setState(() => _fechaLimite = picked);
		}
	}

	int? _toleranciaDias() {
		final limite = _fechaLimite;
		if (limite == null) return null;
		final diff = limite.difference(
			DateTime(_fechaProgramacion.year, _fechaProgramacion.month, _fechaProgramacion.day),
		).inDays;
		return diff > 0 ? diff : 0;
	}

	Future<void> _emitir() async {
		if (_equipoId == null) return;

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
			final ot = await ref.read(apiClientProvider).postJson('ot/emitir', {
				'equipoId': _equipoId,
				if (_procedimientoId != null) 'procedimientoId': _procedimientoId,
				'tipo': _tipo,
				'prioridad': _prioridad.name,
				if (_tecnicoId != null) 'tecnicoAsignadoId': _tecnicoId,
				if (tieneRecibe) 'notificarAsignacion': notificarSegunAccion(accion),
				'fechaProgramacion': _toApiDate(_fechaProgramacion),
				if (_toleranciaDias() != null) 'tolerancia': _toleranciaDias(),
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

		return EmitirOtPageShell(
			titulo: widget.otReferencia != null
					? 'OT correctiva (seg. OT #${widget.otReferencia})'
					: 'Emitir OT no periódica',
			subtitulo: widget.otReferencia != null
					? 'Nueva orden de trabajo asociada al trabajo previo'
					: 'Correctivo, predictivo o mejora fuera del plan de mantenimiento',
			gradient: const [AppColors.brandOrange, AppColors.warning],
			icon: Icons.build_circle_outlined,
			loading: _loading,
			child: catalogo == null || catalogo.equipos.isEmpty
					? const Text('No hay equipos disponibles en tu planta.')
					: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								OutlinedButton.icon(
									onPressed: _seleccionarEquipo,
									icon: const Icon(Icons.map_outlined, size: 18),
									label: Text(_equipoLabel ?? 'Seleccionar equipo en mapa'),
									style: OutlinedButton.styleFrom(
										alignment: Alignment.centerLeft,
										padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
									),
								),
								const SizedBox(height: 16),
								DropdownButtonFormField<String?>(
									value: _procedimientoId,
									decoration: const InputDecoration(
										labelText: 'Procedimiento (opcional)',
										border: OutlineInputBorder(),
									),
									items: [
										const DropdownMenuItem(
											value: null,
											child: Text('Sin procedimiento'),
										),
										...catalogo.procedimientos.map(
											(p) => DropdownMenuItem(
												value: p['id'] as String,
												child: Text(p['nombre'] as String),
											),
										),
									],
									onChanged: (value) => setState(() => _procedimientoId = value),
								),
								const SizedBox(height: 16),
								ResponsivePair(
									first: DropdownButtonFormField<String>(
										value: _tipo,
										decoration: const InputDecoration(
											labelText: 'Tipo de trabajo',
											border: OutlineInputBorder(),
										),
										items: const [
											DropdownMenuItem(
												value: 'correctivo',
												child: Text('Correctivo'),
											),
											DropdownMenuItem(
												value: 'predictivo',
												child: Text('Predictivo'),
											),
											DropdownMenuItem(
												value: 'mejora',
												child: Text('Mejora'),
											),
											DropdownMenuItem(
												value: 'preventivo',
												child: Text('Preventivo'),
											),
										],
										onChanged: (value) {
											if (value != null) setState(() => _tipo = value);
										},
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
											if (value != null) setState(() => _prioridad = value);
										},
									),
								),
								const SizedBox(height: 16),
								InkWell(
									onTap: _pickFecha,
									borderRadius: BorderRadius.circular(8),
									child: InputDecorator(
										decoration: const InputDecoration(
											labelText: 'Fecha de inicio',
											border: OutlineInputBorder(),
											suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
										),
										child: Text(_dateFormat.format(_fechaProgramacion)),
									),
								),
								const SizedBox(height: 16),
								InkWell(
									onTap: _pickFechaLimite,
									borderRadius: BorderRadius.circular(8),
									child: InputDecorator(
										decoration: InputDecoration(
											labelText: 'Fecha límite (opcional)',
											helperText: _fechaLimite != null
													? 'Tolerancia: ${_toleranciaDias() ?? 0} días'
													: 'Ventana de ejecución permitida',
											border: const OutlineInputBorder(),
											suffixIcon: Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													if (_fechaLimite != null)
														IconButton(
															icon: const Icon(Icons.clear_rounded, size: 18),
															onPressed: () => setState(() => _fechaLimite = null),
														),
													const Icon(Icons.event_rounded, size: 18),
												],
											),
										),
										child: Text(
											_fechaLimite != null
													? _dateFormat.format(_fechaLimite!)
													: 'Sin fecha límite',
										),
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
									submitLabel: 'Emitir OT',
									accentColor: AppColors.warning,
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
