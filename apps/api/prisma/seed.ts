import { PrismaClient, SupervisaSolicitudesOt } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

type DerechoNode = {
	codigo: string;
	nombre: string;
	orden: number;
	children?: DerechoNode[];
};

const ARBOL_DERECHOS: DerechoNode[] = [
	{
		codigo: 'sistema',
		nombre: 'Sistema',
		orden: 1,
		children: [
			{
				codigo: 'archivos',
				nombre: 'Archivos',
				orden: 1,
				children: [
					{
						codigo: 'archivos.ubicaciones',
						nombre: 'Ubicaciones',
						orden: 1,
						children: crudLeaves('archivos.ubicaciones', [
							'agregar_nodo',
							'modificar_nodo',
							'borrar_nodo',
							'mover_nodo',
						]),
					},
					{
						codigo: 'archivos.equipos',
						nombre: 'Equipos',
						orden: 2,
						children: crudLeaves('archivos.equipos', [
							'agregar',
							'modificar',
							'borrar',
							'listar',
							'copiar',
							'mover',
							'marcar_fuera_de_servicio',
						]),
					},
					{
						codigo: 'archivos.tipos_equipo',
						nombre: 'Tipos de equipo',
						orden: 3,
						children: crudLeaves('archivos.tipos_equipo', [
							'agregar',
							'modificar',
							'borrar',
							'listar',
						]),
					},
					{
						codigo: 'archivos.procedimientos',
						nombre: 'Procedimientos',
						orden: 4,
						children: crudLeaves('archivos.procedimientos', [
							'agregar',
							'modificar',
							'borrar',
							'listar',
							'asociar_a_equipo',
						]),
					},
				],
			},
			{
				codigo: 'programacion',
				nombre: 'Programación',
				orden: 2,
				children: [
					{
						codigo: 'programacion.ordenes_trabajo',
						nombre: 'Órdenes de Trabajo',
						orden: 1,
						children: crudLeaves('programacion.ordenes_trabajo', [
							'emitir_periodica',
							'emitir_no_periodica',
							'buscar_y_actualizar',
							'anular',
							'reimprimir',
							'ver_reportes_estado',
							'ver_historico',
						]),
					},
					{
						codigo: 'programacion.solicitudes_trabajo',
						nombre: 'Solicitudes de Trabajo',
						orden: 2,
						children: crudLeaves('programacion.solicitudes_trabajo', [
							'agregar',
							'modificar',
							'listar',
							'dar_conformidad',
							'emitir_ot_desde_solicitud',
						]),
					},
				],
			},
			{
				codigo: 'stock',
				nombre: 'Stock',
				orden: 3,
				children: [
					{
						codigo: 'stock.pañol',
						nombre: 'Pañol',
						orden: 1,
						children: [
							{
								codigo: 'stock.pañol.solicitudes_materiales',
								nombre: 'Solicitudes de materiales',
								orden: 1,
								children: crudLeaves('stock.pañol.solicitudes_materiales', [
									'ver_pendientes',
									'aprobar',
									'rechazar',
									'ver_historico',
								]),
							},
							{
								codigo: 'stock.pañol.alertas_stock_minimo',
								nombre: 'Alertas stock mínimo',
								orden: 2,
								children: crudLeaves('stock.pañol.alertas_stock_minimo', [
									'ver',
									'configurar_minimo',
								]),
							},
						],
					},
					{
						codigo: 'stock.ordenes_compra',
						nombre: 'Órdenes de Compra',
						orden: 2,
						children: crudLeaves('stock.ordenes_compra', [
							'emitir',
							'buscar_y_actualizar',
							'anular',
						]),
					},
					{
						codigo: 'stock.materiales_en_stock',
						nombre: 'Materiales en stock',
						orden: 3,
						children: crudLeaves('stock.materiales_en_stock', ['ver', 'modificar_valores_gestion']),
					},
				],
			},
			{
				codigo: 'analisis',
				nombre: 'Análisis',
				orden: 4,
				children: [
					{
						codigo: 'analisis.trabajos',
						nombre: 'Trabajos',
						orden: 1,
						children: crudLeaves('analisis.trabajos', [
							'costos',
							'indices_gestion',
							'pareto_fallas',
						]),
					},
				],
			},
			{
				codigo: 'configuracion',
				nombre: 'Configuración',
				orden: 5,
				children: [
					{
						codigo: 'configuracion.usuarios',
						nombre: 'Usuarios',
						orden: 1,
						children: crudLeaves('configuracion.usuarios', [
							'agregar',
							'modificar',
							'borrar',
							'listar',
						]),
					},
					{
						codigo: 'configuracion.perfiles',
						nombre: 'Perfiles',
						orden: 2,
						children: crudLeaves('configuracion.perfiles', [
							'agregar',
							'modificar',
							'borrar',
							'listar',
							'definir_derechos',
							'asignar_usuarios',
						]),
					},
					{
						codigo: 'configuracion.sucursales',
						nombre: 'Sucursales',
						orden: 3,
						children: crudLeaves('configuracion.sucursales', [
							'agregar',
							'buscar',
							'borrar',
							'listar',
							'asignar_usuarios',
						]),
					},
				],
			},
		],
	},
];

function crudLeaves(prefix: string, actions: string[]): DerechoNode[] {
	return actions.map((action, index) => ({
		codigo: `${prefix}.${action}`,
		nombre: action.replace(/_/g, ' '),
		orden: index + 1,
	}));
}

async function seedDerechos(
	nodes: DerechoNode[],
	parentId: string | null = null,
	map: Map<string, string> = new Map(),
): Promise<Map<string, string>> {
	for (const node of nodes) {
		const derecho = await prisma.derecho.upsert({
			where: { codigo: node.codigo },
			update: {
				nombre: node.nombre,
				orden: node.orden,
				parentId,
			},
			create: {
				codigo: node.codigo,
				nombre: node.nombre,
				orden: node.orden,
				parentId,
			},
		});
		map.set(node.codigo, derecho.id);
		if (node.children?.length) {
			await seedDerechos(node.children, derecho.id, map);
		}
	}
	return map;
}

async function assignDerechos(
	perfilId: string,
	codigos: string[],
	derechoMap: Map<string, string>,
	modoTotal = false,
) {
	for (const codigo of codigos) {
		const derechoId = derechoMap.get(codigo);
		if (!derechoId) continue;
		await prisma.perfilDerecho.upsert({
			where: {
				perfilId_derechoId: { perfilId, derechoId },
			},
			update: { habilitado: true, modoTotal },
			create: { perfilId, derechoId, habilitado: true, modoTotal },
		});
	}
}

async function main() {
	const derechoMap = await seedDerechos(ARBOL_DERECHOS);

	const virrey = await prisma.sucursal.upsert({
		where: { codigo: 'VIRREY' },
		update: { nombre: 'PLANTA_VIRREY', activa: true },
		create: { nombre: 'PLANTA_VIRREY', codigo: 'VIRREY' },
	});

	const rosario = await prisma.sucursal.upsert({
		where: { codigo: 'ROSARIO' },
		update: { nombre: 'PLANTA_ROSARIO', activa: true },
		create: { nombre: 'PLANTA_ROSARIO', codigo: 'ROSARIO' },
	});

	const perfilTecnico = await prisma.perfil.upsert({
		where: { id: '11111111-1111-1111-1111-111111111111' },
		update: { nombre: 'Técnico', activo: true },
		create: {
			id: '11111111-1111-1111-1111-111111111111',
			nombre: 'Técnico',
			descripcion: 'Ejecuta OT asignadas',
		},
	});

	const perfilPanolero = await prisma.perfil.upsert({
		where: { id: '22222222-2222-2222-2222-222222222222' },
		update: { nombre: 'Pañolero', activo: true },
		create: {
			id: '22222222-2222-2222-2222-222222222222',
			nombre: 'Pañolero',
			descripcion: 'Gestiona stock y solicitudes de materiales',
		},
	});

	const perfilSupervisor = await prisma.perfil.upsert({
		where: { id: '33333333-3333-3333-3333-333333333333' },
		update: { nombre: 'Supervisor', activo: true },
		create: {
			id: '33333333-3333-3333-3333-333333333333',
			nombre: 'Supervisor',
			descripcion: 'Supervisa OT y solicitudes de su sucursal',
		},
	});

	const perfilAdminSucursal = await prisma.perfil.upsert({
		where: { id: '44444444-4444-4444-4444-444444444444' },
		update: { nombre: 'Admin Sucursal', activo: true },
		create: {
			id: '44444444-4444-4444-4444-444444444444',
			nombre: 'Admin Sucursal',
			descripcion: 'Administración de usuarios y configuración de sucursal',
		},
	});

	await assignDerechos(
		perfilTecnico.id,
		[
			'programacion.ordenes_trabajo.buscar_y_actualizar',
			'archivos.equipos.listar',
			'stock.pañol.solicitudes_materiales.ver_pendientes',
		],
		derechoMap,
	);

	await assignDerechos(
		perfilPanolero.id,
		['stock', 'stock.pañol', 'stock.materiales_en_stock'],
		derechoMap,
		true,
	);

	await assignDerechos(
		perfilSupervisor.id,
		['programacion', 'archivos'],
		derechoMap,
		true,
	);

	await assignDerechos(
		perfilAdminSucursal.id,
		['configuracion'],
		derechoMap,
		true,
	);

	const passwordHash = await bcrypt.hash('Sika123!', 10);

	await prisma.usuario.upsert({
		where: { nombreUsuario: 'admin' },
		update: {
			claveHash: passwordHash,
			esAdministrador: true,
			supervisaSucursales: true,
			sucursalId: virrey.id,
			activo: true,
		},
		create: {
			nombreUsuario: 'admin',
			claveHash: passwordHash,
			email: 'admin@sika.local',
			esAdministrador: true,
			supervisaSucursales: true,
			sucursalId: virrey.id,
		},
	});

	await prisma.usuario.upsert({
		where: { nombreUsuario: 'tecnico' },
		update: {
			claveHash: passwordHash,
			sucursalId: virrey.id,
			perfilId: perfilTecnico.id,
			activo: true,
		},
		create: {
			nombreUsuario: 'tecnico',
			claveHash: passwordHash,
			email: 'tecnico@sika.local',
			sucursalId: virrey.id,
			perfilId: perfilTecnico.id,
		},
	});

	await prisma.usuario.upsert({
		where: { nombreUsuario: 'panolero' },
		update: {
			claveHash: passwordHash,
			sucursalId: virrey.id,
			perfilId: perfilPanolero.id,
			activo: true,
		},
		create: {
			nombreUsuario: 'panolero',
			claveHash: passwordHash,
			email: 'panolero@sika.local',
			sucursalId: virrey.id,
			perfilId: perfilPanolero.id,
		},
	});

	await prisma.usuario.upsert({
		where: { nombreUsuario: 'supervisor' },
		update: {
			claveHash: passwordHash,
			sucursalId: virrey.id,
			perfilId: perfilSupervisor.id,
			supervisaSolicitudesOt: SupervisaSolicitudesOt.todas,
			activo: true,
		},
		create: {
			nombreUsuario: 'supervisor',
			claveHash: passwordHash,
			email: 'supervisor@sika.local',
			sucursalId: virrey.id,
			perfilId: perfilSupervisor.id,
			supervisaSolicitudesOt: SupervisaSolicitudesOt.todas,
		},
	});

	await prisma.usuario.upsert({
		where: { nombreUsuario: 'admin.virrey' },
		update: {
			claveHash: passwordHash,
			sucursalId: virrey.id,
			perfilId: perfilAdminSucursal.id,
			activo: true,
		},
		create: {
			nombreUsuario: 'admin.virrey',
			claveHash: passwordHash,
			email: 'admin.virrey@sika.local',
			sucursalId: virrey.id,
			perfilId: perfilAdminSucursal.id,
		},
	});

	// Tipos genéricos (sin datos de planta precargados)
	await prisma.tipoEquipo.upsert({
		where: { id: '55555555-5555-5555-5555-555555555501' },
		update: { nombre: 'Máquina', activo: true },
		create: {
			id: '55555555-5555-5555-5555-555555555501',
			nombre: 'Máquina',
			camposDetalle: [],
			camposLectura: [{ key: 'horas', label: 'Horas de operación' }],
		},
	});

	await prisma.tipoEquipo.upsert({
		where: { id: '55555555-5555-5555-5555-555555555502' },
		update: { nombre: 'Instalación', activo: true },
		create: {
			id: '55555555-5555-5555-5555-555555555502',
			nombre: 'Instalación',
			camposDetalle: [],
			camposLectura: [],
		},
	});

	// Planta vacía: solo SIKA → PLANTA_VIRREY. El usuario crea ubicaciones/sectores/máquinas.
	await prisma.lectura.deleteMany({
		where: { equipo: { sucursalId: virrey.id } },
	});
	await prisma.equipo.deleteMany({ where: { sucursalId: virrey.id } });
	await prisma.ubicacion.deleteMany({ where: { sucursalId: virrey.id } });
	await prisma.lectura.deleteMany({
		where: { equipo: { sucursalId: rosario.id } },
	});
	await prisma.equipo.deleteMany({ where: { sucursalId: rosario.id } });
	await prisma.ubicacion.deleteMany({ where: { sucursalId: rosario.id } });

	console.log('Seed M1 + M2 completado');
	console.log(`Sucursales: ${virrey.codigo}, ${rosario.codigo}`);
	console.log('Usuarios demo (clave: Sika123!): admin, tecnico, panolero, supervisor, admin.virrey');
	console.log('Árbol planta vacío: SIKA → PLANTA_VIRREY (crear ubicaciones desde la app)');
}

main()
	.catch((error) => {
		console.error(error);
		process.exit(1);
	})
	.finally(async () => {
		await prisma.$disconnect();
	});
