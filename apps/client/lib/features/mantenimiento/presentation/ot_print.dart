import 'package:intl/intl.dart';

import '../../../core/utils/open_print_html.dart';
import 'ot_ui.dart';

/// Reporte imprimible de OT — paridad SGwing listar / vista previa.
class OtPrint {
	const OtPrint._();

	static String _escape(String value) {
		return value
				.replaceAll('&', '&amp;')
				.replaceAll('<', '&lt;')
				.replaceAll('>', '&gt;')
				.replaceAll('"', '&quot;');
	}

	static String _formatDate(dynamic value) {
		if (value == null) return '';
		final parsed = DateTime.tryParse(value.toString());
		if (parsed == null) return value.toString();
		return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
	}

	static String buildListHtml({
		required String titulo,
		required String periodo,
		required List<Map<String, dynamic>> ordenes,
		String? filtroExtra,
	}) {
		final stamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
		final rows = ordenes.map((ot) {
			final equipo = ot['equipo'] as Map<String, dynamic>?;
			final ubicacion =
					ot['ubicacion'] as Map<String, dynamic>? ?? equipo?['ubicacion'];
			final procedimiento = ot['procedimiento'] as Map<String, dynamic>?;
			final tecnico = ot['tecnicoAsignado'] as Map<String, dynamic>?;
			final motivo = ot['motivoPendiente'] as Map<String, dynamic>?;
			final gut = OtUi.formatDuracionMinutos(procedimiento?['duracionEstimada']);

			return '''
<tr>
	<td>${ot['numero']}</td>
	<td>${_escape(OtUi.estadoLabel(ot['estado'] as String? ?? ''))}</td>
	<td>${_escape('${ot['tipo'] ?? ''}')}</td>
	<td>${_escape(equipo != null ? '${equipo['codigo']} — ${equipo['nombre']}' : '')}</td>
	<td>${_escape('${ubicacion?['nombre'] ?? ''}')}</td>
	<td>${_escape('${tecnico?['nombreUsuario'] ?? ''}')}</td>
	<td>${_escape('${motivo?['descripcion'] ?? ''}')}</td>
	<td>$gut</td>
	<td>${_formatDate(ot['fechaProgramacion'])}</td>
	<td>${_formatDate(ot['fechaEjecucion'])}</td>
</tr>''';
		}).join('\n');

		final filtro = filtroExtra != null && filtroExtra.isNotEmpty
				? '<p class="meta">Filtro: ${_escape(filtroExtra)}</p>'
				: '';

		return '''
<!DOCTYPE html>
<html lang="es">
<head>
	<meta charset="utf-8" />
	<title>$titulo</title>
	<style>
		@page { margin: 12mm; }
		* { box-sizing: border-box; }
		body {
			font-family: "Segoe UI", Arial, sans-serif;
			color: #1a1a1a;
			margin: 0;
			padding: 20px;
			font-size: 11px;
		}
		.header {
			display: flex;
			justify-content: space-between;
			align-items: flex-start;
			border-bottom: 3px solid #C026FF;
			padding-bottom: 10px;
			margin-bottom: 14px;
		}
		.brand { font-size: 18px; font-weight: 800; color: #FF3B1F; }
		.title { font-size: 15px; font-weight: 700; margin: 4px 0 0; }
		.meta { color: #555; margin: 2px 0; font-size: 10px; }
		table { width: 100%; border-collapse: collapse; }
		th {
			background: #FFF4D6;
			text-align: left;
			padding: 6px 8px;
			border: 1px solid #e8d9a8;
			font-size: 10px;
		}
		td {
			padding: 5px 8px;
			border: 1px solid #e5e5e5;
			vertical-align: top;
		}
		tr:nth-child(even) td { background: #fafafa; }
		.footer {
			margin-top: 14px;
			padding-top: 8px;
			border-top: 1px solid #ddd;
			color: #666;
			font-size: 9px;
		}
		@media print { .no-print { display: none; } }
	</style>
</head>
<body>
	<div class="header">
		<div>
			<div class="brand">SIKA</div>
			<div class="title">${_escape(titulo)}</div>
			<p class="meta">Período: ${_escape(periodo)} · Generado: $stamp · ${ordenes.length} OT</p>
			$filtro
		</div>
		<div class="no-print">
			<button onclick="window.print()" style="padding:8px 14px;background:#C026FF;color:#fff;border:none;border-radius:6px;font-weight:600;cursor:pointer;">
				Imprimir
			</button>
		</div>
	</div>
	<table>
		<thead>
			<tr>
				<th>Nº</th>
				<th>Estado</th>
				<th>Tipo</th>
				<th>Equipo</th>
				<th>Ubicación</th>
				<th>Recibe</th>
				<th>Motivo pend.</th>
				<th>GUT est.</th>
				<th>Programación</th>
				<th>Ejecución</th>
			</tr>
		</thead>
		<tbody>
			$rows
		</tbody>
	</table>
	<div class="footer">Gestión de Mantenimiento — listado de órdenes de trabajo.</div>
</body>
</html>''';
	}

	static void previewList({
		required String titulo,
		required String periodo,
		required List<Map<String, dynamic>> ordenes,
		String? filtroExtra,
	}) {
		openHtmlForPrint(
			buildListHtml(
				titulo: titulo,
				periodo: periodo,
				ordenes: ordenes,
				filtroExtra: filtroExtra,
			),
		);
	}
}
