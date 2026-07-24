// Capturas para Google Play Store (teléfono + tablet)
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const {
	apiLogin,
	injectFlutterSession,
	goFlutterRoute,
	waitForFlutterReady,
} = require('./helpers');

const OUT = path.join(__dirname, '..', '..', 'play-store');
const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:8080';

async function shot(page, file) {
	fs.mkdirSync(path.dirname(file), { recursive: true });
	await page.waitForTimeout(1500);
	await page.screenshot({ path: file, type: 'png' });
	console.log('OK', file);
}

async function capture(device, folder, size, scale = 1) {
	const browser = await chromium.launch({ headless: true });
	const context = await browser.newContext({
		viewport: size,
		deviceScaleFactor: scale,
		baseURL: BASE,
	});
	const page = await context.newPage();
	const request = context.request;

	const session = await apiLogin(request, 'admin');
	await injectFlutterSession(page, session);

	await goFlutterRoute(page, '/home');
	await shot(page, path.join(OUT, folder, '01-inicio.png'));

	await goFlutterRoute(page, '/ot');
	await shot(page, path.join(OUT, folder, '02-ordenes.png'));

	await goFlutterRoute(page, '/planta');
	await shot(page, path.join(OUT, folder, '03-planta.png'));

	await goFlutterRoute(page, '/panol');
	await shot(page, path.join(OUT, folder, '04-panol.png'));

	await context.clearCookies();
	await page.evaluate(() => localStorage.clear());
	await page.goto('/login');
	await waitForFlutterReady(page);
	await shot(page, path.join(OUT, folder, '05-login.png'));

	await browser.close();
}

(async () => {
	fs.mkdirSync(OUT, { recursive: true });
	// Teléfono: ancho < 600 para layout mobile; scale alto para calidad Play
	await capture('phone', 'mobile', { width: 400, height: 860 }, 3);
	// Tablet 7–10" landscape
	await capture('tablet', 'tablet', { width: 1024, height: 768 }, 2);
	console.log('Listo en', OUT);
})().catch((e) => {
	console.error(e);
	process.exit(1);
});
