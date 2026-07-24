import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

/// Flujo técnico: lectura → materiales (sí/no) → habilitar ejecución.
Future<bool> showOtPreparacionSheet({
	required BuildContext context,
	required WidgetRef ref,
	required Map<String, dynamic> ot,
}) async {
	final result = await showModalBottomSheet<bool>(
		context: context,
		isScrollControlled: true,
		useSafeArea: true,
		builder: (ctx) => _OtPreparacionSheet(ot: ot),
	);
	return result == true;
}

class _OtPreparacionSheet extends ConsumerStatefulWidget {
	const _OtPreparacionSheet({required this.ot});

	final Map<String, dynamic> ot;

	@override
	ConsumerState<_OtPreparacionSheet> createState() => _OtPreparacionSheetState();
}

class _OtPreparacionSheetState extends ConsumerState<_OtPreparacionSheet> {
	late int _step;
	final _lecturaCtrl = TextEditingController();
	final _tipoCtrl = TextEditingController(text: 'horas');
	final _textoCtrl = TextEditingController();
	bool _busy = false;
	String? _error;
	Map<String, dynamic>? _analisis;
	bool _lecturaOk = false;
	bool _materialesOk = false;

	String get _otId => widget.ot['id'] as String;

	@override
	void initState() {
		super.initState();
		_lecturaOk = widget.ot['lecturaRegistradaAt'] != null;
		final decision = widget.ot['decisionMateriales'] as String? ?? 'pendiente';
		_materialesOk = decision == 'no_necesita' || decision == 'necesita';
		if (!_lecturaOk) {
			_step = 0;
		} else if (!_materialesOk) {
			_step = 1;
		} else {
			_step = 2;
		}
	}

	@override
	void dispose() {
		_lecturaCtrl.dispose();
		_tipoCtrl.dispose();
		_textoCtrl.dispose();
		super.dispose();
	}

	Future<void> _guardarLectura() async {
		final valor = double.tryParse(_lecturaCtrl.text.trim().replaceAll(',', '.'));
		if (valor == null) {
			setState(() => _error = 'Ingresá un valor de lectura válido');
			return;
		}
		setState(() {
			_busy = true;
			_error = null;
		});
		try {
			await ref.read(apiClientProvider).postJson('ot/$_otId/lectura', {
				'tipo': _tipoCtrl.text.trim().isEmpty ? 'horas' : _tipoCtrl.text.trim(),
				'valor': valor,
			});
			setState(() {
				_lecturaOk = true;
				_step = 1;
			});
		} catch (e) {
			setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _busy = false);
		}
	}

	Future<void> _sinMateriales() async {
		setState(() {
			_busy = true;
			_error = null;
		});
		try {
			await ref.read(apiClientProvider).postJson(
				'ot/$_otId/materiales/sin-necesidad',
				{},
			);
			setState(() {
				_materialesOk = true;
				_step = 2;
			});
		} catch (e) {
			setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _busy = false);
		}
	}

	Future<void> _analizar() async {
		final texto = _textoCtrl.text.trim();
		if (texto.length < 2) {
			setState(() => _error = 'Escribí la lista de materiales');
			return;
		}
		setState(() {
			_busy = true;
			_error = null;
			_analisis = null;
		});
		try {
			final data = await ref.read(apiClientProvider).postJson(
				'ot/$_otId/materiales/analizar',
				{'texto': texto},
			);
			setState(() => _analisis = data);
		} catch (e) {
			setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _busy = false);
		}
	}

	Future<void> _confirmar({required bool procederConFaltantes}) async {
		final texto = _textoCtrl.text.trim();
		setState(() {
			_busy = true;
			_error = null;
		});
		try {
			final data = await ref.read(apiClientProvider).postJson(
				'ot/$_otId/materiales/confirmar',
				{
					'texto': texto,
					'procederConFaltantes': procederConFaltantes,
				},
			);
			if (data['requiereConfirmacion'] == true) {
				setState(() => _analisis = data['analisis'] as Map<String, dynamic>?);
				final ok = await showDialog<bool>(
					context: context,
					builder: (ctx) => AlertDialog(
						title: const Text('Hay faltantes'),
						content: Text(
							data['mensaje'] as String? ??
									'Faltan materiales. ¿Igual realizás la OT? Se generará pedido de lo faltante.',
						),
						actions: [
							TextButton(
								onPressed: () => Navigator.pop(ctx, false),
								child: const Text('Cancelar'),
							),
							FilledButton(
								onPressed: () => Navigator.pop(ctx, true),
								child: const Text('Sí, generar pedido'),
							),
						],
					),
				);
				if (ok == true) {
					await _confirmar(procederConFaltantes: true);
				}
				return;
			}
			setState(() {
				_materialesOk = true;
				_step = 2;
				_analisis = data;
			});
		} catch (e) {
			setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _busy = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final bottom = MediaQuery.viewInsetsOf(context).bottom;
		return Padding(
			padding: EdgeInsets.only(bottom: bottom),
			child: DraggableScrollableSheet(
				expand: false,
				initialChildSize: 0.85,
				minChildSize: 0.5,
				maxChildSize: 0.95,
				builder: (context, scrollCtrl) {
					return ListView(
						controller: scrollCtrl,
						padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
						children: [
							Center(
								child: Container(
									width: 40,
									height: 4,
									margin: const EdgeInsets.only(bottom: 12),
									decoration: BoxDecoration(
										color: Colors.white24,
										borderRadius: BorderRadius.circular(99),
									),
								),
							),
							Text(
								'Pedir a Pañol — OT #${widget.ot['numero'] ?? ''}',
								style: Theme.of(context).textTheme.titleLarge,
							),
							const SizedBox(height: 8),
							Text(
								'1) Lectura  →  2) Pedido materiales  →  3) Pañol confirma  →  Iniciar',
								style: Theme.of(context).textTheme.bodySmall?.copyWith(
											color: Colors.white70,
										),
							),
							const SizedBox(height: 16),
							if (_error != null)
								Padding(
									padding: const EdgeInsets.only(bottom: 12),
									child: Text(_error!, style: const TextStyle(color: AppColors.warning)),
								),
							if (_step == 0) _buildLectura(),
							if (_step == 1) _buildMateriales(),
							if (_step == 2) _buildListo(),
						],
					);
				},
			),
		);
	}

	Widget _buildLectura() {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				const Text('Registrá la lectura del equipo (obligatorio).'),
				const SizedBox(height: 12),
				TextField(
					controller: _tipoCtrl,
					decoration: const InputDecoration(
						labelText: 'Tipo (horas / km / ciclos…)',
					),
				),
				const SizedBox(height: 8),
				TextField(
					controller: _lecturaCtrl,
					keyboardType: const TextInputType.numberWithOptions(decimal: true),
					decoration: const InputDecoration(labelText: 'Valor de lectura'),
				),
				const SizedBox(height: 16),
				FilledButton(
					onPressed: _busy ? null : _guardarLectura,
					child: _busy
							? const SizedBox(
									height: 20,
									width: 20,
									child: CircularProgressIndicator(strokeWidth: 2),
								)
							: const Text('Guardar lectura y continuar'),
				),
			],
		);
	}

	Widget _buildMateriales() {
		final lineas = (_analisis?['lineas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				const Text('¿Necesitás materiales para esta OT?'),
				const SizedBox(height: 12),
				FilledButton.tonal(
					onPressed: _busy ? null : _sinMateriales,
					child: const Text('No necesito materiales'),
				),
				const SizedBox(height: 16),
				const Text('Necesito materiales — escribí la lista (una por línea):'),
				const SizedBox(height: 8),
				TextField(
					controller: _textoCtrl,
					minLines: 4,
					maxLines: 8,
					decoration: const InputDecoration(
						hintText: 'Ej:\n2 filtros de aceite\n1 correa x 1\ngrasa 500g',
					),
				),
				const SizedBox(height: 8),
				Row(
					children: [
						Expanded(
							child: OutlinedButton(
								onPressed: _busy ? null : _analizar,
								child: const Text('Verificar en Pañol'),
							),
						),
						const SizedBox(width: 8),
						Expanded(
							child: FilledButton(
								onPressed: _busy ? null : () => _confirmar(procederConFaltantes: false),
								child: const Text('Confirmar pedido'),
							),
						),
					],
				),
				if (lineas.isNotEmpty) ...[
					const SizedBox(height: 16),
					Text(
						'Búsqueda automática en stock',
						style: Theme.of(context).textTheme.titleMedium,
					),
					const SizedBox(height: 8),
					...lineas.map((l) {
						final estado = l['estado'] as String? ?? '';
						final color = switch (estado) {
							'ok' => AppColors.success,
							'faltante_parcial' => AppColors.warning,
							_ => AppColors.danger,
						};
						final match = l['match'] as Map<String, dynamic>?;
						final titulo = match != null
								? '${match['codigo']} · ${match['nombre']}'
								: (l['descripcion'] as String? ?? l['raw'] as String? ?? '');
						return Card(
							child: ListTile(
								dense: true,
								title: Text(titulo),
								subtitle: Text(
									'Pedido: ${l['cantidadPedida']} · Disp: ${l['cantidadDisponible']} · Falta: ${l['cantidadFaltante']}',
								),
								trailing: Text(estado, style: TextStyle(color: color, fontSize: 12)),
							),
						);
					}),
				],
			],
		);
	}

	Widget _buildListo() {
		final otResp = _analisis?['ot'] as Map<String, dynamic>?;
		final estadoOt = otResp?['estado'] as String? ?? widget.ot['estado'] as String?;
		final esperaPanol = estadoOt == 'pendiente_panol';
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Icon(
					esperaPanol ? Icons.hourglass_top_rounded : Icons.check_circle,
					color: esperaPanol ? AppColors.brandOrange : AppColors.success,
					size: 48,
				),
				const SizedBox(height: 12),
				Text(
					esperaPanol
							? 'Pedido enviado a Pañol. Cuando confirmen el material, vas a poder Iniciar la OT.'
							: 'Sin pedido a Pañol. Ya podés Iniciar la OT.',
				),
				const SizedBox(height: 16),
				FilledButton(
					onPressed: () => Navigator.pop(context, true),
					child: const Text('Listo'),
				),
			],
		);
	}
}
