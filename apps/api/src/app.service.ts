import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from './database/prisma.service';

@Injectable()
export class AppService {
	constructor(
		private readonly config: ConfigService,
		private readonly prisma: PrismaService,
	) {}

	getHealth() {
		return {
			status: 'ok',
			service: 'gestion-mantenimiento-api',
			env: this.config.get<string>('NODE_ENV', 'development'),
			storageProvider: this.config.get<string>('STORAGE_PROVIDER', 'local'),
			timestamp: new Date().toISOString(),
		};
	}

	async getReady() {
		try {
			await this.prisma.ping();
			return {
				status: 'ready',
				database: 'up',
				storageProvider: this.config.get<string>('STORAGE_PROVIDER', 'local'),
				timestamp: new Date().toISOString(),
			};
		} catch (error) {
			throw new ServiceUnavailableException({
				status: 'not_ready',
				database: 'down',
				error: error instanceof Error ? error.message : 'db_unreachable',
				timestamp: new Date().toISOString(),
			});
		}
	}
}
