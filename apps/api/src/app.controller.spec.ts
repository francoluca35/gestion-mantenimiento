import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './database/prisma.service';

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
							if (key === 'STORAGE_PROVIDER') return 'local';
							return fallback;
						},
					},
				},
				{
					provide: PrismaService,
					useValue: {
						$queryRaw: jest.fn().mockResolvedValue([{ '?column?': 1 }]),
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

	it('should return ready status', async () => {
		const ready = await appController.getReady();
		expect(ready.status).toBe('ready');
		expect(ready.database).toBe('up');
	});
});
