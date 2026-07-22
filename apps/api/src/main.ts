import { Logger, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

function requireProdEnv(config: ConfigService, key: string): string {
	const value = config.get<string>(key)?.trim();
	if (!value) {
		throw new Error(`Missing required env: ${key}`);
	}
	return value;
}

async function bootstrap() {
	const app = await NestFactory.create(AppModule);
	const config = app.get(ConfigService);
	const logger = new Logger('Bootstrap');
	const nodeEnv = config.get<string>('NODE_ENV', 'development');

	if (nodeEnv === 'production') {
		requireProdEnv(config, 'DATABASE_URL');
		const jwt = requireProdEnv(config, 'JWT_SECRET');
		if (jwt.length < 32 || jwt.includes('change-me') || jwt.includes('dev-secret')) {
			throw new Error('JWT_SECRET must be a strong secret (>= 32 chars) in production');
		}
		requireProdEnv(config, 'JWT_REFRESH_SECRET');
	}

	app.enableShutdownHooks();
	app.setGlobalPrefix('v1');
	app.useGlobalPipes(
		new ValidationPipe({
			whitelist: true,
			forbidNonWhitelisted: true,
			transform: true,
		}),
	);

	const origins = config.get<string>(
		'CORS_ORIGINS',
		config.get<string>('CORS_ORIGIN', 'http://localhost:8080'),
	);
	app.enableCors({
		origin: origins.split(',').map((origin) => origin.trim()).filter(Boolean),
		credentials: true,
	});

	const port = Number(
		config.get<string>('API_PORT') ??
			config.get<string>('PORT') ??
			3000,
	);

	await app.listen(port, '0.0.0.0');
	logger.log(`API lista en http://0.0.0.0:${port}/v1`);
}

bootstrap().catch((err) => {
	console.error('Fatal bootstrap error:', err);
	process.exit(1);
});
