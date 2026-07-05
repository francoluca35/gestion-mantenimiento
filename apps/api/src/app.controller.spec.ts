import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';

describe('AppController', () => {
	let appController: AppController;

	beforeEach(async () => {
		const app: TestingModule = await Test.createTestingModule({
			controllers: [AppController],
			providers: [
				AppService,
				{
					provide: ConfigService,
					useValue: {
						get: (key: string, fallback?: string) => {
							if (key === 'NODE_ENV') return 'test';
							if (key === 'STORAGE_PROVIDER') return 'minio';
							return fallback;
						},
					},
				},
			],
		}).compile();

		appController = app.get<AppController>(AppController);
	});

	it('should return health status', () => {
		const health = appController.getHealth();
		expect(health.status).toBe('ok');
		expect(health.service).toBe('gestion-mantenimiento-api');
	});
});
