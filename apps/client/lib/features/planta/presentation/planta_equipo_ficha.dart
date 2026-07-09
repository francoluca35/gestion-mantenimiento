import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../services/equipo_storage_service.dart';

class PlantaEquipoFicha extends ConsumerStatefulWidget {
	const PlantaEquipoFicha({
		super.key,
		required this.detalle,
		this.sucursalId,
		this.onUpdated,
	});

	final Map<String, dynamic> detalle;
	final String? sucursalId;
	final Future<void> Function()? onUpdated;

	@override
	ConsumerState<PlantaEquipoFicha> createState() => _PlantaEquipoFichaState();
}

class _PlantaEquipoFichaState extends ConsumerState<PlantaEquipoFicha>
		with SingleTickerProviderStateMixin {
	late TabController _tabs;
	List<Map<String, dynamic>> _historial = [];
	List<Map<String, dynamic>> _procedimientos = [];
	List<Map<String, dynamic>> _documentos = [];
	List<Map<String, dynamic>> _componentes = [];
	bool _loadingHistorial = false;
	bool _loadingProcedimientos = false;
	bool _loadingDocumentos = false;
	bool _loadingComponentes = false;
	bool _togglingFuera = false;
	String? _historialError;
	String? _procedimientosError;
	String? _documentosError;
	String? _componentesError;

	AuthUser? get _user => ref.read(authControllerProvider).session?.usuario;

	bool get _canMarcarFuera =>
			_user?.tieneDerecho('archivos.equipos.marcar_fuera_de_servicio') == true ||
			_user?.esAdministrador == true;

	bool get _canModificar =>
			_user?.tieneDerecho('archivos.equipos.modificar') == true ||
			_user?.esAdministrador == true;

	String get _equipoId => widget.detalle['id'] as String;

	List<Map<String, dynamic>> get _lecturas =>
			(widget.detalle['lecturas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

	List<Map<String, dynamic>> get _camposLectura {
		final tipo = widget.detalle['tipoEquipo'] as Map<String, dynamic>?;
		final raw = tipo?['camposLectura'];
		if (raw is! List) return [];
		return raw.cast<Map<String, dynamic>>();
	}

	@override
	void initState() {
		super.initState();
		_tabs = TabController(length: 6, vsync: this);
		_tabs.addListener(_onTabChanged);
	}

	@override
	void dispose() {
		_tabs.removeListener(_onTabChanged);
		_tabs.dispose();
		super.dispose();
	}

	void _onTabChanged() {
		if (!_tabs.indexIsChanging) _loadTabData(_tabs.index);
	}

	@override
	void didUpdateWidget(covariant PlantaEquipoFicha oldWidget) {
		super.didUpdateWidget(oldWidget);
		if (oldWidget.detalle['id'] != widget.detalle['id']) {
			_historial = [];
			_procedimientos = [];
			_documentos = [];
			_componentes = [];
			_loadTabData(_tabs.index);
		}
	}

	Future<void> _loadTabData(int index) async {
		if (index == 1 && _componentes.isEmpty && !_loadingComponentes) {
			setState(() {
				_loadingComponentes = true;
				_componentesError = null;
			});
			try {
				final data =
						await ref.read(apiClientProvider).getList('equipos/$_equipoId/componentes');
				if (mounted) setState(() => _componentes = data.cast<Map<String, dynamic>>());
			} catch (error) {
				if (mounted) setState(() => _componentesError = error.toString());
			} finally {
				if (mounted) setState(() => _loadingComponentes = false);
			}
		}

		if (index == 3 && _historial.isEmpty && !_loadingHistorial) {
			setState(() {
				_loadingHistorial = true;
				_historialError = null;
			});
			try {
				final data = await ref.read(apiClientProvider).getList('equipos/$_equipoId/historial');
				if (mounted) setState(() => _historial = data.cast<Map<String, dynamic>>());
			} catch (error) {
				if (mounted) setState(() => _historialError = error.toString());
			} finally {
				if (mounted) setState(() => _loadingHistorial = false);
			}
		}

		if (index == 4 && _procedimientos.isEmpty && !_loadingProcedimientos) {
			setState(() {
				_loadingProcedimientos = true;
				_procedimientosError = null;
			});
			try {
				final data =
						await ref.read(apiClientProvider).getList('equipos/$_equipoId/procedimientos');
				if (mounted) setState(() => _procedimientos = data.cast<Map<String, dynamic>>());
			} catch (error) {
				if (mounted) setState(() => _procedimientosError = error.toString());
			} finally {
				if (mounted) setState(() => _loadingProcedimientos = false);
			}
		}

		if (index == 5 && _documentos.isEmpty && !_loadingDocumentos) {
			setState(() {
				_loadingDocumentos = true;
				_documentosError = null;
			});
			try {
				final data =
						await ref.read(apiClientProvider).getList('equipos/$_equipoId/documentos');
				if (mounted) setState(() => _documentos = data.cast<Map<String, dynamic>>());
			} catch (error) {
				if (mounted) setState(() => _documentosError = error.toString());
			} finally {
				if (mounted) setState(() => _loadingDocumentos = false);
			}
		}
	}

	Future<void> _registrarLectura() async {
		final tipoCtrl = TextEditingController(
			text: _camposLectura.isNotEmpty
					? _camposLectura.first['key'] as String? ?? 'horas'
					: 'horas',
		);
		final valorCtrl = TextEditingController();
		final notasCtrl = TextEditingController();

		final ok = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Registrar lectura'),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						if (_camposLectura.isNotEmpty)
							DropdownButtonFormField<String>(
								value: tipoCtrl.text.isEmpty ? null : tipoCtrl.text,
								items: _camposLectura
										.map(
											(c) => DropdownMenuItem(
												value: c['key'] as String,
												child: Text(c['label'] as String? ?? c['key'] as String),
											),
										)
										.toList(),
								onChanged: (v) {
									if (v != null) tipoCtrl.text = v;
								},
								decoration: const InputDecoration(labelText: 'Tipo'),
							)
						else
							TextField(
								controller: tipoCtrl,
								decoration: const InputDecoration(labelText: 'Tipo'),
							),
						const SizedBox(height: 8),
						TextField(
							controller: valorCtrl,
							keyboardType: TextInputType.number,
							decoration: const InputDecoration(labelText: 'Valor'),
						),
						const SizedBox(height: 8),
						TextField(
							controller: notasCtrl,
							decoration: const InputDecoration(labelText: 'Notas (opcional)'),
						),
					],
				),
				actions: [
					TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
					FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
				],
			),
		);

		final tipo = tipoCtrl.text.trim();
		final valor = double.tryParse(valorCtrl.text.trim());
		final notas = notasCtrl.text.trim();
		tipoCtrl.dispose();
		valorCtrl.dispose();
		notasCtrl.dispose();

		if (ok != true || valor == null) return;

		try {
			await ref.read(apiClientProvider).postJson('equipos/$_equipoId/lecturas', {
				'tipo': tipo,
				'valor': valor,
				if (notas.isNotEmpty) 'notas': notas,
			});
			if (!mounted) return;
			await widget.onUpdated?.call();
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
	}

	Future<void> _subirDocumento() async {
		if (widget.sucursalId == null) return;
		final result = await FilePicker.platform.pickFiles(withData: true);
		if (result == null || result.files.isEmpty) return;

		final file = result.files.first;
		final bytes = file.bytes;
		if (bytes == null) return;

		final contentType = _contentTypeFor(file.name);
		if (contentType == null) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Formato no soportado (jpg, png, pdf, mp4)')),
			);
			return;
		}

		setState(() => _loadingDocumentos = true);
		try {
			final storage = EquipoStorageService(ref.read(apiClientProvider));
			final presign = await storage.subirDocumento(
				sucursalId: widget.sucursalId!,
				equipoId: _equipoId,
				bytes: bytes,
				fileName: file.name,
				contentType: contentType,
				kind: contentType.contains('pdf') ? 'pdf' : 'planos',
			);

			await ref.read(apiClientProvider).postJson('equipos/$_equipoId/documentos', {
				'nombre': file.name,
				'storageKey': presign['key'],
				'contentType': contentType,
				'tamano': bytes.length,
				'tipo': contentType.contains('pdf')
						? 'pdf'
						: contentType.contains('mp4')
								? 'video'
								: 'plano',
			});

			if (!mounted) return;
			setState(() => _documentos = []);
			await _loadTabData(5);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		} finally {
			if (mounted) setState(() => _loadingDocumentos = false);
		}
	}

	String? _contentTypeFor(String name) {
		final lower = name.toLowerCase();
		if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
		if (lower.endsWith('.png')) return 'image/png';
		if (lower.endsWith('.pdf')) return 'application/pdf';
		if (lower.endsWith('.mp4')) return 'video/mp4';
		return null;
	}

	Future<void> _eliminarDocumento(String documentoId) async {
		try {
			await ref.read(apiClientProvider).deleteJson('equipos/$_equipoId/documentos/$documentoId');
			if (!mounted) return;
			setState(() => _documentos.removeWhere((d) => d['id'] == documentoId));
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
	}

	void _abrirDocumento(Map<String, dynamic> doc) {
		final key = doc['storageKey'] as String;
		final url = '${AppConfig.apiBaseUrl}/storage/files/${Uri.encodeComponent(key)}';
		Clipboard.setData(ClipboardData(text: url));
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(content: Text('URL copiada al portapapeles')),
		);
	}

	Future<void> _agregarComponente() async {
		final nombreCtrl = TextEditingController();
		final codigoCtrl = TextEditingController();

		final ok = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Nuevo componente'),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						TextField(
							controller: nombreCtrl,
							autofocus: true,
							decoration: const InputDecoration(labelText: 'Nombre'),
						),
						const SizedBox(height: 8),
						TextField(
							controller: codigoCtrl,
							decoration: const InputDecoration(labelText: 'Código (opcional)'),
						),
					],
				),
				actions: [
					TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
					FilledButton(
						onPressed: () => Navigator.pop(ctx, nombreCtrl.text.trim().isNotEmpty),
						child: const Text('Guardar'),
					),
				],
			),
		);

		final nombre = nombreCtrl.text.trim();
		final codigo = codigoCtrl.text.trim();
		nombreCtrl.dispose();
		codigoCtrl.dispose();

		if (ok != true) return;

		try {
			await ref.read(apiClientProvider).postJson('equipos/$_equipoId/componentes', {
				'nombre': nombre,
				if (codigo.isNotEmpty) 'codigo': codigo,
			});
			if (!mounted) return;
			setState(() => _componentes = []);
			await _loadTabData(1);
			await widget.onUpdated?.call();
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
	}

	Future<void> _editarComponente(Map<String, dynamic> componente) async {
		final nombreCtrl = TextEditingController(text: componente['nombre'] as String? ?? '');
		final codigoCtrl = TextEditingController(text: componente['codigo'] as String? ?? '');

		final ok = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Editar componente'),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						TextField(
							controller: nombreCtrl,
							autofocus: true,
							decoration: const InputDecoration(labelText: 'Nombre'),
						),
						const SizedBox(height: 8),
						TextField(
							controller: codigoCtrl,
							decoration: const InputDecoration(labelText: 'Código (opcional)'),
						),
					],
				),
				actions: [
					TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
					FilledButton(
						onPressed: () => Navigator.pop(ctx, nombreCtrl.text.trim().isNotEmpty),
						child: const Text('Guardar'),
					),
				],
			),
		);

		final nombre = nombreCtrl.text.trim();
		final codigo = codigoCtrl.text.trim();
		nombreCtrl.dispose();
		codigoCtrl.dispose();

		if (ok != true) return;

		try {
			await ref.read(apiClientProvider).patchJson(
						'equipos/$_equipoId/componentes/${componente['id']}',
						{
							'nombre': nombre,
							if (codigo.isNotEmpty) 'codigo': codigo,
						},
					);
			if (!mounted) return;
			setState(() => _componentes = []);
			await _loadTabData(1);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
	}

	Future<void> _eliminarComponente(String componenteId) async {
		try {
			await ref.read(apiClientProvider).deleteJson(
						'equipos/$_equipoId/componentes/$componenteId',
					);
			if (!mounted) return;
			setState(() => _componentes.removeWhere((c) => c['id'] == componenteId));
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
	}

	Future<void> _toggleFueraServicio(bool fuera) async {
		setState(() => _togglingFuera = true);
		try {
			await ref.read(apiClientProvider).postJson(
						'equipos/$_equipoId/fuera-de-servicio',
						{'fuera': fuera},
					);
			if (!mounted) return;
			await widget.onUpdated?.call();
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		} finally {
			if (mounted) setState(() => _togglingFuera = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final fuera = widget.detalle['fueraDeServicio'] as bool? ?? false;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				if (_canMarcarFuera)
					SwitchListTile(
						contentPadding: EdgeInsets.zero,
						value: fuera,
						onChanged: _togglingFuera ? null : _toggleFueraServicio,
						title: const Text('Fuera de servicio'),
					),
				TabBar(
					controller: _tabs,
					isScrollable: true,
					tabs: const [
						Tab(text: 'General'),
						Tab(text: 'Componentes'),
						Tab(text: 'Lecturas'),
						Tab(text: 'Historial'),
						Tab(text: 'Procedimientos'),
						Tab(text: 'Documentos'),
					],
				),
				const SizedBox(height: 12),
				SizedBox(
					height: 300,
					child: TabBarView(
						controller: _tabs,
						children: [
							SingleChildScrollView(child: _MaquinaInfoBody(detalle: widget.detalle)),
							_ComponentesPanel(
								loading: _loadingComponentes,
								error: _componentesError,
								items: _componentes,
								canEditar: _canModificar,
								onAgregar: _agregarComponente,
								onEditar: _editarComponente,
								onEliminar: _canModificar ? _eliminarComponente : null,
								onRetry: () {
									_componentes = [];
									_loadTabData(1);
								},
							),
							_LecturasPanel(
								lecturas: _lecturas,
								canAgregar: _canModificar,
								onAgregar: _registrarLectura,
							),
							_AsyncListPanel(
								loading: _loadingHistorial,
								error: _historialError,
								emptyLabel: 'Sin eventos en el historial',
								items: _historial,
								itemBuilder: (item) {
									final ot = item['ot'] as Map<String, dynamic>?;
									return ListTile(
										dense: true,
										contentPadding: EdgeInsets.zero,
										title: Text(ot?['numero']?.toString() ?? 'Evento'),
										subtitle: Text(item['comentario'] as String? ?? ''),
									);
								},
								onRetry: () {
									_historial = [];
									_loadTabData(3);
								},
							),
							_AsyncListPanel(
								loading: _loadingProcedimientos,
								error: _procedimientosError,
								emptyLabel: 'Sin procedimientos asociados',
								items: _procedimientos,
								itemBuilder: (item) {
									final proc = item['procedimiento'] as Map<String, dynamic>?;
									return ListTile(
										dense: true,
										contentPadding: EdgeInsets.zero,
										title: Text(proc?['nombre'] as String? ?? ''),
										subtitle: Text('#${proc?['codigo'] ?? ''}'),
									);
								},
								onRetry: () {
									_procedimientos = [];
									_loadTabData(4);
								},
							),
							_DocumentosPanel(
								loading: _loadingDocumentos,
								error: _documentosError,
								items: _documentos,
								canSubir: _canModificar,
								onSubir: _subirDocumento,
								onAbrir: _abrirDocumento,
								onEliminar: _canModificar ? _eliminarDocumento : null,
								onRetry: () {
									_documentos = [];
									_loadTabData(5);
								},
							),
						],
					),
				),
			],
		);
	}
}

class _MaquinaInfoBody extends StatelessWidget {
	const _MaquinaInfoBody({required this.detalle});

	final Map<String, dynamic> detalle;

	@override
	Widget build(BuildContext context) {
		final tipo = detalle['tipoEquipo'] as Map<String, dynamic>?;
		final ubicacion = detalle['ubicacion'] as Map<String, dynamic>?;
		final campos = detalle['detalle'] as Map<String, dynamic>? ?? {};

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Wrap(
					spacing: 12,
					runSpacing: 12,
					children: [
						_InfoChip(label: 'Código', value: '${detalle['codigo'] ?? '-'}'),
						_InfoChip(label: 'Tipo', value: '${tipo?['nombre'] ?? '-'}'),
						_InfoChip(label: 'Ubicación', value: '${ubicacion?['nombre'] ?? '-'}'),
					],
				),
				if (campos.isNotEmpty) ...[
					const SizedBox(height: 16),
					...campos.entries.map(
						(e) => ListTile(
							dense: true,
							contentPadding: EdgeInsets.zero,
							title: Text(e.key),
							subtitle: Text('${e.value}'),
						),
					),
				],
			],
		);
	}
}

class _ComponentesPanel extends StatelessWidget {
	const _ComponentesPanel({
		required this.loading,
		required this.error,
		required this.items,
		required this.onRetry,
		this.canEditar = false,
		this.onAgregar,
		this.onEditar,
		this.onEliminar,
	});

	final bool loading;
	final String? error;
	final List<Map<String, dynamic>> items;
	final VoidCallback onRetry;
	final bool canEditar;
	final VoidCallback? onAgregar;
	final Future<void> Function(Map<String, dynamic> componente)? onEditar;
	final Future<void> Function(String id)? onEliminar;

	@override
	Widget build(BuildContext context) {
		if (loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
		if (error != null) {
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(error!),
						TextButton(onPressed: onRetry, child: const Text('Reintentar')),
					],
				),
			);
		}

		return Column(
			children: [
				if (canEditar && onAgregar != null)
					Align(
						alignment: Alignment.centerRight,
						child: TextButton.icon(
							onPressed: onAgregar,
							icon: const Icon(Icons.add_circle_outline, size: 18),
							label: const Text('Agregar'),
						),
					),
				if (items.isEmpty)
					const Expanded(child: Center(child: Text('Sin componentes')))
				else
					Expanded(
						child: ListView.builder(
							itemCount: items.length,
							itemBuilder: (_, index) {
								final item = items[index];
								return ListTile(
									dense: true,
									contentPadding: EdgeInsets.zero,
									title: Text(item['nombre'] as String? ?? ''),
									subtitle: Text(item['codigo'] as String? ?? '—'),
									trailing: canEditar
											? PopupMenuButton<String>(
													onSelected: (action) async {
														switch (action) {
															case 'edit':
																await onEditar?.call(item);
															case 'delete':
																await onEliminar?.call(item['id'] as String);
														}
													},
													itemBuilder: (context) => const [
														PopupMenuItem(value: 'edit', child: Text('Editar')),
														PopupMenuItem(value: 'delete', child: Text('Eliminar')),
													],
												)
											: null,
								);
							},
						),
					),
			],
		);
	}
}

class _InfoChip extends StatelessWidget {
	const _InfoChip({required this.label, required this.value});

	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
				borderRadius: BorderRadius.circular(12),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(label, style: Theme.of(context).textTheme.bodySmall),
					Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
				],
			),
		);
	}
}

class _LecturasPanel extends StatelessWidget {
	const _LecturasPanel({
		required this.lecturas,
		this.canAgregar = false,
		this.onAgregar,
	});

	final List<Map<String, dynamic>> lecturas;
	final bool canAgregar;
	final VoidCallback? onAgregar;

	double _valor(dynamic raw) {
		if (raw is num) return raw.toDouble();
		return double.tryParse(raw?.toString() ?? '') ?? 0;
	}

	@override
	Widget build(BuildContext context) {
		final max = lecturas.isEmpty
				? 1.0
				: lecturas.map(_valor).reduce((a, b) => a > b ? a : b);

		return Column(
			children: [
				if (canAgregar && onAgregar != null)
					Align(
						alignment: Alignment.centerRight,
						child: TextButton.icon(
							onPressed: onAgregar,
							icon: const Icon(Icons.add_chart_outlined, size: 18),
							label: const Text('Registrar'),
						),
					),
				if (lecturas.isEmpty)
					const Expanded(child: Center(child: Text('Sin lecturas')))
				else ...[
					SizedBox(
						height: 72,
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.end,
							children: lecturas.take(8).map((l) {
								final v = _valor(l['valor']);
								final h = max > 0 ? (v / max) * 56 : 4.0;
								return Expanded(
									child: Padding(
										padding: const EdgeInsets.symmetric(horizontal: 2),
										child: Container(
											height: h.clamp(4, 56),
											decoration: BoxDecoration(
												color: AppColors.primary.withValues(alpha: 0.85),
												borderRadius: BorderRadius.circular(4),
											),
										),
									),
								);
							}).toList(),
						),
					),
					Expanded(
						child: ListView.builder(
							itemCount: lecturas.length,
							itemBuilder: (_, i) {
								final l = lecturas[i];
								return ListTile(
									dense: true,
									contentPadding: EdgeInsets.zero,
									title: Text('${l['tipo']}: ${l['valor']}'),
								);
							},
						),
					),
				],
			],
		);
	}
}

class _AsyncListPanel extends StatelessWidget {
	const _AsyncListPanel({
		required this.loading,
		required this.error,
		required this.emptyLabel,
		required this.items,
		required this.itemBuilder,
		required this.onRetry,
	});

	final bool loading;
	final String? error;
	final String emptyLabel;
	final List<Map<String, dynamic>> items;
	final Widget Function(Map<String, dynamic> item) itemBuilder;
	final VoidCallback onRetry;

	@override
	Widget build(BuildContext context) {
		if (loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
		if (error != null) {
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(error!),
						TextButton(onPressed: onRetry, child: const Text('Reintentar')),
					],
				),
			);
		}
		if (items.isEmpty) return Center(child: Text(emptyLabel));
		return ListView.builder(
			itemCount: items.length,
			itemBuilder: (_, i) => itemBuilder(items[i]),
		);
	}
}

class _DocumentosPanel extends StatelessWidget {
	const _DocumentosPanel({
		required this.loading,
		required this.error,
		required this.items,
		required this.onRetry,
		this.canSubir = false,
		this.onSubir,
		this.onAbrir,
		this.onEliminar,
	});

	final bool loading;
	final String? error;
	final List<Map<String, dynamic>> items;
	final VoidCallback onRetry;
	final bool canSubir;
	final VoidCallback? onSubir;
	final void Function(Map<String, dynamic> doc)? onAbrir;
	final Future<void> Function(String id)? onEliminar;

	@override
	Widget build(BuildContext context) {
		if (loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
		if (error != null) {
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(error!),
						TextButton(onPressed: onRetry, child: const Text('Reintentar')),
					],
				),
			);
		}

		return Column(
			children: [
				if (canSubir && onSubir != null)
					Align(
						alignment: Alignment.centerRight,
						child: TextButton.icon(
							onPressed: onSubir,
							icon: const Icon(Icons.upload_file_outlined, size: 18),
							label: const Text('Adjuntar'),
						),
					),
				if (items.isEmpty)
					const Expanded(child: Center(child: Text('Sin documentos')))
				else
					Expanded(
						child: ListView.builder(
							itemCount: items.length,
							itemBuilder: (_, i) {
								final doc = items[i];
								return ListTile(
									dense: true,
									contentPadding: EdgeInsets.zero,
									title: Text(doc['nombre'] as String? ?? ''),
									subtitle: Text(doc['tipo'] as String? ?? ''),
									trailing: Row(
										mainAxisSize: MainAxisSize.min,
										children: [
											IconButton(
												icon: const Icon(Icons.link_rounded, size: 20),
												onPressed: onAbrir == null ? null : () => onAbrir!(doc),
											),
											if (onEliminar != null)
												IconButton(
													icon: const Icon(Icons.delete_outline_rounded, size: 20),
													onPressed: () => onEliminar!(doc['id'] as String),
												),
										],
									),
								);
							},
						),
					),
			],
		);
	}
}
