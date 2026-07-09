import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum OtEmitirAccion {
	enviar,
	enviarYGenerarPdf,
	soloGenerarPdf,
}

/// Diálogo al emitir OT con técnico/recibe asignado.
Future<OtEmitirAccion?> showOtEmitirAccionDialog(
	BuildContext context, {
	required bool tieneRecibe,
	String? recibeNombre,
}) {
	return showDialog<OtEmitirAccion>(
		context: context,
		builder: (ctx) => AlertDialog(
			title: const Text('Enviar OT'),
			content: Column(
				mainAxisSize: MainAxisSize.min,
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					if (tieneRecibe && recibeNombre != null) ...[
						Text(
							'Recibe: $recibeNombre',
							style: const TextStyle(fontWeight: FontWeight.w600),
						),
						const SizedBox(height: 12),
					],
					Text(
						tieneRecibe
								? 'Elegí si notificar al técnico en la app y si generar el PDF ahora.'
								: 'Elegí si solo emitir la OT o generar el PDF al crearla.',
						style: TextStyle(
							color: Theme.of(ctx).colorScheme.onSurfaceVariant,
							fontSize: 13,
						),
					),
					const SizedBox(height: 16),
					if (tieneRecibe)
						OutlinedButton.icon(
							onPressed: () => Navigator.pop(ctx, OtEmitirAccion.enviar),
							icon: const Icon(Icons.send_rounded, size: 18),
							label: const Text('Enviar OT'),
						),
					if (tieneRecibe) const SizedBox(height: 8),
					if (tieneRecibe)
						FilledButton.icon(
							style: FilledButton.styleFrom(backgroundColor: AppColors.brandYellow),
							onPressed: () => Navigator.pop(ctx, OtEmitirAccion.enviarYGenerarPdf),
							icon: const Icon(Icons.send_and_archive_rounded, size: 18, color: AppColors.ink),
							label: const Text(
								'Enviar y descargar PDF',
								style: TextStyle(color: AppColors.ink),
							),
						),
					if (tieneRecibe) const SizedBox(height: 8),
					OutlinedButton.icon(
						onPressed: () => Navigator.pop(ctx, OtEmitirAccion.soloGenerarPdf),
						icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
						label: Text(tieneRecibe ? 'Descargar PDF' : 'Emitir y descargar PDF'),
					),
					const SizedBox(height: 8),
					TextButton(
						onPressed: () => Navigator.pop(ctx),
						child: const Text('Cancelar'),
					),
				],
			),
		),
	);
}

bool notificarSegunAccion(OtEmitirAccion accion) {
	return accion == OtEmitirAccion.enviar || accion == OtEmitirAccion.enviarYGenerarPdf;
}

bool generarPdfSegunAccion(OtEmitirAccion accion) {
	return accion == OtEmitirAccion.enviarYGenerarPdf ||
			accion == OtEmitirAccion.soloGenerarPdf;
}
