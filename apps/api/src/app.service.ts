import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AppService {
	constructor(private readonly config: ConfigService) {}

	getHealth() {
		return {
			status: 'ok',
			service: 'gestion-mantenimiento-api',
			env: this.config.get<string>('NODE_ENV', 'development'),
			storageProvider: this.config.get<string>('STORAGE_PROVIDER', 'minio'),
			timestamp: new Date().toISOString(),
		};
	}
}
