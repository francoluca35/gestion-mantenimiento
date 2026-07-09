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

describe('Planta (e2e)', () => {
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

	it('GET /ubicaciones/tree', async () => {
		const sucursales = await request(app.getHttpServer())
			.get('/v1/sucursales')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		const virrey = (sucursales.body as Array<{ codigo: string; id: string }>).find(
			(s) => s.codigo === 'VIRREY',
		);

		const res = await request(app.getHttpServer())
			.get(`/v1/ubicaciones/tree?sucursalId=${virrey!.id}`)
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		expect(Array.isArray(res.body)).toBe(true);
	});

	it('GET /equipos con sucursal', async () => {
		const sucursales = await request(app.getHttpServer())
			.get('/v1/sucursales')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		const virrey = (sucursales.body as Array<{ codigo: string; id: string }>).find(
			(s) => s.codigo === 'VIRREY',
		);

		const res = await request(app.getHttpServer())
			.get(`/v1/equipos?sucursalId=${virrey!.id}`)
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		expect(Array.isArray(res.body)).toBe(true);
		expect(res.body.length).toBeGreaterThan(0);
	});

	it('componentes y duplicar equipo', async () => {
		const sucursales = await request(app.getHttpServer())
			.get('/v1/sucursales')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);
		const virrey = (sucursales.body as Array<{ codigo: string; id: string }>).find(
			(s) => s.codigo === 'VIRREY',
		);

		const equipos = await request(app.getHttpServer())
			.get(`/v1/equipos?sucursalId=${virrey!.id}`)
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		const equipo = (equipos.body as Array<{ id: string }>)[0];
		expect(equipo).toBeDefined();

		const componente = await request(app.getHttpServer())
			.post(`/v1/equipos/${equipo.id}/componentes`)
			.set('Authorization', `Bearer ${adminToken}`)
			.send({ nombre: 'Motor prueba', codigo: 'MOT-TEST' })
			.expect(201);

		expect(componente.body.nombre).toBe('Motor prueba');

		const list = await request(app.getHttpServer())
			.get(`/v1/equipos/${equipo.id}/componentes`)
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		expect((list.body as unknown[]).length).toBeGreaterThan(0);

		const duplicado = await request(app.getHttpServer())
			.post(`/v1/equipos/${equipo.id}/duplicar`)
			.set('Authorization', `Bearer ${adminToken}`)
			.send({})
			.expect(201);

		expect(duplicado.body.id).not.toBe(equipo.id);
	});

	it('PATCH ubicación y mover', async () => {
		const nombre = `TEST-UBIC-${Date.now()}`;
		const sucursales = await request(app.getHttpServer())
			.get('/v1/sucursales')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);
		const virrey = (sucursales.body as Array<{ codigo: string; id: string }>).find(
			(s) => s.codigo === 'VIRREY',
		);

		const created = await request(app.getHttpServer())
			.post('/v1/ubicaciones')
			.set('Authorization', `Bearer ${adminToken}`)
			.send({ sucursalId: virrey!.id, nombre })
			.expect(201);

		const id = created.body.id as string;

		await request(app.getHttpServer())
			.patch(`/v1/ubicaciones/${id}`)
			.set('Authorization', `Bearer ${adminToken}`)
			.send({ nombre: `${nombre}-EDIT` })
			.expect(200);

		await request(app.getHttpServer())
			.delete(`/v1/ubicaciones/${id}`)
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);
	});
});
