import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';

async function login(app: INestApplication<App>, usuario: string) {
	const res = await request(app.getHttpServer())
		.post('/v1/auth/login')
		.send({ nombreUsuario: usuario, clave: 'Sika123!' })
		.expect(201);
	return res.body.accessToken as string;
}

describe('OT Mantenimiento (e2e)', () => {
	let app: INestApplication<App>;
	let adminToken: string;

	beforeAll(async () => {
		const moduleFixture: TestingModule = await Test.createTestingModule({
			imports: [AppModule],
		}).compile();

		app = moduleFixture.createNestApplication();
		app.setGlobalPrefix('v1');
		app.useGlobalPipes(
			new ValidationPipe({
				whitelist: true,
				forbidNonWhitelisted: true,
				transform: true,
			}),
		);
		await app.init();
		adminToken = await login(app, 'admin');
	});

	afterAll(async () => {
		await app.close();
	});

	it('GET /ot con filtros', async () => {
		const res = await request(app.getHttpServer())
			.get('/v1/ot?prioridad=media')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		expect(Array.isArray(res.body)).toBe(true);
	});

	it('GET /ot/necesarias', async () => {
		const sucursales = await request(app.getHttpServer())
			.get('/v1/sucursales')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);
		const virrey = (sucursales.body as Array<{ codigo: string; id: string }>).find(
			(s) => s.codigo === 'VIRREY',
		);

		const res = await request(app.getHttpServer())
			.get(`/v1/ot/necesarias?sucursalId=${virrey!.id}`)
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		expect(res.body).toHaveProperty('items');
	});

	it('GET /motivos-ot-pendiente', async () => {
		const res = await request(app.getHttpServer())
			.get('/v1/motivos-ot-pendiente')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		expect(Array.isArray(res.body)).toBe(true);
		expect(res.body.length).toBeGreaterThan(0);
	});

	it('POST /ot/:id/derivar sobre OT realizada', async () => {
		const ordenes = await request(app.getHttpServer())
			.get('/v1/ot?estado=realizada')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		const realizada = (ordenes.body as Array<{ id: string; estado: string }>).find(
			(o) => o.estado === 'realizada',
		);
		expect(realizada).toBeDefined();

		const derivada = await request(app.getHttpServer())
			.post(`/v1/ot/${realizada!.id}/derivar`)
			.set('Authorization', `Bearer ${adminToken}`)
			.send({})
			.expect(201);

		expect(derivada.body.tipo).toBe('correctivo');
	});
});
