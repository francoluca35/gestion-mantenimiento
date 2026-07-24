import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';

@Injectable()
export class OtPdfBinaryService {
	private readonly logger = new Logger(OtPdfBinaryService.name);

	async htmlToPdf(html: string): Promise<Buffer> {
		let browser: { close: () => Promise<void> } | null = null;
		try {
			const puppeteer = await import('puppeteer');
			browser = await puppeteer.default.launch({
				headless: true,
				args: [
					'--no-sandbox',
					'--disable-setuid-sandbox',
					'--disable-dev-shm-usage',
					'--disable-gpu',
				],
			});
			const page = await (browser as any).newPage();
			await page.setContent(html, { waitUntil: 'networkidle0' });
			const pdf = await page.pdf({
				format: 'A4',
				printBackground: true,
				margin: { top: '12mm', right: '10mm', bottom: '12mm', left: '10mm' },
			});
			return Buffer.from(pdf);
		} catch (error) {
			this.logger.error('No se pudo generar PDF binario', error);
			throw new ServiceUnavailableException(
				'Generación de PDF no disponible en este entorno. Usá la vista HTML / imprimir.',
			);
		} finally {
			if (browser) {
				await browser.close().catch(() => undefined);
			}
		}
	}
}
