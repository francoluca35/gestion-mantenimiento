import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

Future<bool?> showPerfilForm(
	BuildContext context,
	WidgetRef ref, {
	Map<String, dynamic>? perfil,
}) {
	return showDialog<bool>(
		context: context,
		builder: (context) => _PerfilFormDialog(
			ref: ref,
			perfil: perfil,
			esEdicion: perfil != null,
		),
	);
}

class _PerfilFormDialog extends ConsumerStatefulWidget {
	const _PerfilFormDialog({
		required this.ref,
		required this.esEdicion,
		this.perfil,
	});

	final WidgetRef ref;
	final bool esEdicion;
	final Map<String, dynamic>? perfil;

	@override
	ConsumerState<_PerfilFormDialog> createState() => _PerfilFormDialogState();
}

class _PerfilFormDialogState extends ConsumerState<_PerfilFormDialog> {
	final _formKey = GlobalKey<FormState>();
	final _nombreCtrl = TextEditingController();
	final _descripcionCtrl = TextEditingController();

	bool _submitting = false;
	bool _activo = true;
	String? _error;

	@override
	void initState() {
		super.initState();
		final p = widget.perfil;
		if (p != null) {
			_nombreCtrl.text = p['nombre'] as String? ?? '';
			_descripcionCtrl.text = p['descripcion'] as String? ?? '';
			_activo = p['activo'] as bool? ?? true;
		}
	}

	@override
	void dispose() {
		_nombreCtrl.dispose();
		_descripcionCtrl.dispose();
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
			final descripcion = _descripcionCtrl.text.trim();

			if (widget.esEdicion) {
				await api.patchJson('perfiles/${widget.perfil!['id']}', {
					'nombre': _nombreCtrl.text.trim(),
					'descripcion': descripcion.isEmpty ? null : descripcion,
					'activo': _activo,
				});
			} else {
				await api.postJson('perfiles', {
					'nombre': _nombreCtrl.text.trim(),
					if (descripcion.isNotEmpty) 'descripcion': descripcion,
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
			title: Text(widget.esEdicion ? 'Editar perfil' : 'Nuevo perfil'),
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
								controller: _descripcionCtrl,
								maxLines: 3,
								decoration: const InputDecoration(
									labelText: 'Descripción (opcional)',
									border: OutlineInputBorder(),
								),
							),
							if (widget.esEdicion) ...[
								const SizedBox(height: 8),
								SwitchListTile(
									contentPadding: EdgeInsets.zero,
									value: _activo,
									onChanged: (v) => setState(() => _activo = v),
									title: const Text('Perfil activo'),
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
