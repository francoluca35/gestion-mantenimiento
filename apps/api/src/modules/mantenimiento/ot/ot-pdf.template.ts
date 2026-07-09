export interface OtPdfUbicacionNodo {
	nombre: string;
}

export interface OtPdfPlanillaItem {
	label?: string;
	key?: string;
	done?: boolean;
}

export interface OtPdfLectura {
	fecha: Date;
	tipo: string;
	valor: { toString(): string };
	notas?: string | null;
}

export interface OtPdfHistorialItem {
	estado: string;
	createdAt: Date;
	usuario?: { nombreUsuario?: string } | null;
}

export interface OtPdfData {
	numero: number;
	sucursalNombre: string;
	fechaProgramacion: Date | null;
	fechaEjecucion: Date | null;
	tipo: string;
	estado: string;
	tolerancia: number;
	prioridad: string;
	comentarios?: string | null;
	novedadesFueraDePrograma?: string | null;
	firmaDigital?: string | null;
	equipo: {
		nombre: string;
		codigo: string;
		tipoEquipo?: { nombre?: string } | null;
	};
	procedimiento?: {
		codigo: number;
		versionActual: number;
		nombre: string;
		tipo: string;
		descripcion?: string | null;
		observaciones?: string | null;
		periodicidadTipo?: string | null;
		periodicidadValor?: number | null;
		planillaLecturas?: unknown;
		sectorResponsable?: { nombre?: string } | null;
	} | null;
	tecnicoAsignado?: { nombreUsuario?: string } | null;
	creador?: { nombreUsuario?: string } | null;
	ubicacionPath: string[];
	checklistCompletado?: unknown;
	lecturas?: OtPdfLectura[];
	historialEstados?: OtPdfHistorialItem[];
}

function escapeHtml(value: string): string {
	return value
		.replace(/&/g, '&amp;')
		.replace(/</g, '&lt;')
		.replace(/>/g, '&gt;')
		.replace(/"/g, '&quot;');
}

function formatDateAR(value: Date | null | undefined): string {
	if (!value) return '';
	const date = new Date(value);
	if (Number.isNaN(date.getTime())) return '';
	const day = String(date.getDate()).padStart(2, '0');
	const month = String(date.getMonth() + 1).padStart(2, '0');
	const year = date.getFullYear();
	return `${day}/${month}/${year}`;
}

function formatDateTimeAR(value: Date | null | undefined): string {
	if (!value) return '';
	const date = new Date(value);
	if (Number.isNaN(date.getTime())) return '';
	return `${formatDateAR(date)} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
}

function tipoLabel(tipo: string): string {
	return tipo.replace(/_/g, ' ').toUpperCase();
}

function prioridadLabel(prioridad: string): string {
	return prioridad.toUpperCase();
}

function barcodeOt(numero: number): string {
	return `*02${String(numero).padStart(6, '0')}*`;
}

function parsePlanilla(value: unknown): OtPdfPlanillaItem[] {
	if (!Array.isArray(value)) return [];
	return value as OtPdfPlanillaItem[];
}

function firmaToImgSrc(firma: string | null | undefined): string | null {
	if (!firma?.trim()) return null;
	if (firma.startsWith('data:image')) return firma;
	if (firma.startsWith('iVBOR')) return `data:image/png;base64,${firma}`;
	return null;
}

function buildDescripcionLineas(data: OtPdfData): string[] {
	const lines: string[] = [];
	const proc = data.procedimiento;

	if (proc) {
		const periodicidad =
			proc.periodicidadTipo === 'tiempo' && proc.periodicidadValor
				? ` (${proc.periodicidadValor} dias)`
				: '';
		lines.push(
			`${tipoLabel(proc.tipo)} ${proc.nombre}${periodicidad}`,
		);

		if (proc.descripcion?.trim()) {
			lines.push(proc.descripcion.trim());
		}

		if (proc.observaciones?.trim()) {
			for (const raw of proc.observaciones.split('\n')) {
				const line = raw.trim();
				if (!line) continue;
				lines.push(line.startsWith('-') ? line : `- ${line}`);
			}
		}

		for (const item of parsePlanilla(proc.planillaLecturas)) {
			if (item.label?.trim()) {
				lines.push(`-${item.label.trim()}`);
			}
		}
	} else if (data.comentarios?.trim()) {
		lines.push(data.comentarios.trim());
	}

	const checklist = parsePlanilla(data.checklistCompletado);
	for (const item of checklist) {
		if (item.label?.trim()) {
			const marca = item.done === true ? '[X]' : '[ ]';
			lines.push(`${marca} ${item.label.trim()}`);
		}
	}

	return lines;
}

function findHistorialFecha(
	historial: OtPdfHistorialItem[] | undefined,
	estado: string,
): Date | null {
	const item = historial?.find((h) => h.estado === estado);
	return item?.createdAt ?? null;
}

function blankRows(count: number, cols: number): string {
	return Array.from({ length: count })
		.map(
			() =>
				`<tr>${Array.from({ length: cols })
					.map(() => '<td>&nbsp;</td>')
					.join('')}</tr>`,
		)
		.join('');
}

export function renderOtPdfHtml(data: OtPdfData): string {
	const planta = data.sucursalNombre.toUpperCase();
	const procedimientoLabel = data.procedimiento
		? `${data.procedimiento.codigo} v${data.procedimiento.versionActual}`
		: '';
	const responsable =
		data.procedimiento?.sectorResponsable?.nombre?.toUpperCase() ??
		data.creador?.nombreUsuario?.toUpperCase() ??
		'';
	const tipoEquipo = data.equipo.tipoEquipo?.nombre?.toUpperCase() ?? 'EQUIPO';
	const solicitado = formatDateAR(data.fechaProgramacion);
	const recibe = data.tecnicoAsignado?.nombreUsuario?.toUpperCase() ?? '';
	const descripcionLineas = buildDescripcionLineas(data);
	const novedades = data.novedadesFueraDePrograma?.trim() ?? '';
	const inicio = findHistorialFecha(data.historialEstados, 'en_ejecucion');
	const fin =
		findHistorialFecha(data.historialEstados, 'realizada') ??
		(data.estado === 'realizada' ? data.fechaEjecucion : null);

	const ubicacionBloque = [
		'SIKA S.A.I.C.',
		...data.ubicacionPath.map((n) => escapeHtml(n.toUpperCase())),
		escapeHtml(data.equipo.nombre.toUpperCase()),
	]
		.map((line) => `<div class="ubic-line">${line}</div>`)
		.join('');

	const lecturasTexto =
		data.lecturas && data.lecturas.length > 0
			? data.lecturas
					.map(
						(l) =>
							`${formatDateAR(l.fecha)} — ${escapeHtml(l.tipo)}: ${escapeHtml(l.valor.toString())}${l.notas ? ` (${escapeHtml(l.notas)})` : ''}`,
					)
					.join('<br/>')
			: '&nbsp;';

	const firmaSrc = firmaToImgSrc(data.firmaDigital);
	const firmaHtml = firmaSrc
		? `<img src="${firmaSrc}" alt="Firma" class="firma-img"/>`
		: data.estado === 'realizada'
				? '<span style="font-size:9pt;color:#666;">Sin firma registrada</span>'
				: '&nbsp;';

	return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8"/>
<title>OT ${data.numero}</title>
<style>
@page { size: A4; margin: 12mm 14mm; }
* { box-sizing: border-box; }
body {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 10pt;
	color: #000;
	margin: 0;
	padding: 0;
	line-height: 1.25;
}
.sheet { width: 100%; max-width: 190mm; margin: 0 auto; }
.top-bar {
	display: flex;
	justify-content: space-between;
	align-items: flex-start;
	border-bottom: 2px solid #000;
	padding-bottom: 4px;
	margin-bottom: 6px;
}
.empresa { font-weight: 700; font-size: 11pt; }
.barcode {
	font-family: 'Courier New', Courier, monospace;
	font-size: 13pt;
	font-weight: 700;
	letter-spacing: 1px;
	text-align: right;
}
.title {
	text-align: center;
	font-weight: 700;
	font-size: 13pt;
	margin: 8px 0 10px;
	letter-spacing: 0.3px;
}
table { width: 100%; border-collapse: collapse; }
td, th {
	border: 1px solid #000;
	padding: 3px 5px;
	vertical-align: top;
}
.meta td { height: 22px; }
.meta .label {
	font-size: 8.5pt;
	color: #111;
	white-space: nowrap;
}
.meta .value { font-size: 10pt; font-weight: 600; }
.section-title {
	font-weight: 700;
	font-size: 9.5pt;
	margin: 10px 0 4px;
}
.ubic-box {
	border: 1px solid #000;
	padding: 6px 8px;
	min-height: 72px;
}
.ubic-line { font-weight: 600; font-size: 10pt; line-height: 1.35; }
.desc-box {
	border: 1px solid #000;
	padding: 6px 8px;
	min-height: 110px;
	white-space: pre-wrap;
	font-size: 10pt;
}
.novedades-box {
	border: 1px solid #000;
	padding: 6px 8px;
	min-height: 48px;
	white-space: pre-wrap;
}
.sub-table th {
	font-size: 8.5pt;
	font-weight: 700;
	text-align: center;
	background: #fff;
}
.sub-table td { height: 20px; font-size: 9pt; }
.footer-row {
	display: flex;
	justify-content: space-between;
	margin-top: 10px;
	font-size: 9pt;
}
.firma-box {
	border: 1px solid #000;
	min-height: 56px;
	padding: 4px;
	margin-top: 4px;
}
.firma-img { max-height: 48px; max-width: 180px; }
.bottom-pair { display: flex; gap: 8px; margin-top: 8px; }
.bottom-pair > div { flex: 1; }
.label-inline { font-size: 9pt; font-weight: 700; }
@media print {
	body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
}
</style>
</head>
<body>
<div class="sheet">
	<div class="top-bar">
		<div class="empresa">SIKA S.A. — ${escapeHtml(planta)}</div>
		<div class="barcode">${barcodeOt(data.numero)}</div>
	</div>

	<div class="title">ORDEN DE TRABAJO Nº${data.numero}</div>

	<table class="meta">
		<tr>
			<td class="label" width="14%">Fecha Programación:</td>
			<td class="label" width="14%">Procedimiento Nº:</td>
			<td class="label" width="18%">Responsable:</td>
			<td class="label" width="12%">Tipo:</td>
			<td class="label" width="12%">Solicitado:</td>
			<td class="label" width="12%">Recibe:</td>
			<td class="label" width="9%">Tolerancia:</td>
			<td class="label" width="9%">Prioridad:</td>
		</tr>
		<tr>
			<td class="value">${escapeHtml(solicitado)}</td>
			<td class="value">${escapeHtml(procedimientoLabel)}</td>
			<td class="value">${escapeHtml(responsable)}</td>
			<td class="value">${escapeHtml(tipoLabel(data.tipo))}</td>
			<td class="value">${escapeHtml(solicitado)}</td>
			<td class="value">${escapeHtml(recibe)}</td>
			<td class="value">${data.tolerancia}</td>
			<td class="value">${escapeHtml(prioridadLabel(data.prioridad))}</td>
		</tr>
		<tr>
			<td class="label" colspan="7">Ubicación:</td>
			<td class="value">${escapeHtml(tipoEquipo)}</td>
		</tr>
	</table>

	<div style="display:flex; gap:8px; margin-top:8px;">
		<div style="flex:0 0 34%;">
			<div class="section-title">Ubicación</div>
			<div class="ubic-box">${ubicacionBloque}</div>
		</div>
		<div style="flex:1;">
			<div class="section-title">Descripción del Trabajo:</div>
			<div class="desc-box">${escapeHtml(descripcionLineas.join('\n'))}</div>
		</div>
	</div>

	<div class="section-title">Novedades y tareas fuera de programa:</div>
	<div class="novedades-box">${escapeHtml(novedades)}</div>

	<div class="section-title">Materiales Utilizados:</div>
	<table class="sub-table">
		<tr>
			<th width="12%">Fecha</th>
			<th width="12%">Código</th>
			<th width="10%">Cantidad</th>
			<th width="36%">Denominación</th>
			<th width="12%">Unidad</th>
			<th width="18%">Costo</th>
		</tr>
		${blankRows(3, 6)}
	</table>

	<div class="section-title">Mano de Obra Utilizada:</div>
	<table class="sub-table">
		<tr>
			<th width="12%">Fecha</th>
			<th width="28%">Apellido y Nombre</th>
			<th width="15%">Cant. Hr. Normal</th>
			<th width="15%">Cant. Hr.Extra</th>
			<th width="15%">Cant.Hr.Ex.100%</th>
			<th width="15%">Cant.Hr.Ex.200%</th>
		</tr>
		${blankRows(2, 6)}
	</table>

	<div class="bottom-pair">
		<div>
			<div class="label-inline">Inicio:</div>
			<div class="firma-box">${escapeHtml(formatDateTimeAR(inicio))}</div>
		</div>
		<div>
			<div class="label-inline">Finalización:</div>
			<div class="firma-box">${escapeHtml(formatDateTimeAR(fin))}</div>
		</div>
	</div>

	<div class="bottom-pair">
		<div>
			<div class="label-inline">Estado Contador:</div>
			<div class="firma-box">${lecturasTexto}</div>
		</div>
		<div>
			<div class="label-inline">Firma Responsable:</div>
			<div class="firma-box">${firmaHtml}</div>
		</div>
	</div>

	<div class="footer-row">
		<span>Página 1 de 1</span>
		<span>Original</span>
	</div>
</div>

</body>
</html>`;
}
