import 'package:intl/intl.dart';

import '../../../core/utils/download_csv.dart';

class PlantaExport {
	const PlantaExport._();

	static String _csvCell(dynamic value) {
		final text = value?.toString() ?? '';
		if (text.contains(',') || text.contains('"') || text.contains('\n')) {
			return '"${text.replaceAll('"', '""')}"';
		}
		return text;
	}

	static String buildEquiposCsv(List<Map<String, dynamic>> equipos) {
		const headers = [
			'Código',
			'Nombre',
			'Tipo',
			'Ubicación',
			'Estado',
			'Fuera de servicio',
		];

		final rows = equipos.map((e) {
			final tipo = e['tipoEquipo'] as Map<String, dynamic>?;
			final ubicacion = e['ubicacion'] as Map<String, dynamic>?;
			final activo = e['activo'] as bool? ?? true;
			final fuera = e['fueraDeServicio'] as bool? ?? false;

			return [
				e['codigo'],
				e['nombre'],
				tipo?['nombre'],
				ubicacion?['nombre'],
				activo ? 'Activo' : 'Inactivo',
				fuera ? 'Sí' : 'No',
			].map(_csvCell).join(',');
		});

		return '${headers.map(_csvCell).join(',')}\n${rows.join('\n')}';
	}

	static void downloadEquipos(List<Map<String, dynamic>> equipos) {
		final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
		downloadTextFile(
			'equipos_planta_$stamp.csv',
			buildEquiposCsv(equipos),
			'text/csv;charset=utf-8',
		);
	}
}
