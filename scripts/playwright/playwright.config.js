// @ts-check
const { defineConfig, devices } = require('@playwright/test');

const baseURL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:8080';
const apiBase = process.env.PLAYWRIGHT_API_BASE || 'http://localhost:3000/v1';

module.exports = defineConfig({
	testDir: './tests',
	fullyParallel: false,
	forbidOnly: !!process.env.CI,
	retries: process.env.CI ? 1 : 0,
	workers: 1,
	timeout: 90_000,
	expect: { timeout: 20_000 },
	reporter: [
		['list'],
		['html', { open: 'never', outputFolder: 'playwright-report' }],
	],
	use: {
		baseURL,
		trace: 'on-first-retry',
		screenshot: 'only-on-failure',
		video: 'retain-on-failure',
		viewport: { width: 1400, height: 900 },
		locale: 'es-AR',
	},
	projects: [
		{
			name: 'chromium',
			use: { ...devices['Desktop Chrome'] },
		},
	],
	metadata: {
		apiBase,
	},
});
