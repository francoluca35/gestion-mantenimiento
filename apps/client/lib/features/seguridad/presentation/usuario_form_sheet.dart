import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

const _supervisaOtOpciones = <String, String>{
	'ninguna': 'Ninguna',
	'de_su_sector': 'De su sector',
	'todas': 'Todas',
};

/// Diálogo alta / edición de usuario.
Future<bool?> showUsuarioForm(
	BuildContext context,
	WidgetRef ref, {
	Map<String, dynamic>? usuario,
}) {
	final esEdicion = usuario != null;
	return showDialog<bool>(
		context: context,
		builder: (context) => _UsuarioFormDialog(
			ref: ref,
			usuario: usuario,
			esEdicion: esEdicion,
		),
	);
}

class _UsuarioFormDialog extends ConsumerStatefulWidget {
	const _UsuarioFormDialog({
		required this.ref,
		required this.esEdicion,
		this.usuario,
	});

	final WidgetRef ref;
	final bool esEdicion;
	final Map<String, dynamic>? usuario;

	@override
	ConsumerState<_UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends ConsumerState<_UsuarioFormDialog> {
	final _formKey = GlobalKey<FormState>();
	final _nombreCtrl = TextEditingController();
	final _claveCtrl = TextEditingController();
	final _emailCtrl = TextEditingController();
	final _montoOcCtrl = TextEditingController();

	bool _loadingCatalogos = true;
	bool _submitting = false;
	String? _error;

	List<Map<String, dynamic>> _perfiles = [];
	List<Map<String, dynamic>> _sucursales = [];
	List<Map<String, dynamic>> _ubicaciones = [];

	String? _sucursalId;
	String? _sectorId;
	String? _perfilId;
	String _supervisaOt = 'ninguna';
	bool _esAdministrador = false;
	bool _supervisaSucursales = false;
	bool _supervisaOc = false;
	bool _activo = true;

	bool get _puedeAdministrar {
		final user = ref.read(authControllerProvider).session?.usuario;
		return user?.esAdministrador == true;
	}

	@override
	void initState() {
		super.initState();
		final u = widget.usuario;
		if (u != null) {
			_nombreCtrl.text = u['nombreUsuario'] as String? ?? '';
			_emailCtrl.text = u['email'] as String? ?? '';
			_montoOcCtrl.text = u['montoMaximoOc'] as String? ?? '';
			_sucursalId = u['sucursalId'] as String?;
			_sectorId = u['sectorId'] as String?;
			_perfilId = u['perfilId'] as String?;
			_supervisaOt = u['supervisaSolicitudesOt'] as String? ?? 'ninguna';
			_esAdministrador = u['esAdministrador'] as bool? ?? false;
			_supervisaSucursales = u['supervisaSucursales'] as bool? ?? false;
			_supervisaOc = u['supervisaSolicitudesOc'] as bool? ?? false;
			_activo = u['activo'] as bool? ?? true;
		}
		_loadCatalogos();
	}

	@override
	void dispose() {
		_nombreCtrl.dispose();
		_claveCtrl.dispose();
		_emailCtrl.dispose();
		_montoOcCtrl.dispose();
		super.dispose();
	}

	Future<void> _loadCatalogos() async {
		try {
			final api = widget.ref.read(apiClientProvider);
			final results = await Future.wait([
				api.getList('perfiles'),
				api.getList('sucursales'),
			]);
			if (!mounted) return;
			setState(() {
				_perfiles = results[0].cast<Map<String, dynamic>>();
				_sucursales = results[1].cast<Map<String, dynamic>>();
				_loadingCatalogos = false;
			});
			await _cargarUbicaciones();
		} catch (error) {
			if (!mounted) return;
			setState(() {
				_error = error.toString();
				_loadingCatalogos = false;
			});
		}
	}

	List<Map<String, dynamic>> _flattenUbicaciones(List<dynamic> nodes, [int depth = 0]) {
		final out = <Map<String, dynamic>>[];
		for (final raw in nodes) {
			final node = raw as Map<String, dynamic>;
			out.add({
				'id': node['id'],
				'nombre': '${'  ' * depth}${node['nombre']}',
			});
			final children = node['children'] as List<dynamic>? ?? [];
			out.addAll(_flattenUbicaciones(children, depth + 1));
		}
		return out;
	}

	Future<void> _cargarUbicaciones() async {
		if (_sucursalId == null) {
			setState(() {
				_ubicaciones = [];
				_sectorId = null;
			});
			return;
		}

		try {
			final tree = await widget.ref.read(apiClientProvider).getList(
				'ubicaciones/tree?sucursalId=$_sucursalId',
			);
			if (!mounted) return;
			setState(() {
				_ubicaciones = _flattenUbicaciones(tree);
				if (_sectorId != null &&
						!_ubicaciones.any((u) => u['id'] == _sectorId)) {
					_sectorId = null;
				}
			});
		} catch (_) {
			if (!mounted) return;
			setState(() => _ubicaciones = []);
		}
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) return;

		setState(() {
			_submitting = true;
			_error = null;
		});

		try {
			final api = widget.ref.read(apiClientProvider);
			final email = _emailCtrl.text.trim();
			final monto = _montoOcCtrl.text.trim();

			if (widget.esEdicion) {
				final body = <String, dynamic>{
					if (_claveCtrl.text.isNotEmpty) 'clave': _claveCtrl.text,
					if (email.isNotEmpty) 'email': email,
					'sucursalId': _sucursalId,
					'sectorId': _sectorId,
					'perfilId': _perfilId,
					'esAdministrador': _esAdministrador,
					'supervisaSucursales': _supervisaSucursales,
					'supervisaSolicitudesOt': _supervisaOt,
					'supervisaSolicitudesOc': _supervisaOc,
					'montoMaximoOc': monto.isEmpty ? null : monto,
					'activo': _activo,
				};
				await api.patchJson('usuarios/${widget.usuario!['id']}', body);
			} else {
				final body = <String, dynamic>{
					'nombreUsuario': _nombreCtrl.text.trim(),
					'clave': _claveCtrl.text,
					if (email.isNotEmpty) 'email': email,
					if (_sucursalId != null) 'sucursalId': _sucursalId,
					if (_sectorId != null) 'sectorId': _sectorId,
					if (_perfilId != null) 'perfilId': _perfilId,
					'esAdministrador': _esAdministrador,
					'supervisaSucursales': _supervisaSucursales,
					'supervisaSolicitudesOt': _supervisaOt,
					'supervisaSolicitudesOc': _supervisaOc,
					if (monto.isNotEmpty) 'montoMaximoOc': monto,
				};
				await api.postJson('usuarios', body);
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
		final wide = MediaQuery.sizeOf(context).width >= 600;

		return AlertDialog(
			title: Text(widget.esEdicion ? 'Editar usuario' : 'Nuevo usuario'),
			content: SizedBox(
				width: wide ? 480 : double.maxFinite,
				child: _loadingCatalogos
						? const SizedBox(
								height: 120,
								child: Center(child: CircularProgressIndicator()),
							)
						: Form(
								key: _formKey,
								child: SingleChildScrollView(
									child: Column(
										mainAxisSize: MainAxisSize.min,
										crossAxisAlignment: CrossAxisAlignment.stretch,
										children: [
											TextFormField(
												controller: _nombreCtrl,
												enabled: !widget.esEdicion,
												decoration: const InputDecoration(
													labelText: 'Usuario',
													border: OutlineInputBorder(),
												),
												validator: (v) =>
														(v == null || v.trim().length < 2)
																? 'Mínimo 2 caracteres'
																: null,
											),
											const SizedBox(height: 12),
											TextFormField(
												controller: _claveCtrl,
												obscureText: true,
												decoration: InputDecoration(
													labelText: widget.esEdicion
															? 'Nueva contraseña (opcional)'
															: 'Contraseña',
													border: const OutlineInputBorder(),
												),
												validator: (v) {
													if (!widget.esEdicion &&
															(v == null || v.length < 6)) {
														return 'Mínimo 6 caracteres';
													}
													if (widget.esEdicion &&
															v != null &&
															v.isNotEmpty &&
															v.length < 6) {
														return 'Mínimo 6 caracteres';
													}
													return null;
												},
											),
											const SizedBox(height: 12),
											TextFormField(
												controller: _emailCtrl,
												keyboardType: TextInputType.emailAddress,
												decoration: const InputDecoration(
													labelText: 'Email (opcional)',
													border: OutlineInputBorder(),
												),
											),
											const SizedBox(height: 12),
											DropdownButtonFormField<String?>(
												value: _sucursalId,
												isExpanded: true,
												decoration: const InputDecoration(
													labelText: 'Sucursal',
													border: OutlineInputBorder(),
												),
												items: [
													const DropdownMenuItem(
														value: null,
														child: Text('Todas las sucursales'),
													),
													..._sucursales.map(
														(s) => DropdownMenuItem(
															value: s['id'] as String,
															child: Text(s['nombre'] as String),
														),
													),
												],
												onChanged: (v) async {
													setState(() {
														_sucursalId = v;
														_sectorId = null;
													});
													await _cargarUbicaciones();
												},
											),
											const SizedBox(height: 12),
											DropdownButtonFormField<String?>(
												value: _sectorId,
												isExpanded: true,
												decoration: const InputDecoration(
													labelText: 'Sector (ubicación)',
													border: OutlineInputBorder(),
												),
												items: [
													const DropdownMenuItem(
														value: null,
														child: Text('Sin sector asignado'),
													),
													..._ubicaciones.map(
														(u) => DropdownMenuItem(
															value: u['id'] as String,
															child: Text(u['nombre'] as String),
														),
													),
												],
												onChanged: _sucursalId == null
														? null
														: (v) => setState(() => _sectorId = v),
											),
											const SizedBox(height: 12),
											DropdownButtonFormField<String?>(
												value: _perfilId,
												isExpanded: true,
												decoration: const InputDecoration(
													labelText: 'Perfil',
													border: OutlineInputBorder(),
												),
												items: [
													const DropdownMenuItem(
														value: null,
														child: Text('Sin perfil'),
													),
													..._perfiles.map(
														(p) => DropdownMenuItem(
															value: p['id'] as String,
															child: Text(p['nombre'] as String),
														),
													),
												],
												onChanged: (v) => setState(() => _perfilId = v),
											),
											const SizedBox(height: 12),
											DropdownButtonFormField<String>(
												value: _supervisaOt,
												isExpanded: true,
												decoration: const InputDecoration(
													labelText: 'Supervisa solicitudes OT',
													border: OutlineInputBorder(),
												),
												items: _supervisaOtOpciones.entries
														.map(
															(e) => DropdownMenuItem(
																value: e.key,
																child: Text(e.value),
															),
														)
														.toList(),
												onChanged: (v) => setState(
													() => _supervisaOt = v ?? 'ninguna',
												),
											),
											const SizedBox(height: 8),
											TextFormField(
												controller: _montoOcCtrl,
												keyboardType: TextInputType.number,
												decoration: const InputDecoration(
													labelText: 'Monto máximo OC (opcional)',
													border: OutlineInputBorder(),
												),
											),
											const SizedBox(height: 8),
											SwitchListTile(
												contentPadding: EdgeInsets.zero,
												value: _supervisaSucursales,
												onChanged: (v) =>
														setState(() => _supervisaSucursales = v),
												title: const Text('Supervisa sucursales'),
											),
											SwitchListTile(
												contentPadding: EdgeInsets.zero,
												value: _supervisaOc,
												onChanged: (v) => setState(() => _supervisaOc = v),
												title: const Text('Supervisa solicitudes OC'),
											),
											if (_puedeAdministrar)
												SwitchListTile(
													contentPadding: EdgeInsets.zero,
													value: _esAdministrador,
													onChanged: (v) =>
															setState(() => _esAdministrador = v),
													title: const Text('Administrador global'),
												),
											if (widget.esEdicion)
												SwitchListTile(
													contentPadding: EdgeInsets.zero,
													value: _activo,
													onChanged: (v) => setState(() => _activo = v),
													title: const Text('Usuario activo'),
												),
											if (_error != null) ...[
												const SizedBox(height: 12),
												Text(
													_error!,
													style: const TextStyle(color: AppColors.danger),
												),
											],
										],
									),
								),
							),
			),
			actions: [
				TextButton(
					onPressed: _submitting ? null : () => Navigator.pop(context, false),
					child: const Text('Cancelar'),
				),
				FilledButton(
					onPressed: _submitting || _loadingCatalogos ? null : _submit,
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
