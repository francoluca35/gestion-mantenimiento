import 'package:intl/intl.dart';

import '../../../core/utils/open_print_html.dart';

/// Reporte imprimible de equipos — paridad SGwing-12.
class PlantaPrint {
	const PlantaPrint._();

	static String _escape(String value) {
		return value
				.replaceAll('&', '&amp;')
				.replaceAll('<', '&lt;')
				.replaceAll('>', '&gt;')
				.replaceAll('"', '&quot;');
	}

	static String buildEquiposHtml({
		required String empresaNombre,
		required String plantaNombre,
		required List<Map<String, dynamic>> equipos,
		String? sectorFiltro,
	}) {
		final stamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
		final rows = equipos.map((e) {
			final tipo = e['tipoEquipo'] as Map<String, dynamic>?;
			final ubicacion = e['ubicacion'] as Map<String, dynamic>?;
			final activo = e['activo'] as bool? ?? true;
			final fuera = e['fueraDeServicio'] as bool? ?? false;
			final estado = !activo
					? 'Inactivo'
					: fuera
					? 'Fuera de servicio'
					: 'Operativo';

			return '''
<tr>
	<td>${_escape('${e['codigo'] ?? ''}')}</td>
	<td>${_escape('${e['nombre'] ?? ''}')}</td>
	<td>${_escape('${tipo?['nombre'] ?? ''}')}</td>
	<td>${_escape('${ubicacion?['nombre'] ?? ''}')}</td>
	<td>$estado</td>
</tr>''';
		}).join('\n');

		final filtro = sectorFiltro != null && sectorFiltro.isNotEmpty
				? '<p class="meta">Filtro: ${_escape(sectorFiltro)}</p>'
				: '';

		return '''
<!DOCTYPE html>
<html lang="es">
<head>
	<meta charset="utf-8" />
	<title>Listado de máquinas — ${_escape(plantaNombre)}</title>
	<style>
		@page { margin: 14mm; }
		* { box-sizing: border-box; }
		body {
			font-family: "Segoe UI", Arial, sans-serif;
			color: #1a1a1a;
			margin: 0;
			padding: 24px;
			font-size: 12px;
		}
		.header {
			display: flex;
			justify-content: space-between;
			align-items: flex-start;
			border-bottom: 3px solid #FFB11B;
			padding-bottom: 12px;
			margin-bottom: 16px;
		}
		.brand { font-size: 20px; font-weight: 800; color: #E30613; letter-spacing: 0.02em; }
		.title { font-size: 16px; font-weight: 700; margin: 4px 0 0; }
		.meta { color: #555; margin: 2px 0; font-size: 11px; }
		table { width: 100%; border-collapse: collapse; margin-top: 8px; }
		th {
			background: #FFF4D6;
			color: #5c4a00;
			text-align: left;
			padding: 8px 10px;
			border: 1px solid #e8d9a8;
			font-size: 11px;
		}
		td {
			padding: 7px 10px;
			border: 1px solid #e5e5e5;
			vertical-align: top;
		}
		tr:nth-child(even) td { background: #fafafa; }
		.footer {
			margin-top: 18px;
			padding-top: 10px;
			border-top: 1px solid #ddd;
			color: #666;
			font-size: 10px;
		}
		@media print {
			body { padding: 0; }
			.no-print { display: none; }
		}
	</style>
</head>
<body>
	<div class="header">
		<div>
			<div class="brand">${_escape(empresaNombre)}</div>
			<div class="title">Listado de máquinas — ${_escape(plantaNombre)}</div>
			<p class="meta">Generado: $stamp · ${equipos.length} registro(s)</p>
			$filtro
		</div>
		<div class="no-print">
			<button onclick="window.print()" style="padding:8px 14px;background:#FFB11B;border:none;border-radius:6px;font-weight:600;cursor:pointer;">
				Imprimir
			</button>
		</div>
	</div>
	<table>
		<thead>
			<tr>
				<th>Código</th>
				<th>Nombre</th>
				<th>Tipo</th>
				<th>Ubicación</th>
				<th>Estado</th>
			</tr>
		</thead>
		<tbody>
			$rows
		</tbody>
	</table>
	<div class="footer">
		Gestión de Mantenimiento — reporte de equipos. Revise los datos antes de archivar.
	</div>
</body>
</html>''';
	}

	static void previewEquipos({
		required String empresaNombre,
		required String plantaNombre,
		required List<Map<String, dynamic>> equipos,
		String? sectorFiltro,
	}) {
		openHtmlForPrint(
			buildEquiposHtml(
				empresaNombre: empresaNombre,
				plantaNombre: plantaNombre,
				equipos: equipos,
				sectorFiltro: sectorFiltro,
			),
		);
	}
}
