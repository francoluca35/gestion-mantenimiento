#!/usr/bin/env node
/**
 * Smoke bot — valida flujos API de Sprints 1–3 contra un servidor vivo.
 *
 * Uso:
 *   node scripts/smoke-bot.mjs
 *   node scripts/smoke-bot.mjs --base http://localhost:3000/v1
 *   SMOKE_PASS=Sika123! node scripts/smoke-bot.mjs
 *
 * Requiere: API corriendo (npm run start:dev en apps/api).
 */

const BASE = (process.argv.includes('--base')
	? process.argv[process.argv.indexOf('--base') + 1]
	: process.env.SMOKE_BASE) || 'http://localhost:3000/v1';

const PASS = process.env.SMOKE_PASS || 'Sika123!';
const USERS = ['admin', 'supervisor', 'tecnico'];

const results = [];
let passed = 0;
let failed = 0;

function ok(name, detail = '') {
	passed += 1;
	results.push({ ok: true, name, detail });
	console.log(`  ✓ ${name}${detail ? ` — ${detail}` : ''}`);
}

function fail(name, detail = '') {
	failed += 1;
	results.push({ ok: false, name, detail });
	console.error(`  ✗ ${name}${detail ? ` — ${detail}` : ''}`);
}

async function req(method, path, { token, body, expectStatus } = {}) {
	const url = path.startsWith('http') ? path : `${BASE}${path.startsWith('/') ? path : `/${path}`}`;
	const headers = { Accept: 'application/json' };
	if (token) headers.Authorization = `Bearer ${token}`;
	if (body !== undefined) headers['Content-Type'] = 'application/json';

	const res = await fetch(url, {
		method,
		headers,
		body: body !== undefined ? JSON.stringify(body) : undefined,
	});

	const text = await res.text();
	let data = null;
	try {
		data = text ? JSON.parse(text) : null;
	} catch {
		data = text;
	}

	if (expectStatus != null && res.status !== expectStatus) {
		const err = new Error(`HTTP ${res.status} (esperado ${expectStatus})`);
		err.status = res.status;
		err.data = data;
		throw err;
	}

	return { status: res.status, data };
}

async function login(usuario) {
	const res = await req('POST', '/auth/login', {
		body: { nombreUsuario: usuario, clave: PASS },
	});
	if (res.status !== 200 && res.status !== 201) {
		throw new Error(`HTTP ${res.status}`);
	}
	if (!res.data?.accessToken) throw new Error('Sin accessToken');
	return res.data.accessToken;
}

function isoDate(d = new Date()) {
	return d.toISOString().slice(0, 10);
}

function daysAgo(n) {
	const d = new Date();
	d.setDate(d.getDate() - n);
	return isoDate(d);
}

async function section(title, fn) {
	console.log(`\n▸ ${title}`);
	try {
		await fn();
	} catch (error) {
		fail(title, error.message || String(error));
	}
}

async function main() {
	console.log(`Smoke bot Sika CMMS`);
	console.log(`Base: ${BASE}`);
	console.log(`Usuarios: ${USERS.join(', ')}`);

	// 0. Health
	await section('API disponible', async () => {
		const { data } = await req('GET', '/storage/status', { expectStatus: 200 });
		ok('GET /storage/status', `provider=${data?.provider ?? '?'}`);
	});

	const tokens = {};

	// 1. Auth por rol
	await section('Login por rol', async () => {
		for (const u of USERS) {
			try {
				tokens[u] = await login(u);
				ok(`login ${u}`);
			} catch (error) {
				fail(`login ${u}`, error.message);
			}
		}
	});

	if (!tokens.admin && !tokens.supervisor) {
		console.error('\nSin token de admin/supervisor — abortando.');
		process.exit(1);
	}

	const token = tokens.supervisor || tokens.admin;
	const adminToken = tokens.admin || token;

	let sucursalId = null;
	let equipoId = null;
	let otId = null;

	// 2. Planta (Sprint 2)
	await section('Planta / equipos (Sprint 2)', async () => {
		const { data: sucursales } = await req('GET', '/sucursales', {
			token: adminToken,
			expectStatus: 200,
		});
		if (!Array.isArray(sucursales) || sucursales.length === 0) {
			throw new Error('Sin sucursales');
		}
		const virrey =
			sucursales.find((s) => s.codigo === 'VIRREY') || sucursales[0];
		sucursalId = virrey.id;
		ok('GET /sucursales', `${sucursales.length} planta(s)`);

		const { data: tree } = await req(
			'GET',
			`/ubicaciones/tree?sucursalId=${sucursalId}`,
			{ token, expectStatus: 200 },
		);
		ok('GET /ubicaciones/tree', `${Array.isArray(tree) ? tree.length : 0} raíces`);

		const { data: equipos } = await req(
			'GET',
			`/equipos?sucursalId=${sucursalId}`,
			{ token, expectStatus: 200 },
		);
		if (!Array.isArray(equipos) || equipos.length === 0) {
			throw new Error('Sin equipos');
		}
		equipoId = equipos[0].id;
		ok('GET /equipos', `${equipos.length} máquina(s)`);

		const { data: tipos } = await req('GET', '/tipos-equipo', {
			token,
			expectStatus: 200,
		});
		ok('GET /tipos-equipo', `${Array.isArray(tipos) ? tipos.length : 0}`);

		const { data: detalle } = await req('GET', `/equipos/${equipoId}`, {
			token,
			expectStatus: 200,
		});
		ok('GET /equipos/:id', detalle?.codigo ?? equipoId);

		await req('GET', `/equipos/${equipoId}/historial`, {
			token,
			expectStatus: 200,
		});
		ok('GET /equipos/:id/historial');

		await req('GET', `/equipos/${equipoId}/procedimientos`, {
			token,
			expectStatus: 200,
		});
		ok('GET /equipos/:id/procedimientos');

		await req('GET', `/equipos/${equipoId}/documentos`, {
			token,
			expectStatus: 200,
		});
		ok('GET /equipos/:id/documentos');

		await req('GET', `/ubicaciones/alcance/procedimientos?sucursalId=${sucursalId}`, {
			token,
			expectStatus: 200,
		});
		ok('GET /ubicaciones/alcance/procedimientos');
	});

	// 3. Procedimientos (Sprint 1)
	await section('Procedimientos (Sprint 1)', async () => {
		const { data: procs } = await req('GET', '/procedimientos', {
			token,
			expectStatus: 200,
		});
		const list = Array.isArray(procs) ? procs : procs?.items ?? [];
		ok('GET /procedimientos', `${list.length} proc(s)`);

		if (list.length > 0) {
			const id = list[0].id;
			await req('GET', `/procedimientos/${id}`, { token, expectStatus: 200 });
			ok('GET /procedimientos/:id');
		}

		await req('GET', '/procedimientos?tipo=preventivo&q=mant', {
			token,
			expectStatus: 200,
		});
		ok('GET /procedimientos con filtros');
	});

	// 4. OT profundidad (Sprint 3)
	await section('Órdenes de trabajo (Sprint 3)', async () => {
		const q =
			`?fechaDesde=${daysAgo(120)}&fechaHasta=${isoDate()}` +
			(sucursalId ? `` : '');

		const { data: resumen } = await req('GET', `/ot/resumen${q}`, {
			token,
			expectStatus: 200,
		});
		ok('GET /ot/resumen', JSON.stringify(resumen).slice(0, 80));

		const { data: ordenes } = await req('GET', `/ot${q}`, {
			token,
			expectStatus: 200,
		});
		if (!Array.isArray(ordenes)) throw new Error('ot no es array');
		ok('GET /ot', `${ordenes.length} OT`);

		await req('GET', `/ot${q}&prioridad=media`, { token, expectStatus: 200 });
		ok('GET /ot?prioridad=media');

		const { data: tipos } = await req('GET', '/tipos-equipo', {
			token,
			expectStatus: 200,
		});
		if (Array.isArray(tipos) && tipos[0]?.id) {
			await req('GET', `/ot${q}&tipoEquipoId=${tipos[0].id}`, {
				token,
				expectStatus: 200,
			});
			ok('GET /ot?tipoEquipoId=…');
		}

		const { data: tecnicos } = await req('GET', '/ot/tecnicos', {
			token,
			expectStatus: 200,
		});
		ok('GET /ot/tecnicos', `${Array.isArray(tecnicos) ? tecnicos.length : 0}`);

		const { data: motivos } = await req('GET', '/motivos-ot-pendiente', {
			token,
			expectStatus: 200,
		});
		ok(
			'GET /motivos-ot-pendiente',
			`${Array.isArray(motivos) ? motivos.length : 0}`,
		);

		if (sucursalId) {
			const { data: necesarias } = await req(
				'GET',
				`/ot/necesarias?sucursalId=${sucursalId}`,
				{ token, expectStatus: 200 },
			);
			ok(
				'GET /ot/necesarias',
				`${necesarias?.items?.length ?? 0} candidata(s)`,
			);
		}

		const candidata =
			ordenes.find((o) => o.estado === 'realizada') ||
			ordenes.find((o) => o.estado === 'pendiente') ||
			ordenes[0];

		if (candidata) {
			otId = candidata.id;
			await req('GET', `/ot/${otId}`, { token, expectStatus: 200 });
			ok('GET /ot/:id', `#${candidata.numero}`);

			const pdf = await req('GET', `/ot/${otId}/pdf`, { token, expectStatus: 200 });
			const html = pdf.data?.html ?? '';
			if (!html || !String(html).includes('ORDEN DE TRABAJO')) {
				fail('GET /ot/:id/pdf', 'HTML sin título OT');
			} else {
				ok('GET /ot/:id/pdf', `html ${String(html).length} chars`);
			}
		} else {
			fail('GET /ot/:id', 'No hay OT para detalle');
		}
	});

	// 5. Contadores
	await section('Contadores / lecturas', async () => {
		if (!equipoId) throw new Error('Sin equipo');
		const { data: lecturas } = await req(
			'GET',
			`/equipos/${equipoId}/lecturas`,
			{ token: adminToken, expectStatus: 200 },
		);
		ok(
			'GET /equipos/:id/lecturas',
			`${Array.isArray(lecturas) ? lecturas.length : 0}`,
		);
	});

	// 6. Técnico — mis OT
	await section('Rol técnico', async () => {
		if (!tokens.tecnico) {
			fail('login tecnico', 'no disponible');
			return;
		}
		const { data: mis } = await req(
			'GET',
			`/ot?misOt=true&fechaDesde=${daysAgo(180)}&fechaHasta=${isoDate()}`,
			{ token: tokens.tecnico, expectStatus: 200 },
		);
		ok('GET /ot?misOt=true', `${Array.isArray(mis) ? mis.length : 0} OT`);
	});

	// 7. Emisión smoke (crea 1 OT correctiva y verifica PDF)
	await section('Emitir OT no periódica (smoke write)', async () => {
		if (!equipoId) throw new Error('Sin equipo');
		const emit = await req('POST', '/ot/emitir', {
			token,
			body: {
				equipoId,
				tipo: 'correctivo',
				prioridad: 'baja',
				fechaProgramacion: isoDate(),
				tolerancia: 3,
				comentarios: `[smoke-bot] ${new Date().toISOString()}`,
				notificarAsignacion: false,
			},
		});
		if (emit.status !== 201 && emit.status !== 200) {
			throw new Error(`HTTP ${emit.status}: ${JSON.stringify(emit.data)}`);
		}
		ok('POST /ot/emitir', `#${emit.data?.numero}`);

		if (emit.data?.id) {
			const pdf = await req('GET', `/ot/${emit.data.id}/pdf`, {
				token,
				expectStatus: 200,
			});
			ok('PDF OT emitida', pdf.data?.html ? 'ok' : 'sin html');
		}
	});

	// Resumen
	console.log('\n────────────────────────────');
	console.log(`Resultado: ${passed} ok · ${failed} fail`);
	if (failed > 0) {
		console.log('\nFallos:');
		for (const r of results.filter((x) => !x.ok)) {
			console.log(`  - ${r.name}: ${r.detail}`);
		}
		process.exit(1);
	}
	console.log('Smoke OK — flujos Sprints 1–3 respondiendo.');
	process.exit(0);
}

main().catch((error) => {
	console.error('\nSmoke abortó:', error);
	process.exit(1);
});
