import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
	const app = await NestFactory.create(AppModule);
	const config = app.get(ConfigService);

	app.setGlobalPrefix('v1');
	app.useGlobalPipes(
		new ValidationPipe({
			whitelist: true,
			forbidNonWhitelisted: true,
			transform: true,
		}),
	);

	const origins = config.get<string>('CORS_ORIGINS', 'http://localhost:8080');
	app.enableCors({
		origin: origins.split(',').map((origin) => origin.trim()),
		credentials: true,
	});

	const port = config.get<number>('API_PORT', 3000);
	await app.listen(port);
	console.log(`API lista en http://localhost:${port}/v1`);
}

bootstrap();
