import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

List<Map<String, dynamic>> flattenUbicaciones(
	List<Map<String, dynamic>> nodes, [
	int depth = 0,
]) {
	final out = <Map<String, dynamic>>[];
	for (final node in nodes) {
		out.add({
			'id': node['id'],
			'nombre': '${'  ' * depth}${node['nombre']}',
			'depth': depth,
		});
		final children = node['children'] as List<dynamic>? ?? [];
		out.addAll(
			flattenUbicaciones(children.cast<Map<String, dynamic>>(), depth + 1),
		);
	}
	return out;
}

List<Map<String, dynamic>> parseCamposDetalle(Map<String, dynamic>? tipo) {
	final raw = tipo?['camposDetalle'];
	if (raw is! List) return [];
	return raw.cast<Map<String, dynamic>>();
}

List<Widget> buildCamposDetalleFields({
	required List<Map<String, dynamic>> campos,
	required Map<String, TextEditingController> controllers,
}) {
	return campos.map((campo) {
		final key = campo['key'] as String? ?? '';
		final label = campo['label'] as String? ?? key;
		final ctrl = controllers.putIfAbsent(key, TextEditingController.new);
		return Padding(
			padding: const EdgeInsets.only(bottom: 8),
			child: TextField(
				controller: ctrl,
				decoration: InputDecoration(labelText: label),
			),
		);
	}).toList();
}

Map<String, dynamic> collectDetalle(
	List<Map<String, dynamic>> campos,
	Map<String, TextEditingController> controllers,
) {
	final detalle = <String, dynamic>{};
	for (final campo in campos) {
		final key = campo['key'] as String? ?? '';
		final value = controllers[key]?.text.trim() ?? '';
		if (value.isNotEmpty) detalle[key] = value;
	}
	return detalle;
}

Future<bool> showEditUbicacionDialog({
	required BuildContext context,
	required ApiClient api,
	required String ubicacionId,
	required String nombreActual,
}) async {
	final controller = TextEditingController(text: nombreActual);
	final ok = await showDialog<bool>(
		context: context,
		builder: (ctx) => AlertDialog(
			title: const Text('Editar ubicación'),
			content: TextField(
				controller: controller,
				autofocus: true,
				decoration: const InputDecoration(labelText: 'Nombre'),
			),
			actions: [
				TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
				FilledButton(
					onPressed: () => Navigator.pop(ctx, controller.text.trim().isNotEmpty),
					child: const Text('Guardar'),
				),
			],
		),
	);

	if (ok != true) {
		controller.dispose();
		return false;
	}

	final nombre = controller.text.trim().toUpperCase();
	controller.dispose();

	try {
		await api.patchJson('ubicaciones/$ubicacionId', {'nombre': nombre});
		return true;
	} catch (error) {
		if (context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
		return false;
	}
}

Future<bool> confirmDeleteUbicacion({
	required BuildContext context,
	required ApiClient api,
	required String ubicacionId,
	required String nombre,
}) async {
	final ok = await showDialog<bool>(
		context: context,
		builder: (ctx) => AlertDialog(
			title: const Text('Eliminar ubicación'),
			content: Text(
				'¿Desactivar "$nombre"? Solo se puede si no tiene sectores hijos ni máquinas.',
			),
			actions: [
				TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
				FilledButton(
					style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
					onPressed: () => Navigator.pop(ctx, true),
					child: const Text('Eliminar'),
				),
			],
		),
	);
	if (ok != true) return false;

	try {
		await api.deleteJson('ubicaciones/$ubicacionId');
		return true;
	} catch (error) {
		if (context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
		return false;
	}
}

Future<bool> showMoverUbicacionDialog({
	required BuildContext context,
	required ApiClient api,
	required String ubicacionId,
	required List<Map<String, dynamic>> ubicacionesTree,
	Set<String> excludeIds = const {},
}) async {
	final opciones = flattenUbicaciones(ubicacionesTree)
			.where((u) => !excludeIds.contains(u['id']))
			.toList();

	String? parentId;
	final ok = await showDialog<bool>(
		context: context,
		builder: (ctx) => StatefulBuilder(
			builder: (ctx, setDialog) => AlertDialog(
				title: const Text('Mover ubicación'),
				content: SizedBox(
					width: 400,
					child: DropdownButtonFormField<String?>(
						value: parentId,
						isExpanded: true,
						decoration: const InputDecoration(labelText: 'Nuevo padre'),
						items: [
							const DropdownMenuItem(value: null, child: Text('Raíz de la planta')),
							...opciones.map(
								(u) => DropdownMenuItem(
									value: u['id'] as String,
									child: Text(u['nombre'] as String),
								),
							),
						],
						onChanged: (v) => setDialog(() => parentId = v),
					),
				),
				actions: [
					TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
					FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mover')),
				],
			),
		),
	);
	if (ok != true) return false;

	try {
		await api.postJson('ubicaciones/$ubicacionId/mover', {'parentId': parentId});
		return true;
	} catch (error) {
		if (context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
		return false;
	}
}

Future<bool> showMoverEquipoDialog({
	required BuildContext context,
	required ApiClient api,
	required String equipoId,
	required List<Map<String, String>> hojas,
}) async {
	if (hojas.isEmpty) {
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(content: Text('No hay sectores hoja disponibles')),
		);
		return false;
	}

	String? ubicacionId = hojas.first['id'];
	final ok = await showDialog<bool>(
		context: context,
		builder: (ctx) => StatefulBuilder(
			builder: (ctx, setDialog) => AlertDialog(
				title: const Text('Mover máquina'),
				content: DropdownButtonFormField<String>(
					value: ubicacionId,
					isExpanded: true,
					decoration: const InputDecoration(labelText: 'Sector destino'),
					items: hojas
							.map(
								(h) => DropdownMenuItem(
									value: h['id'],
									child: Text(h['label'] ?? h['id']!),
								),
							)
							.toList(),
					onChanged: (v) => setDialog(() => ubicacionId = v),
				),
				actions: [
					TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
					FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mover')),
				],
			),
		),
	);
	if (ok != true || ubicacionId == null) return false;

	try {
		await api.postJson('equipos/$equipoId/mover', {'ubicacionId': ubicacionId});
		return true;
	} catch (error) {
		if (context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
		return false;
	}
}

Future<bool> showEditEquipoDialog({
	required BuildContext context,
	required ApiClient api,
	required Map<String, dynamic> detalle,
}) async {
	final nombreCtrl = TextEditingController(text: detalle['nombre'] as String? ?? '');
	final codigoCtrl = TextEditingController(text: detalle['codigo'] as String? ?? '');
	final tipo = detalle['tipoEquipo'] as Map<String, dynamic>?;
	final campos = parseCamposDetalle(tipo);
	final detalleMap = (detalle['detalle'] as Map<String, dynamic>?) ?? {};
	final campoCtrls = <String, TextEditingController>{};
	for (final campo in campos) {
		final key = campo['key'] as String? ?? '';
		campoCtrls[key] = TextEditingController(text: detalleMap[key]?.toString() ?? '');
	}

	final ok = await showDialog<bool>(
		context: context,
		builder: (ctx) => AlertDialog(
			title: const Text('Editar máquina'),
			content: SizedBox(
				width: 420,
				child: SingleChildScrollView(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							Container(
								padding: const EdgeInsets.all(12),
								decoration: BoxDecoration(
									color: AppColors.brandYellow.withValues(alpha: 0.1),
									borderRadius: BorderRadius.circular(10),
								),
								child: Text(
									'${detalle['nombre'] ?? ''} · ${detalle['codigo'] ?? ''}',
									style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
								),
							),
							const SizedBox(height: 14),
							TextField(
								controller: nombreCtrl,
								decoration: const InputDecoration(
									labelText: 'Nombre de la máquina',
									border: OutlineInputBorder(),
								),
							),
							const SizedBox(height: 10),
							TextField(
								controller: codigoCtrl,
								decoration: const InputDecoration(
									labelText: 'Código interno',
									helperText: 'Debe ser único en la planta',
									border: OutlineInputBorder(),
								),
							),
							if (campos.isNotEmpty) ...[
								const SizedBox(height: 14),
								const Text(
									'Datos adicionales del tipo',
									style: TextStyle(fontWeight: FontWeight.w600),
								),
								const SizedBox(height: 8),
								...buildCamposDetalleFields(
									campos: campos,
									controllers: campoCtrls,
								),
							],
						],
					),
				),
			),
			actions: [
				TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
				FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
			],
		),
	);

	if (ok != true) return false;

	final nombre = nombreCtrl.text.trim().toUpperCase();
	final codigo = codigoCtrl.text.trim().toUpperCase();
	final detallePayload = campos.isNotEmpty ? collectDetalle(campos, campoCtrls) : null;

	for (final ctrl in campoCtrls.values) {
		ctrl.dispose();
	}
	nombreCtrl.dispose();
	codigoCtrl.dispose();

	try {
		await api.patchJson('equipos/${detalle['id']}', {
			'nombre': nombre,
			'codigo': codigo,
			if (detallePayload != null) 'detalle': detallePayload,
		});
		return true;
	} catch (error) {
		if (context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
		return false;
	}
}

Future<bool> showCreateMaquinaDialog({
	required BuildContext context,
	required ApiClient api,
	required String sucursalId,
	required String ubicacionId,
	required String ubicacionNombre,
	required List<Map<String, dynamic>> tipos,
}) async {
	if (tipos.isEmpty) {
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(content: Text('No hay tipos de máquina configurados')),
		);
		return false;
	}

	final nombreCtrl = TextEditingController();
	final codigoCtrl = TextEditingController();
	var tipoId = tipos.first['id'] as String;
	final campoCtrls = <String, TextEditingController>{};

	final ok = await showDialog<bool>(
		context: context,
		builder: (ctx) => StatefulBuilder(
			builder: (ctx, setDialog) {
				final tipoActual = tipos.firstWhere((t) => t['id'] == tipoId);
				final camposActuales = parseCamposDetalle(tipoActual);
				return AlertDialog(
					title: const Text('Nueva máquina'),
					content: SizedBox(
						width: 420,
						child: SingleChildScrollView(
							child: Column(
								mainAxisSize: MainAxisSize.min,
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									Container(
										padding: const EdgeInsets.all(12),
										decoration: BoxDecoration(
											color: AppColors.brandYellow.withValues(alpha: 0.1),
											borderRadius: BorderRadius.circular(10),
										),
										child: Text(
											'Vas a registrar una máquina en: $ubicacionNombre',
											style: const TextStyle(fontSize: 13, height: 1.35),
										),
									),
									const SizedBox(height: 14),
									TextField(
										controller: nombreCtrl,
										decoration: const InputDecoration(
											labelText: 'Nombre de la máquina',
											hintText: 'Ej: SILO-104',
											border: OutlineInputBorder(),
										),
									),
									const SizedBox(height: 10),
									TextField(
										controller: codigoCtrl,
										decoration: const InputDecoration(
											labelText: 'Código interno',
											helperText: 'Debe ser único en la planta',
											border: OutlineInputBorder(),
										),
									),
									const SizedBox(height: 10),
									DropdownButtonFormField<String>(
										value: tipoId,
										items: tipos
												.map(
													(t) => DropdownMenuItem(
														value: t['id'] as String,
														child: Text(t['nombre'] as String),
													),
												)
												.toList(),
										onChanged: (v) {
											if (v != null) setDialog(() => tipoId = v);
										},
										decoration: const InputDecoration(
											labelText: 'Tipo de máquina',
											border: OutlineInputBorder(),
										),
									),
									if (camposActuales.isNotEmpty) ...[
										const SizedBox(height: 14),
										const Text(
											'Datos adicionales del tipo',
											style: TextStyle(fontWeight: FontWeight.w600),
										),
										const SizedBox(height: 8),
										...buildCamposDetalleFields(
											campos: camposActuales,
											controllers: campoCtrls,
										),
									],
								],
							),
						),
					),
					actions: [
						TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
						FilledButton(
							onPressed: () {
								if (nombreCtrl.text.trim().length < 2 || codigoCtrl.text.trim().isEmpty) {
									return;
								}
								Navigator.pop(ctx, true);
							},
							child: const Text('Crear'),
						),
					],
				);
			},
		),
	);

	if (ok != true) return false;

	final nombre = nombreCtrl.text.trim().toUpperCase();
	final codigo = codigoCtrl.text.trim().toUpperCase();
	final tipoFinal = tipos.firstWhere((t) => t['id'] == tipoId);
	final camposFinal = parseCamposDetalle(tipoFinal);
	final detallePayload =
			camposFinal.isNotEmpty ? collectDetalle(camposFinal, campoCtrls) : null;

	for (final ctrl in campoCtrls.values) {
		ctrl.dispose();
	}
	nombreCtrl.dispose();
	codigoCtrl.dispose();

	try {
		await api.postJson('equipos', {
			'sucursalId': sucursalId,
			'ubicacionId': ubicacionId,
			'tipoEquipoId': tipoId,
			'nombre': nombre,
			'codigo': codigo,
			if (detallePayload != null) 'detalle': detallePayload,
		});
		return true;
	} catch (error) {
		if (context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
		return false;
	}
}
