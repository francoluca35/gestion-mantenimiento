import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';

async function login(
	app: INestApplication<App>,
	usuario: string,
	clave = 'Sika123!',
) {
	const res = await request(app.getHttpServer())
		.post('/v1/auth/login')
		.send({ nombreUsuario: usuario, clave })
		.expect(201);

	return res.body.accessToken as string;
}

describe('Auth y seguridad (e2e)', () => {
	let app: INestApplication<App>;

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
	});

	afterAll(async () => {
		await app.close();
	});

	it('login y /auth/me', async () => {
		const token = await login(app, 'admin');

		const me = await request(app.getHttpServer())
			.get('/v1/auth/me')
			.set('Authorization', `Bearer ${token}`)
			.expect(200);

		expect(me.body.nombreUsuario).toBe('admin');
		expect(me.body.esAdministrador).toBe(true);
		expect(Array.isArray(me.body.derechos)).toBe(true);
	});

	it('técnico no puede listar usuarios', async () => {
		const token = await login(app, 'tecnico');

		await request(app.getHttpServer())
			.get('/v1/usuarios')
			.set('Authorization', `Bearer ${token}`)
			.expect(403);
	});

	it('admin puede listar usuarios', async () => {
		const token = await login(app, 'admin');

		const res = await request(app.getHttpServer())
			.get('/v1/usuarios')
			.set('Authorization', `Bearer ${token}`)
			.expect(200);

		expect(Array.isArray(res.body)).toBe(true);
		expect(res.body.length).toBeGreaterThan(0);
	});

	it('aislamiento por sucursal (RLS + servicio)', async () => {
		const adminToken = await login(app, 'admin');
		const virreyToken = await login(app, 'admin.virrey');

		const sucursales = await request(app.getHttpServer())
			.get('/v1/sucursales')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		const rosario = (sucursales.body as Array<{ codigo: string; id: string }>).find(
			(s) => s.codigo === 'ROSARIO',
		);
		expect(rosario).toBeDefined();

		const usuarioRosario = `test.rosario.${Date.now()}`;
		await request(app.getHttpServer())
			.post('/v1/usuarios')
			.set('Authorization', `Bearer ${adminToken}`)
			.send({
				nombreUsuario: usuarioRosario,
				clave: 'Sika123!',
				sucursalId: rosario!.id,
			})
			.expect(201);

		const listaVirrey = await request(app.getHttpServer())
			.get('/v1/usuarios')
			.set('Authorization', `Bearer ${virreyToken}`)
			.expect(200);

		const nombres = (listaVirrey.body as Array<{ nombreUsuario: string }>).map(
			(u) => u.nombreUsuario,
		);
		expect(nombres).not.toContain(usuarioRosario);
	});

	it('cambio de clave revoca sesiones', async () => {
		const usuario = `clave.test.${Date.now()}`;
		const adminToken = await login(app, 'admin');

		const sucursales = await request(app.getHttpServer())
			.get('/v1/sucursales')
			.set('Authorization', `Bearer ${adminToken}`)
			.expect(200);

		const virrey = (sucursales.body as Array<{ codigo: string; id: string }>).find(
			(s) => s.codigo === 'VIRREY',
		);

		await request(app.getHttpServer())
			.post('/v1/usuarios')
			.set('Authorization', `Bearer ${adminToken}`)
			.send({
				nombreUsuario: usuario,
				clave: 'Sika123!',
				sucursalId: virrey!.id,
			})
			.expect(201);

		const token1 = await login(app, usuario);
		await login(app, usuario);

		await request(app.getHttpServer())
			.patch('/v1/auth/clave')
			.set('Authorization', `Bearer ${token1}`)
			.send({ claveActual: 'Sika123!', claveNueva: 'NuevaSika123!' })
			.expect(200);

		const tokenNuevo = await login(app, usuario, 'NuevaSika123!');
		const sesiones = await request(app.getHttpServer())
			.get('/v1/auth/sesiones')
			.set('Authorization', `Bearer ${tokenNuevo}`)
			.expect(200);

		expect(Array.isArray(sesiones.body)).toBe(true);
		const revocadas = (sesiones.body as Array<{ revocada: boolean }>).filter(
			(s) => s.revocada,
		);
		expect(revocadas.length).toBeGreaterThanOrEqual(2);
	});

	it('GET /derechos/tree autenticado', async () => {
		const token = await login(app, 'supervisor');

		const res = await request(app.getHttpServer())
			.get('/v1/derechos/tree')
			.set('Authorization', `Bearer ${token}`)
			.expect(200);

		expect(Array.isArray(res.body)).toBe(true);
		expect(res.body.length).toBeGreaterThan(0);
	});
});
