export type ParsedMaterialLine = {
	raw: string;
	descripcion: string;
	cantidad: number;
};

export type StockCandidate = {
	materialId: string;
	codigo: string;
	nombre: string;
	disponible: number;
	panolId: string;
	panolNombre: string;
	unidad?: string | null;
};

export type MatchResultLine = {
	raw: string;
	descripcion: string;
	cantidadPedida: number;
	match: null | {
		materialId: string;
		codigo: string;
		nombre: string;
		disponible: number;
		panolId: string;
		panolNombre: string;
		unidad?: string | null;
		score: number;
	};
	estado: 'ok' | 'faltante_parcial' | 'sin_stock' | 'sin_match';
	cantidadDisponible: number;
	cantidadFaltante: number;
};

function normalize(text: string): string {
	return text
		.toLowerCase()
		.normalize('NFD')
		.replace(/[\u0300-\u036f]/g, '')
		.replace(/[^a-z0-9\s]/g, ' ')
		.replace(/\s+/g, ' ')
		.trim();
}

function tokenSet(text: string): Set<string> {
	return new Set(normalize(text).split(' ').filter((t) => t.length > 1));
}

function jaccard(a: Set<string>, b: Set<string>): number {
	if (a.size === 0 || b.size === 0) return 0;
	let inter = 0;
	for (const t of a) if (b.has(t)) inter += 1;
	const union = a.size + b.size - inter;
	return union === 0 ? 0 : inter / union;
}

/** Extrae líneas y cantidades de texto libre. */
export function parseMaterialesTexto(texto: string): ParsedMaterialLine[] {
	const chunks = texto
		.split(/[\n;,]+/)
		.map((s) => s.trim())
		.filter(Boolean);

	const lines: ParsedMaterialLine[] = [];
	for (const raw of chunks) {
		let cantidad = 1;
		let descripcion = raw;

		const patterns = [
			/^(\d+[.,]?\d*)\s*[x×]\s*(.+)$/i,
			/^(\d+[.,]?\d*)\s+(.+)$/i,
			/^(.+?)\s*[x×]\s*(\d+[.,]?\d*)$/i,
			/^(.+?)\s*[:(]\s*(\d+[.,]?\d*)\s*(?:uds?|unidades?)?\)?$/i,
		];

		for (const re of patterns) {
			const m = raw.match(re);
			if (!m) continue;
			if (re.source.startsWith('^(.+?)')) {
				descripcion = m[1].trim();
				cantidad = Number(String(m[2]).replace(',', '.'));
			} else {
				cantidad = Number(String(m[1]).replace(',', '.'));
				descripcion = m[2].trim();
			}
			break;
		}

		if (!Number.isFinite(cantidad) || cantidad <= 0) cantidad = 1;
		if (!descripcion) continue;
		lines.push({ raw, descripcion, cantidad });
	}
	return lines;
}

function scoreCandidate(query: string, candidate: StockCandidate): number {
	const q = normalize(query);
	const codigo = normalize(candidate.codigo);
	const nombre = normalize(candidate.nombre);
	if (!q) return 0;
	if (codigo === q || nombre === q) return 1;
	if (codigo.includes(q) || q.includes(codigo)) return 0.92;
	if (nombre.includes(q) || q.includes(nombre)) return 0.88;
	const qt = tokenSet(q);
	const nt = tokenSet(`${candidate.codigo} ${candidate.nombre}`);
	return jaccard(qt, nt);
}

export function matchMaterialesContraStock(
	texto: string,
	catalogo: StockCandidate[],
	minScore = 0.35,
): MatchResultLine[] {
	const lines = parseMaterialesTexto(texto);
	return lines.map((line) => {
		let best: { candidate: StockCandidate; score: number } | null = null;
		for (const c of catalogo) {
			const score = scoreCandidate(line.descripcion, c);
			if (score < minScore) continue;
			if (!best || score > best.score) best = { candidate: c, score };
		}

		if (!best) {
			return {
				raw: line.raw,
				descripcion: line.descripcion,
				cantidadPedida: line.cantidad,
				match: null,
				estado: 'sin_match' as const,
				cantidadDisponible: 0,
				cantidadFaltante: line.cantidad,
			};
		}

		const disponible = Math.max(0, Number(best.candidate.disponible) || 0);
		const faltante = Math.max(0, line.cantidad - disponible);
		let estado: MatchResultLine['estado'] = 'ok';
		if (disponible <= 0) estado = 'sin_stock';
		else if (faltante > 0) estado = 'faltante_parcial';

		return {
			raw: line.raw,
			descripcion: line.descripcion,
			cantidadPedida: line.cantidad,
			match: {
				materialId: best.candidate.materialId,
				codigo: best.candidate.codigo,
				nombre: best.candidate.nombre,
				disponible,
				panolId: best.candidate.panolId,
				panolNombre: best.candidate.panolNombre,
				unidad: best.candidate.unidad,
				score: Number(best.score.toFixed(3)),
			},
			estado,
			cantidadDisponible: Math.min(disponible, line.cantidad),
			cantidadFaltante: faltante,
		};
	});
}
