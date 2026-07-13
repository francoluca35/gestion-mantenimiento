// @ts-check
/**
 * Helpers para automatizar Flutter web (CanvasKit).
 * SharedPreferences en web guarda strings JSON-encoded con prefijo `flutter.`.
 */

const path = require('path');
const fs = require('fs');

const API_BASE = process.env.PLAYWRIGHT_API_BASE || 'http://localhost:3000/v1';
const PASS = process.env.SMOKE_PASS || 'Sika123!';
const SCREENSHOT_DIR = path.join(__dirname, 'test-results', 'screenshots');

/**
 * @param {import('@playwright/test').APIRequestContext} request
 * @param {string} usuario
 */
async function apiLogin(request, usuario) {
	const res = await request.post(`${API_BASE}/auth/login`, {
		data: { nombreUsuario: usuario, clave: PASS },
	});
	if (!res.ok()) {
		throw new Error(`Login API ${usuario} falló: ${res.status()} ${await res.text()}`);
	}
	const body = await res.json();
	if (!body.accessToken || !body.refreshToken) {
		throw new Error(`Login ${usuario} sin tokens`);
	}
	return body;
}

/**
 * Inyecta sesión Flutter SharedPreferences y recarga.
 * @param {import('@playwright/test').Page} page
 * @param {{ accessToken: string, refreshToken: string }} session
 */
async function injectFlutterSession(page, session) {
	await page.goto('/');
	await page.waitForSelector('flutter-view, flt-glass-pane, canvas', {
		timeout: 60_000,
	});

	await page.evaluate(
		({ accessToken, refreshToken }) => {
			localStorage.setItem('flutter.access_token', JSON.stringify(accessToken));
			localStorage.setItem('flutter.refresh_token', JSON.stringify(refreshToken));
		},
		{
			accessToken: session.accessToken,
			refreshToken: session.refreshToken,
		},
	);

	await page.reload({ waitUntil: 'domcontentloaded' });
	await waitForFlutterReady(page);
}

/**
 * @param {import('@playwright/test').Page} page
 */
async function waitForFlutterReady(page) {
	await page.waitForSelector('flutter-view, flt-glass-pane, canvas', {
		timeout: 60_000,
	});
	// Dar tiempo al primer frame + bootstrap de auth
	await page.waitForTimeout(2500);
}

/**
 * Navega a una ruta de go_router (soporta path y hash URL strategy).
 * @param {import('@playwright/test').Page} page
 * @param {string} route  ej. '/planta'
 */
async function goFlutterRoute(page, route) {
	const path = route.startsWith('/') ? route : `/${route}`;

	// Preferir path strategy; si la app usa hash, reintentar
	await page.goto(path, { waitUntil: 'domcontentloaded' });
	await waitForFlutterReady(page);

	let url = page.url();
	const landedOnLogin = /\/login\/?$/.test(new URL(url).pathname) || url.endsWith('/#/login');
	if (landedOnLogin && path !== '/login') {
		await page.goto(`/#${path}`, { waitUntil: 'domcontentloaded' });
		await waitForFlutterReady(page);
		url = page.url();
	}

	// Si aún estamos en login, la sesión no levantó a tiempo
	if ((url.includes('/login') || url.endsWith('#/login')) && path !== '/login') {
		await page.waitForTimeout(2000);
		await page.goto(path, { waitUntil: 'domcontentloaded' });
		await waitForFlutterReady(page);
		if (page.url().includes('login')) {
			await page.goto(`/#${path}`, { waitUntil: 'domcontentloaded' });
			await waitForFlutterReady(page);
		}
	}
}

/**
 * Intenta login por teclado (Flutter CanvasKit no expone inputs HTML).
 * @param {import('@playwright/test').Page} page
 * @param {string} usuario
 * @param {string} [clave]
 */
async function tryKeyboardLogin(page, usuario, clave = PASS) {
	await page.goto('/login');
	await waitForFlutterReady(page);

	const pane = page.locator('flt-glass-pane, flutter-view, body').first();
	await pane.click({ position: { x: 700, y: 420 } });
	await page.waitForTimeout(400);

	// Tab hasta el campo usuario y escribir
	for (let i = 0; i < 6; i++) {
		await page.keyboard.press('Tab');
		await page.waitForTimeout(150);
	}

	await page.keyboard.type(usuario, { delay: 40 });
	await page.keyboard.press('Tab');
	await page.waitForTimeout(200);
	await page.keyboard.type(clave, { delay: 40 });
	await page.keyboard.press('Enter');
	await page.waitForTimeout(3500);
}

/**
 * @param {import('@playwright/test').Page} page
 * @param {string} name
 */
async function shot(page, name) {
	fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
	await page.screenshot({
		path: path.join(SCREENSHOT_DIR, `${name}.png`),
		fullPage: true,
	});
}

module.exports = {
	API_BASE,
	PASS,
	apiLogin,
	injectFlutterSession,
	waitForFlutterReady,
	goFlutterRoute,
	tryKeyboardLogin,
	shot,
};
