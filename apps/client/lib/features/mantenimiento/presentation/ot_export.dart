import 'package:intl/intl.dart';

import '../../../core/utils/download_csv.dart';
import 'ot_ui.dart';

class OtExport {
	const OtExport._();

	static String _csvCell(dynamic value) {
		final text = value?.toString() ?? '';
		if (text.contains(',') || text.contains('"') || text.contains('\n')) {
			return '"${text.replaceAll('"', '""')}"';
		}
		return text;
	}

	static String buildCsv(List<Map<String, dynamic>> ordenes) {
		const headers = [
			'Número',
			'Estado',
			'Tipo',
			'Prioridad',
			'Equipo',
			'Ubicación',
			'Procedimiento',
			'Técnico',
			'Motivo pendiente',
			'Fecha programación',
			'Fecha ejecución',
		];

		final rows = ordenes.map((ot) {
			final equipo = ot['equipo'] as Map<String, dynamic>?;
			final ubicacion =
					ot['ubicacion'] as Map<String, dynamic>? ?? equipo?['ubicacion'];
			final procedimiento = ot['procedimiento'] as Map<String, dynamic>?;
			final tecnico = ot['tecnicoAsignado'] as Map<String, dynamic>?;
			final motivo = ot['motivoPendiente'] as Map<String, dynamic>?;

			return [
				ot['numero'],
				OtUi.estadoLabel(ot['estado'] as String? ?? ''),
				ot['tipo'],
				OtUi.prioridadLabel(ot['prioridad'] as String? ?? 'media'),
				equipo != null ? '${equipo['codigo']} — ${equipo['nombre']}' : '',
				ubicacion?['nombre'],
				procedimiento?['nombre'],
				tecnico?['nombreUsuario'],
				motivo?['descripcion'],
				_formatDate(ot['fechaProgramacion']),
				_formatDate(ot['fechaEjecucion']),
			].map(_csvCell).join(',');
		});

		return '${headers.map(_csvCell).join(',')}\n${rows.join('\n')}';
	}

	static void download(List<Map<String, dynamic>> ordenes, {String? suffix}) {
		final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
		final name = suffix != null ? 'ot_${suffix}_$stamp.csv' : 'ot_$stamp.csv';
		downloadTextFile(name, buildCsv(ordenes), 'text/csv;charset=utf-8');
	}

	static String _formatDate(dynamic value) {
		if (value == null) return '';
		final parsed = DateTime.tryParse(value.toString());
		if (parsed == null) return value.toString();
		return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
	}
}
