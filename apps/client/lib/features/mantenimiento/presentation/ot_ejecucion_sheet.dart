import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../services/ot_storage_service.dart';

class OtEjecucionSheet extends ConsumerStatefulWidget {
	const OtEjecucionSheet({super.key, required this.ot});

	final Map<String, dynamic> ot;

	static Future<Map<String, dynamic>?> show(
		BuildContext context,
		Map<String, dynamic> ot,
	) {
		return showModalBottomSheet<Map<String, dynamic>>(
			context: context,
			isScrollControlled: true,
			useSafeArea: true,
			showDragHandle: true,
			builder: (context) => OtEjecucionSheet(ot: ot),
		);
	}

	@override
	ConsumerState<OtEjecucionSheet> createState() => _OtEjecucionSheetState();
}

class _OtEjecucionSheetState extends ConsumerState<OtEjecucionSheet> {
	final _novedadesCtrl = TextEditingController();
	final _comentariosCtrl = TextEditingController();
	late List<Map<String, dynamic>> _items;
	late List<OtFoto> _fotos;
	bool _guardando = false;
	bool _subiendoFoto = false;

	@override
	void initState() {
		super.initState();
		_novedadesCtrl.text =
				widget.ot['novedadesFueraDePrograma'] as String? ?? '';
		_comentariosCtrl.text = widget.ot['comentarios'] as String? ?? '';
		_items = _cargarItemsIniciales();
		_fotos = _cargarFotosIniciales();
	}

	@override
	void dispose() {
		_novedadesCtrl.dispose();
		_comentariosCtrl.dispose();
		super.dispose();
	}

	List<Map<String, dynamic>> _cargarItemsIniciales() {
		final checklist = (widget.ot['checklistCompletado'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>();
		if (checklist.isNotEmpty) {
			return checklist
					.map((item) => Map<String, dynamic>.from(item))
					.toList();
		}

		final planilla =
				(widget.ot['procedimiento']?['planillaLecturas'] as List<dynamic>? ??
						[])
					.cast<Map<String, dynamic>>();
		if (planilla.isNotEmpty) {
			return planilla
					.map(
						(item) => {
							'key': item['key'] ?? item['label'],
							'label': item['label'] ?? item['key'],
							'done': item['done'] == true,
						},
					)
					.toList();
		}

		return [
			{'key': 'inspeccion', 'label': 'Inspección general', 'done': false},
			{'key': 'seguridad', 'label': 'Condiciones de seguridad', 'done': false},
			{'key': 'limpieza', 'label': 'Limpieza del área', 'done': false},
		];
	}

	List<OtFoto> _cargarFotosIniciales() {
		return (widget.ot['fotos'] as List<dynamic>? ?? [])
				.cast<Map<String, dynamic>>()
				.map(OtFoto.fromJson)
				.toList();
	}

	String _resolveUrl(String url) {
		if (url.startsWith('http')) return url;
		final origin = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/v1/?$'), '');
		return '$origin$url';
	}

	Future<void> _agregarFoto() async {
		final result = await FilePicker.platform.pickFiles(
			type: FileType.image,
			withData: true,
			allowMultiple: false,
		);
		if (result == null || result.files.isEmpty) return;

		final file = result.files.first;
		final bytes = file.bytes;
		if (bytes == null) return;

		final user = ref.read(authControllerProvider).session?.usuario;
		final sucursalId = user?.sucursalId;
		if (sucursalId == null) return;

		final nombre = file.name.isNotEmpty ? file.name : 'foto.jpg';
		final contentType = _contentTypeForName(nombre);

		setState(() => _subiendoFoto = true);
		try {
			final foto = await OtStorageService(ref.read(apiClientProvider))
					.subirFotoOt(
						sucursalId: sucursalId,
						otId: widget.ot['id'] as String,
						bytes: bytes,
						fileName: nombre,
						contentType: contentType,
					);
			if (!mounted) return;
			setState(() => _fotos = [..._fotos, foto]);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('No se pudo subir la foto: $error')),
			);
		} finally {
			if (mounted) setState(() => _subiendoFoto = false);
		}
	}

	String _contentTypeForName(String name) {
		final lower = name.toLowerCase();
		if (lower.endsWith('.png')) return 'image/png';
		if (lower.endsWith('.webp')) return 'image/webp';
		return 'image/jpeg';
	}

	Future<void> _guardar() async {
		setState(() => _guardando = true);
		try {
			final detalle = await ref.read(apiClientProvider).patchJson(
						'ot/${widget.ot['id']}/ejecucion',
						{
							'items': _items,
							'novedadesFueraDePrograma': _novedadesCtrl.text.trim(),
							'comentarios': _comentariosCtrl.text.trim(),
							'fotos': _fotos.map((f) => f.toJson()).toList(),
						},
					);
			if (!mounted) return;
			Navigator.pop(context, detalle);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('$error')),
			);
		} finally {
			if (mounted) setState(() => _guardando = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final bottom = MediaQuery.viewInsetsOf(context).bottom;
		final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
		final completados = _items.where((i) => i['done'] == true).length;

		return Padding(
			padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
			child: ConstrainedBox(
				constraints: BoxConstraints(maxHeight: maxHeight),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Text(
							'Trabajo en OT #${widget.ot['numero']}',
							style: Theme.of(context).textTheme.titleLarge?.copyWith(
										fontWeight: FontWeight.w800,
									),
						),
						const SizedBox(height: 4),
						Text(
							'Marcá el checklist, dejá novedades y adjuntá fotos del trabajo.',
							style: TextStyle(
								color: Theme.of(context).colorScheme.onSurfaceVariant,
							),
						),
						const SizedBox(height: 16),
						Expanded(
							child: SingleChildScrollView(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
									_TextoSeccion(
										titulo: 'Checklist ($completados/${_items.length})',
										icono: Icons.checklist_rounded,
										child: Column(
											children: _items.asMap().entries.map((entry) {
												final index = entry.key;
												final item = entry.value;
												return CheckboxListTile(
													value: item['done'] == true,
													onChanged: (value) {
														setState(() {
															_items[index] = {
																...item,
																'done': value == true,
															};
														});
													},
													title: Text(item['label'] as String? ?? ''),
													controlAffinity: ListTileControlAffinity.leading,
													contentPadding: EdgeInsets.zero,
													dense: true,
												);
											}).toList(),
										),
									),
									const SizedBox(height: 16),
									_TextoSeccion(
										titulo: 'Novedades / tareas fuera de programa',
										icono: Icons.report_outlined,
										child: TextField(
											controller: _novedadesCtrl,
											maxLines: 3,
											decoration: const InputDecoration(
												hintText: 'Ej.: se encontró desgaste en válvula…',
												alignLabelWithHint: true,
											),
										),
									),
									const SizedBox(height: 16),
									_TextoSeccion(
										titulo: 'Comentarios del técnico',
										icono: Icons.notes_rounded,
										child: TextField(
											controller: _comentariosCtrl,
											maxLines: 2,
											decoration: const InputDecoration(
												hintText: 'Observaciones adicionales del trabajo…',
												alignLabelWithHint: true,
											),
										),
									),
									const SizedBox(height: 16),
									_TextoSeccion(
										titulo: 'Fotos (${_fotos.length})',
										icono: Icons.photo_camera_outlined,
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.stretch,
											children: [
												if (_fotos.isNotEmpty)
													Wrap(
														spacing: 8,
														runSpacing: 8,
														children: _fotos.map((foto) {
															return ClipRRect(
																borderRadius: BorderRadius.circular(10),
																child: Image.network(
																	_resolveUrl(foto.url),
																	width: 88,
																	height: 88,
																	fit: BoxFit.cover,
																	errorBuilder: (_, __, ___) => Container(
																		width: 88,
																		height: 88,
																		color: AppColors.surfaceMuted,
																		child: const Icon(Icons.broken_image_outlined),
																	),
																),
															);
														}).toList(),
													),
												const SizedBox(height: 8),
												OutlinedButton.icon(
													onPressed: _subiendoFoto ? null : _agregarFoto,
													icon: _subiendoFoto
															? const SizedBox(
																	width: 18,
																	height: 18,
																	child: CircularProgressIndicator(strokeWidth: 2),
																)
															: const Icon(Icons.add_a_photo_outlined),
													label: Text(
														_subiendoFoto ? 'Subiendo…' : 'Agregar foto',
													),
												),
											],
										),
									),
								],
							),
						),
						),
						const SizedBox(height: 16),
						FilledButton.icon(
							onPressed: _guardando ? null : _guardar,
							icon: _guardando
									? const SizedBox(
											width: 18,
											height: 18,
											child: CircularProgressIndicator(
												strokeWidth: 2,
												color: AppColors.onPrimary,
											),
										)
									: const Icon(Icons.save_rounded),
							label: Text(_guardando ? 'Guardando…' : 'Guardar trabajo'),
						),
					],
				),
			),
		);
	}
}

class _TextoSeccion extends StatelessWidget {
	const _TextoSeccion({
		required this.titulo,
		required this.icono,
		required this.child,
	});

	final String titulo;
	final IconData icono;
	final Widget child;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Row(
					children: [
						Icon(icono, size: 18, color: AppColors.accent),
						const SizedBox(width: 8),
						Text(
							titulo,
							style: const TextStyle(fontWeight: FontWeight.w700),
						),
					],
				),
				const SizedBox(height: 8),
				child,
			],
		);
	}
}
