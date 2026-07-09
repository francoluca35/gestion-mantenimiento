import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

Future<bool?> showSucursalForm(
	BuildContext context,
	WidgetRef ref, {
	Map<String, dynamic>? sucursal,
}) {
	return showDialog<bool>(
		context: context,
		builder: (context) => _SucursalFormDialog(
			ref: ref,
			sucursal: sucursal,
			esEdicion: sucursal != null,
		),
	);
}

class _SucursalFormDialog extends ConsumerStatefulWidget {
	const _SucursalFormDialog({
		required this.ref,
		required this.esEdicion,
		this.sucursal,
	});

	final WidgetRef ref;
	final bool esEdicion;
	final Map<String, dynamic>? sucursal;

	@override
	ConsumerState<_SucursalFormDialog> createState() => _SucursalFormDialogState();
}

class _SucursalFormDialogState extends ConsumerState<_SucursalFormDialog> {
	final _formKey = GlobalKey<FormState>();
	final _nombreCtrl = TextEditingController();
	final _codigoCtrl = TextEditingController();

	bool _submitting = false;
	bool _activa = true;
	String? _error;

	@override
	void initState() {
		super.initState();
		final s = widget.sucursal;
		if (s != null) {
			_nombreCtrl.text = s['nombre'] as String? ?? '';
			_codigoCtrl.text = s['codigo'] as String? ?? '';
			_activa = s['activa'] as bool? ?? true;
		}
	}

	@override
	void dispose() {
		_nombreCtrl.dispose();
		_codigoCtrl.dispose();
		super.dispose();
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) return;

		setState(() {
			_submitting = true;
			_error = null;
		});

		try {
			final api = widget.ref.read(apiClientProvider);

			if (widget.esEdicion) {
				await api.patchJson('sucursales/${widget.sucursal!['id']}', {
					'nombre': _nombreCtrl.text.trim(),
					'activa': _activa,
				});
			} else {
				await api.postJson('sucursales', {
					'nombre': _nombreCtrl.text.trim(),
					'codigo': _codigoCtrl.text.trim().toUpperCase(),
				});
			}

			if (!mounted) return;
			Navigator.pop(context, true);
		} catch (error) {
			if (!mounted) return;
			setState(() {
				_error = error.toString();
				_submitting = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			title: Text(widget.esEdicion ? 'Editar planta' : 'Nueva planta'),
			content: SizedBox(
				width: 420,
				child: Form(
					key: _formKey,
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							TextFormField(
								controller: _nombreCtrl,
								decoration: const InputDecoration(
									labelText: 'Nombre',
									border: OutlineInputBorder(),
								),
								validator: (v) =>
										(v == null || v.trim().length < 2) ? 'Mínimo 2 caracteres' : null,
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _codigoCtrl,
								enabled: !widget.esEdicion,
								textCapitalization: TextCapitalization.characters,
								decoration: const InputDecoration(
									labelText: 'Código',
									hintText: 'VIRREY',
									border: OutlineInputBorder(),
								),
								validator: (v) {
									if (widget.esEdicion) return null;
									final value = v?.trim() ?? '';
									if (value.length < 2) return 'Mínimo 2 caracteres';
									if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(value)) {
										return 'Solo mayúsculas, números, _ o -';
									}
									return null;
								},
							),
							if (widget.esEdicion) ...[
								const SizedBox(height: 8),
								SwitchListTile(
									contentPadding: EdgeInsets.zero,
									value: _activa,
									onChanged: (v) => setState(() => _activa = v),
									title: const Text('Planta activa'),
								),
							],
							if (_error != null) ...[
								const SizedBox(height: 12),
								Text(_error!, style: const TextStyle(color: AppColors.danger)),
							],
						],
					),
				),
			),
			actions: [
				TextButton(
					onPressed: _submitting ? null : () => Navigator.pop(context, false),
					child: const Text('Cancelar'),
				),
				FilledButton(
					onPressed: _submitting ? null : _submit,
					child: _submitting
							? const SizedBox(
									width: 18,
									height: 18,
									child: CircularProgressIndicator(strokeWidth: 2),
								)
							: Text(widget.esEdicion ? 'Guardar' : 'Crear'),
				),
			],
		);
	}
}
