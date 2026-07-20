/**
 * Smoke M4 Pañol — ciclo solicitud → aprobar → cerrar OT → stock.
 * Uso: node scripts/smoke-m4-panol.mjs
 * Requiere API en :3000 y seed Virrey.
 */
const API = process.env.API_BASE_URL ?? 'http://localhost:3000/v1';

async function req(method, path, token, body) {
	const res = await fetch(`${API}${path}`, {
		method,
		headers: {
			'Content-Type': 'application/json',
			...(token ? { Authorization: `Bearer ${token}` } : {}),
		},
		body: body ? JSON.stringify(body) : undefined,
	});
	const text = await res.text();
	let data;
	try {
		data = text ? JSON.parse(text) : null;
	} catch {
		data = text;
	}
	if (!res.ok) {
		throw new Error(`${method} ${path} → ${res.status}: ${text}`);
	}
	return data;
}

async function login(nombreUsuario) {
	const data = await req('POST', '/auth/login', null, {
		nombreUsuario,
		password: 'Sika123!',
	});
	return data.accessToken ?? data.access_token ?? data.token;
}

function assert(cond, msg) {
	if (!cond) throw new Error(msg);
}

async function main() {
	console.log('M4 smoke →', API);

	const tokenTecnico = await login('tecnico');
	const tokenPanol = await login('panolero');
	const tokenAdmin = await login('admin');

	const stockAntes = await req('GET', '/stock', tokenPanol);
	assert(Array.isArray(stockAntes) && stockAntes.length > 0, 'Sin stock seed');
	const item = stockAntes.find((s) => Number(s.disponible) >= 1) ?? stockAntes[0];
	const materialId = item.materialId ?? item.material?.id;
	const panolId = item.panolId ?? item.panol?.id;
	assert(materialId && panolId, 'Stock item sin material/pañol');

	const ots = await req('GET', '/ot?estado=pendiente&limit=5', tokenTecnico);
	const lista = Array.isArray(ots) ? ots : ots?.items ?? ots?.data ?? [];
	assert(lista.length > 0, 'Sin OT pendiente para técnico');
	const ot = lista[0];
	const otId = ot.id;

	await req('POST', '/solicitudes-materiales', tokenTecnico, {
		otId,
		items: [{ panolId, materialId, cantidad: 1 }],
	});

	const pendientes = await req(
		'GET',
		`/solicitudes-materiales?estado=pendiente&otId=${otId}`,
		tokenPanol,
	);
	const sols = Array.isArray(pendientes) ? pendientes : pendientes?.items ?? [];
	assert(sols.length > 0, 'No apareció solicitud pendiente');
	await req('PATCH', `/solicitudes-materiales/${sols[0].id}/aprobar`, tokenPanol, {});

	const stockReservado = await req('GET', `/stock?panolId=${panolId}`, tokenPanol);
	const afterReserve = stockReservado.find(
		(s) => (s.materialId ?? s.material?.id) === materialId,
	);
	assert(Number(afterReserve.cantidadReservada) >= 1, 'Reserva no incrementó');

	// Pasar a ejecución si hace falta
	const otFresh = await req('GET', `/ot/${otId}`, tokenTecnico);
	if (otFresh.estado === 'pendiente_panol' || otFresh.estado === 'pendiente') {
		await req('PATCH', `/ot/${otId}/estado`, tokenAdmin, {
			estado: 'en_ejecucion',
		});
	}

	await req('PATCH', `/ot/${otId}/estado`, tokenAdmin, { estado: 'realizada' });

	const stockDespues = await req('GET', `/stock?panolId=${panolId}`, tokenPanol);
	const afterClose = stockDespues.find(
		(s) => (s.materialId ?? s.material?.id) === materialId,
	);
	assert(
		Number(afterClose.cantidadActual) < Number(item.cantidadActual) ||
			Number(afterClose.cantidadReservada) < Number(afterReserve.cantidadReservada),
		'Cierre OT no movió stock',
	);

	const alertas = await req('GET', '/stock/alertas', tokenPanol);
	assert(Array.isArray(alertas), 'alertas debe ser array');

	const movs = await req(
		'GET',
		`/stock/movimientos?panolId=${panolId}`,
		tokenPanol,
	);
	const cierre = (Array.isArray(movs) ? movs : []).find(
		(m) => m.origen === 'ot_cierre' && m.otId === otId,
	);
	assert(cierre, 'Falta movimiento ot_cierre');

	console.log('M4 smoke OK');
}

main().catch((err) => {
	console.error('M4 smoke FAIL:', err.message);
	process.exit(1);
});
