// @ts-check
const { test, expect } = require('@playwright/test');
const {
	apiLogin,
	injectFlutterSession,
	waitForFlutterReady,
	goFlutterRoute,
	tryKeyboardLogin,
	shot,
	API_BASE,
} = require('../helpers');

test.describe.configure({ mode: 'serial' });

test.describe('Smoke UI — supervisor', () => {
	/** @type {string} */
	let accessToken = '';
	/** @type {string} */
	let refreshToken = '';

	test.beforeAll(async ({ request }) => {
		const health = await request.get(`${API_BASE}/storage/status`);
		expect(health.ok(), 'API debe estar en :3000').toBeTruthy();

		const session = await apiLogin(request, 'supervisor');
		accessToken = session.accessToken;
		refreshToken = session.refreshToken;
	});

	test('0) login UI por teclado (best-effort)', async ({ page }) => {
		test.setTimeout(120_000);
		await tryKeyboardLogin(page, 'supervisor');
		await shot(page, '00-login-keyboard');

		const url = page.url();
		// Si el teclado no enganchó CanvasKit, no fallamos el suite: el resto usa sesión inyectada
		test.info().annotations.push({
			type: 'note',
			description: `URL tras login teclado: ${url}`,
		});
	});

	test('1) inyección de sesión + home', async ({ page }) => {
		await injectFlutterSession(page, { accessToken, refreshToken });
		await goFlutterRoute(page, '/home');
		await shot(page, '01-home');

		expect(page.url()).not.toMatch(/\/login$/);
	});

	test('2) planta', async ({ page }) => {
		await injectFlutterSession(page, { accessToken, refreshToken });
		await goFlutterRoute(page, '/planta');
		await shot(page, '02-planta');
		expect(page.url()).toMatch(/planta/);
	});

	test('3) órdenes de trabajo', async ({ page }) => {
		await injectFlutterSession(page, { accessToken, refreshToken });
		await goFlutterRoute(page, '/ot');
		await shot(page, '03-ot');
		expect(page.url()).toMatch(/\/ot/);
	});

	test('4) procedimientos', async ({ page }) => {
		await injectFlutterSession(page, { accessToken, refreshToken });
		await goFlutterRoute(page, '/procedimientos');
		await shot(page, '04-procedimientos');
		expect(page.url()).toMatch(/procedimientos/);
	});

	test('5) OT necesarias', async ({ page }) => {
		await injectFlutterSession(page, { accessToken, refreshToken });
		await goFlutterRoute(page, '/ot/necesarias');
		await shot(page, '05-ot-necesarias');
		expect(page.url()).toMatch(/necesarias/);
	});

	test('6) emitir OT no periódica', async ({ page }) => {
		await injectFlutterSession(page, { accessToken, refreshToken });
		await goFlutterRoute(page, '/ot/emitir-no-periodica');
		await shot(page, '06-emitir-no-periodica');
		expect(page.url()).toMatch(/emitir-no-periodica/);
	});

	test('7) contadores', async ({ page }) => {
		await injectFlutterSession(page, { accessToken, refreshToken });
		await goFlutterRoute(page, '/contadores');
		await shot(page, '07-contadores');
		expect(page.url()).toMatch(/contadores/);
	});
});

test.describe('Smoke UI — técnico', () => {
	test('mis-ot tras login API', async ({ page, request }) => {
		const health = await request.get(`${API_BASE}/storage/status`);
		expect(health.ok()).toBeTruthy();

		const session = await apiLogin(request, 'tecnico');
		await injectFlutterSession(page, {
			accessToken: session.accessToken,
			refreshToken: session.refreshToken,
		});
		await goFlutterRoute(page, '/mis-ot');
		await shot(page, '08-mis-ot-tecnico');
		expect(page.url()).toMatch(/mis-ot/);
	});
});

test('login page carga', async ({ page }) => {
	await page.goto('/login');
	await waitForFlutterReady(page);
	await shot(page, '09-login-page');
	await expect(page.locator('flutter-view, flt-glass-pane, canvas').first()).toBeVisible();
});
