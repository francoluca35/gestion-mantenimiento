/**
 * Smoke test Ola 2 — flujo API end-to-end (sin push FCM).
 * Uso: node tools/smoke-ola2.mjs
 */
const BASE = process.env.API_BASE_URL ?? 'http://localhost:3000/v1';

const IDS = {
	procLubricacion: '77777777-7777-7777-7777-777777777701',
	silo104: '66666666-6666-6666-6666-666666666612',
	silo103: '66666666-6666-6666-6666-666666666611',
	sectorLosa: '66666666-6666-6666-6666-666666666602',
	solicitudPendiente: '99999999-9999-9999-9999-999999999901',
	solicitudConformada: '99999999-9999-9999-9999-999999999902',
	otPendiente: '88888888-8888-8888-8888-888888888801',
	mol01: '66666666-6666-6666-6666-666666666613',
	procCorrectivo: '77777777-7777-7777-7777-777777777702',
};

const results = [];

function log(step, ok, detail = '') {
	const mark = ok ? '✅' : '❌';
	results.push({ step, ok, detail });
	console.log(`${mark} ${step}${detail ? ` — ${detail}` : ''}`);
}

async function api(path, { method = 'GET', token, body } = {}) {
	const headers = { 'Content-Type': 'application/json' };
	if (token) headers.Authorization = `Bearer ${token}`;

	const res = await fetch(`${BASE}${path}`, {
		method,
		headers,
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
		const msg =
			typeof data === 'object' && data?.message
				? Array.isArray(data.message)
					? data.message.join('; ')
					: data.message
				: text.slice(0, 300);
		throw new Error(`${method} ${path} → ${res.status}: ${msg}`);
	}

	return data;
}

async function login(usuario, clave) {
	const data = await api('/auth/login', {
		method: 'POST',
		body: { nombreUsuario: usuario, clave },
	});
	return data;
}

function todayIso() {
	return new Date().toISOString().slice(0, 10);
}

async function main() {
	console.log(`\n🔍 Smoke Ola 2 — ${BASE}\n`);

	// ── 1. Supervisor: OT necesarias ─────────────────────────────
	let supervisor;
	let tecnicoId;

	try {
		supervisor = await login('supervisor', 'Sika123!');
		log('Login supervisor', true, supervisor.usuario?.nombreUsuario);
	} catch (e) {
		log('Login supervisor', false, e.message);
		return finish(1);
	}

	const supToken = supervisor.accessToken;

	try {
		const necesarias = await api('/ot/necesarias', { token: supToken });
		const items = necesarias.items ?? necesarias;
		const silo104 = Array.isArray(items)
			? items.find((i) => i.equipo?.id === IDS.silo104 || i.equipoId === IDS.silo104)
			: null;
		log(
			'Listar OT necesarias',
			Array.isArray(items) && items.length > 0,
			`${items?.length ?? 0} ítems${silo104 ? ', SILO-104 presente' : ''}`,
		);

		if (silo104) {
			const tecnicos = await api('/ot/tecnicos', { token: supToken });
			tecnicoId = tecnicos[0]?.id ?? supervisor.usuario?.id;
			const emitidas = await api('/ot/necesarias/emitir', {
				method: 'POST',
				token: supToken,
				body: {
					items: [
						{
							procedimientoId: silo104.procedimientoId,
							equipoId: silo104.equipo?.id ?? IDS.silo104,
							fechaProgramacion: todayIso(),
							tecnicoAsignadoId: tecnicoId,
							prioridad: 'media',
							notificarAsignacion: false,
						},
					],
				},
			});
			const otNec = emitidas.ordenes?.[0] ?? emitidas[0] ?? emitidas;
			log(
				'Emitir OT desde necesarias',
				!!(otNec?.id || otNec?.numero),
				`OT #${otNec?.numero ?? '?'}`,
			);
		} else {
			log('Emitir OT desde necesarias', false, 'SILO-104 no en necesarias (seed?)');
		}
	} catch (e) {
		log('Flujo OT necesarias', false, e.message);
	}

	// ── 2. Supervisor: solicitudes ───────────────────────────────
	let otSolicitudId;

	try {
		await api(`/solicitudes-trabajo/${IDS.solicitudPendiente}/conformidad`, {
			method: 'PATCH',
			token: supToken,
			body: { conforme: true, calificacion: 'bueno' },
		});
		log('Conformar solicitud pendiente', true);
	} catch (e) {
		log('Conformar solicitud pendiente', false, e.message);
	}

	try {
		const tecnicos = await api('/ot/tecnicos', { token: supToken });
		tecnicoId = tecnicoId ?? tecnicos.find((t) => t.nombreUsuario === 'tecnico')?.id ?? tecnicos[0]?.id;

		const otEmitida = await api(
			`/solicitudes-trabajo/${IDS.solicitudPendiente}/emitir-ot`,
			{
				method: 'POST',
				token: supToken,
				body: {
					equipoId: IDS.silo103,
					procedimientoId: IDS.procCorrectivo,
					tipo: 'correctivo',
					tecnicoAsignadoId: tecnicoId,
					fechaProgramacion: todayIso(),
					prioridad: 'alta',
					notificarAsignacion: false,
				},
			},
		);
		otSolicitudId = otEmitida.id;
		log('Emitir OT desde solicitud', true, `OT #${otEmitida.numero}`);
	} catch (e) {
		log('Emitir OT desde solicitud', false, e.message);
	}

	// ── 3. PDF ───────────────────────────────────────────────────
	const pdfOtId = otSolicitudId ?? IDS.otPendiente;
	try {
		const pdf = await api(`/ot/${pdfOtId}/pdf`, { token: supToken });
		const hasHtml = typeof pdf.html === 'string' && pdf.html.length > 500;
		log('PDF OT (HTML)', hasHtml, `${pdf.html?.length ?? 0} chars`);
	} catch (e) {
		log('PDF OT (HTML)', false, e.message);
	}

	// ── 4. Técnico: checklist + firma ────────────────────────────
	let tecnico;
	try {
		tecnico = await login('tecnico', 'Sika123!');
		log('Login técnico', true);
	} catch (e) {
		log('Login técnico', false, e.message);
		return finish(1);
	}

	const tecToken = tecnico.accessToken;
	let otCerrarId = IDS.otPendiente;

	try {
		const misOt = await api('/ot?misOt=true', { token: tecToken });
		const lista = Array.isArray(misOt) ? misOt : misOt.items ?? [];
		const pendiente = lista.find((o) => o.estado === 'pendiente');
		if (pendiente) otCerrarId = pendiente.id;
		log('Listar Mis OT (técnico)', lista.length > 0, `${lista.length} OT, cerrar #${pendiente?.numero ?? '1001'}`);
	} catch (e) {
		log('Listar Mis OT (técnico)', false, e.message);
	}

	try {
		const ot = await api(`/ot/${otCerrarId}`, { token: tecToken });
		if (ot.estado === 'pendiente') {
			await api(`/ot/${otCerrarId}/estado`, {
				method: 'PATCH',
				token: tecToken,
				body: { estado: 'en_ejecucion', comentario: 'Inicio smoke test' },
			});
		}
		log('Iniciar ejecución OT', true, `estado previo: ${ot.estado}`);
	} catch (e) {
		log('Iniciar ejecución OT', false, e.message);
	}

	try {
		const ot = await api(`/ot/${otCerrarId}`, { token: tecToken });
		const planilla =
			ot.procedimiento?.planillaLecturas ??
			ot.checklistCompletado ??
			[
				{ key: 'inspeccion', label: 'Inspección', done: true },
				{ key: 'engrase', label: 'Engrase', done: true },
			];
		const items = Array.isArray(planilla)
			? planilla.map((i) => ({ ...i, done: true }))
			: planilla;

		await api(`/ot/${otCerrarId}/checklist`, {
			method: 'POST',
			token: tecToken,
			body: { items },
		});
		log('Completar checklist', true);
	} catch (e) {
		log('Completar checklist', false, e.message);
	}

	try {
		const firma = Buffer.from('smoke-test-firma').toString('base64');
		const cerrada = await api(`/ot/${otCerrarId}/firma`, {
			method: 'POST',
			token: tecToken,
			body: { firmaDigital: firma },
		});
		log(
			'Firma y cierre OT',
			cerrada.estado === 'realizada',
			`estado: ${cerrada.estado}`,
		);
	} catch (e) {
		log('Firma y cierre OT', false, e.message);
	}

	// ── 5. Asociar procedimiento (alcance sector) ────────────────
	try {
		await api(`/procedimientos/${IDS.procLubricacion}/asociar-alcance`, {
			method: 'POST',
			token: supToken,
			body: { tipo: 'ubicacion', targetId: IDS.sectorLosa },
		});
		log('Asociar procedimiento a sector', true, 'Sector Losa');
	} catch (e) {
		// Ya asociado es OK
		const ok = /ya|exist|unique|duplicate/i.test(e.message);
		log('Asociar procedimiento a sector', ok, ok ? 'ya asociado' : e.message);
	}

	return finish();
}

function finish(code = 0) {
	const failed = results.filter((r) => !r.ok);
	console.log('\n── Resumen ──');
	console.log(`Total: ${results.length} | OK: ${results.length - failed.length} | Fallos: ${failed.length}`);
	if (failed.length) {
		console.log('\nFallos:');
		for (const f of failed) console.log(`  • ${f.step}: ${f.detail}`);
	}
	process.exit(failed.length ? 1 : 0);
}

main().catch((e) => {
	console.error('Error fatal:', e);
	process.exit(1);
});
