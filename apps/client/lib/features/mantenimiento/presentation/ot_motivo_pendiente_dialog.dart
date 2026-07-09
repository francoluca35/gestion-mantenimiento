import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

class OtMotivoPendienteDialog extends ConsumerStatefulWidget {
	const OtMotivoPendienteDialog({
		super.key,
		required this.motivos,
		this.initialMotivoId,
	});

	final List<Map<String, dynamic>> motivos;
	final String? initialMotivoId;

	static Future<String?> show(
		BuildContext context, {
		required List<Map<String, dynamic>> motivos,
		String? initialMotivoId,
	}) {
		return showDialog<String?>(
			context: context,
			builder: (context) => OtMotivoPendienteDialog(
				motivos: motivos,
				initialMotivoId: initialMotivoId,
			),
		);
	}

	@override
	ConsumerState<OtMotivoPendienteDialog> createState() =>
			_OtMotivoPendienteDialogState();
}

class _OtMotivoPendienteDialogState extends ConsumerState<OtMotivoPendienteDialog> {
	final _codigoCtrl = TextEditingController();
	final _descripcionCtrl = TextEditingController();
	String? _selectedId;
	bool _creando = false;
	bool _saving = false;

	@override
	void initState() {
		super.initState();
		_selectedId = widget.initialMotivoId;
	}

	@override
	void dispose() {
		_codigoCtrl.dispose();
		_descripcionCtrl.dispose();
		super.dispose();
	}

	Future<void> _crearMotivo() async {
		final codigo = _codigoCtrl.text.trim();
		final descripcion = _descripcionCtrl.text.trim();
		if (codigo.isEmpty || descripcion.isEmpty) return;

		setState(() => _saving = true);
		try {
			final creado = await ref.read(apiClientProvider).postJson(
						'motivos-ot-pendiente',
						{'codigo': codigo, 'descripcion': descripcion},
					);
			if (!mounted) return;
			setState(() {
				_selectedId = creado['id'] as String?;
				_creando = false;
				_codigoCtrl.clear();
				_descripcionCtrl.clear();
			});
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('$error')),
			);
		} finally {
			if (mounted) setState(() => _saving = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			title: const Text('Motivo de OT pendiente'),
			content: SizedBox(
				width: 420,
				child: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						DropdownButtonFormField<String?>(
							value: _selectedId,
							isExpanded: true,
							decoration: const InputDecoration(
								labelText: 'Motivo',
								border: OutlineInputBorder(),
							),
							items: [
								const DropdownMenuItem(
									value: null,
									child: Text('Sin motivo'),
								),
								...widget.motivos.map(
									(m) => DropdownMenuItem(
										value: m['id'] as String,
										child: Text(m['descripcion'] as String),
									),
								),
							],
							onChanged: _saving ? null : (v) => setState(() => _selectedId = v),
						),
						const SizedBox(height: 12),
						if (!_creando)
							Align(
								alignment: Alignment.centerLeft,
								child: TextButton.icon(
									onPressed: _saving ? null : () => setState(() => _creando = true),
									icon: const Icon(Icons.add_rounded),
									label: const Text('Agregar motivo nuevo'),
								),
							)
						else ...[
							TextField(
								controller: _codigoCtrl,
								decoration: const InputDecoration(
									labelText: 'Código',
									border: OutlineInputBorder(),
								),
							),
							const SizedBox(height: 10),
							TextField(
								controller: _descripcionCtrl,
								decoration: const InputDecoration(
									labelText: 'Descripción',
									border: OutlineInputBorder(),
								),
							),
							const SizedBox(height: 10),
							Row(
								children: [
									TextButton(
										onPressed: _saving
												? null
												: () => setState(() => _creando = false),
										child: const Text('Cancelar'),
									),
									const Spacer(),
									FilledButton(
										onPressed: _saving ? null : _crearMotivo,
										child: _saving
												? const SizedBox(
														width: 18,
														height: 18,
														child: CircularProgressIndicator(strokeWidth: 2),
													)
												: const Text('Guardar motivo'),
									),
								],
							),
						],
					],
				),
			),
			actions: [
				TextButton(
					onPressed: () => Navigator.pop(context),
					child: const Text('Cancelar'),
				),
				FilledButton(
					onPressed: _saving ? null : () => Navigator.pop(context, _selectedId),
					child: const Text('Aplicar'),
				),
			],
		);
	}
}
