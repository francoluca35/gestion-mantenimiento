import 'package:intl/intl.dart';

import '../../../core/utils/download_csv.dart';

class ProcedimientosExport {
	const ProcedimientosExport._();

	static String _csvCell(dynamic value) {
		final text = value?.toString() ?? '';
		if (text.contains(',') || text.contains('"') || text.contains('\n')) {
			return '"${text.replaceAll('"', '""')}"';
		}
		return text;
	}

	static String _tipoLabel(String tipo) {
		return switch (tipo) {
			'preventivo' => 'Preventivo',
			'preventivo_no_periodico' => 'Preventivo no periódico',
			'correctivo' => 'Correctivo',
			'mejora' => 'Mejora',
			'predictivo' => 'Predictivo',
			_ => tipo,
		};
	}

	static String _periodicidadLabel(Map<String, dynamic> proc) {
		final tipo = proc['periodicidadTipo'] as String?;
		final valor = proc['periodicidadValor'];
		if (tipo == null || valor == null) return '';
		return tipo == 'contador' ? 'Cada $valor (contador)' : 'Cada $valor días';
	}

	static String buildCsv(List<Map<String, dynamic>> procedimientos) {
		const headers = [
			'Código',
			'Nombre',
			'Tipo',
			'Periodicidad',
			'Sector responsable',
			'Equipos asociados',
			'OT generadas',
			'Tolerancia',
			'Hs hombre',
		];

		final rows = procedimientos.map((proc) {
			final sector = proc['sectorResponsable'] as Map<String, dynamic>?;
			final count = proc['_count'] as Map<String, dynamic>?;

			return [
				proc['codigo'],
				proc['nombre'],
				_tipoLabel(proc['tipo'] as String? ?? ''),
				_periodicidadLabel(proc),
				sector?['nombre'],
				count?['equipos'] ?? 0,
				count?['ordenes'] ?? 0,
				proc['tolerancia'],
				proc['hsHombre'],
			].map(_csvCell).join(',');
		});

		return '${headers.map(_csvCell).join(',')}\n${rows.join('\n')}';
	}

	static void download(List<Map<String, dynamic>> procedimientos, {String? suffix}) {
		final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
		final name = suffix != null
				? 'procedimientos_${suffix}_$stamp.csv'
				: 'procedimientos_$stamp.csv';
		downloadTextFile(name, buildCsv(procedimientos), 'text/csv;charset=utf-8');
	}
}
