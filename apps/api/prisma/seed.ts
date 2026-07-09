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
							'reabrir',
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

async function seedMotivosOtPendiente(sucursalId: string) {
	const motivos = [
		{ codigo: 'FALTA_MATERIAL', descripcion: 'Falta de material', orden: 1 },
		{ codigo: 'FALTA_PERSONAL', descripcion: 'Falta de personal', orden: 2 },
		{ codigo: 'MAQUINA_EN_USO', descripcion: 'Máquina en uso', orden: 3 },
		{ codigo: 'CLIMA', descripcion: 'Condiciones climáticas', orden: 4 },
		{ codigo: 'OTRO', descripcion: 'Otro motivo', orden: 5 },
	];

	for (const motivo of motivos) {
		await prisma.motivoOtPendiente.upsert({
			where: {
				sucursalId_codigo: { sucursalId, codigo: motivo.codigo },
			},
			update: {
				descripcion: motivo.descripcion,
				orden: motivo.orden,
				activo: true,
			},
			create: {
				sucursalId,
				codigo: motivo.codigo,
				descripcion: motivo.descripcion,
				orden: motivo.orden,
			},
		});
	}
}

async function main() {
	await prisma.$executeRaw`SELECT set_config('app.bypass_rls', 'true', true)`;

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

	await seedMotivosOtPendiente(virrey.id);
	await seedMotivosOtPendiente(rosario.id);

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
		['configuracion', 'archivos', 'programacion'],
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

	// Demo planta Virrey + M3
	await prisma.historialEquipo.deleteMany({
		where: { equipo: { sucursalId: virrey.id } },
	});
	await prisma.otEstadoHistorial.deleteMany({
		where: { ot: { sucursalId: virrey.id } },
	});
	await prisma.solicitudTrabajo.deleteMany({ where: { sucursalId: virrey.id } });
	await prisma.ordenTrabajo.deleteMany({ where: { sucursalId: virrey.id } });
	await prisma.procedimientoEquipo.deleteMany({
		where: { procedimiento: { sucursalId: virrey.id } },
	});
	await prisma.procedimiento.deleteMany({ where: { sucursalId: virrey.id } });
	await prisma.lectura.deleteMany({
		where: { equipo: { sucursalId: virrey.id } },
	});
	await prisma.equipo.deleteMany({ where: { sucursalId: virrey.id } });
	await prisma.ubicacion.deleteMany({ where: { sucursalId: virrey.id } });

	const tecnico = await prisma.usuario.findUnique({
		where: { nombreUsuario: 'tecnico' },
	});
	const supervisor = await prisma.usuario.findUnique({
		where: { nombreUsuario: 'supervisor' },
	});

	const silosExternos = await prisma.ubicacion.create({
		data: {
			id: '66666666-6666-6666-6666-666666666601',
			sucursalId: virrey.id,
			nombre: 'Silos Externos',
			orden: 1,
		},
	});

	const sectorLosa = await prisma.ubicacion.create({
		data: {
			id: '66666666-6666-6666-6666-666666666602',
			sucursalId: virrey.id,
			parentId: silosExternos.id,
			nombre: 'Sector Losa',
			orden: 1,
		},
	});

	const molienda = await prisma.ubicacion.create({
		data: {
			id: '66666666-6666-6666-6666-666666666603',
			sucursalId: virrey.id,
			nombre: 'Molienda',
			orden: 2,
		},
	});

	const silo103 = await prisma.equipo.create({
		data: {
			id: '66666666-6666-6666-6666-666666666611',
			sucursalId: virrey.id,
			ubicacionId: sectorLosa.id,
			tipoEquipoId: '55555555-5555-5555-5555-555555555501',
			nombre: 'Silo 103',
			codigo: 'SILO-103',
			detalle: { capacidad: '120 m³' },
		},
	});

	const silo104 = await prisma.equipo.create({
		data: {
			id: '66666666-6666-6666-6666-666666666612',
			sucursalId: virrey.id,
			ubicacionId: sectorLosa.id,
			tipoEquipoId: '55555555-5555-5555-5555-555555555501',
			nombre: 'Silo 104',
			codigo: 'SILO-104',
			detalle: { capacidad: '120 m³' },
		},
	});

	const mol01 = await prisma.equipo.create({
		data: {
			id: '66666666-6666-6666-6666-666666666613',
			sucursalId: virrey.id,
			ubicacionId: molienda.id,
			tipoEquipoId: '55555555-5555-5555-5555-555555555501',
			nombre: 'Molino 01',
			codigo: 'MOL-01',
			detalle: { potencia: '250 kW' },
		},
	});

	const procLubricacion = await prisma.procedimiento.create({
		data: {
			id: '77777777-7777-7777-7777-777777777701',
			codigo: 1000,
			sucursalId: virrey.id,
			sectorResponsableId: molienda.id,
			nombre: 'Lubricación preventiva silo',
			tipo: 'preventivo',
			descripcion: 'Engrase de rodamientos y revisión de niveles',
			planillaLecturas: [
				{ key: 'inspeccion_visual', label: 'Inspección visual', done: false },
				{ key: 'engrase', label: 'Puntos de engrase', done: false },
				{ key: 'horas', label: 'Registrar horas', done: false },
			],
			periodicidadTipo: 'tiempo',
			periodicidadValor: 30,
			criterioProgramacion: 'fecha_finalizacion',
			tolerancia: 5,
			duracionEstimada: 180,
			hsHombre: 3,
			cantOperarios: 1,
			indisponibilidadEstimada: 60,
			costoEstimado: 0,
		},
	});

	const procCorrectivo = await prisma.procedimiento.create({
		data: {
			id: '77777777-7777-7777-7777-777777777702',
			codigo: 1001,
			sucursalId: virrey.id,
			sectorResponsableId: molienda.id,
			nombre: 'Revisión correctiva molienda',
			tipo: 'correctivo',
			descripcion: 'Diagnóstico por vibración anormal',
			planillaLecturas: [
				{ key: 'vibracion', label: 'Medir vibración', done: false },
				{ key: 'temperatura', label: 'Temperatura rodamientos', done: false },
			],
			duracionEstimada: 240,
			hsHombre: 4,
			cantOperarios: 2,
			indisponibilidadEstimada: 120,
		},
	});

	await prisma.procedimientoEquipo.createMany({
		data: [
			{ procedimientoId: procLubricacion.id, equipoId: silo103.id },
			{ procedimientoId: procLubricacion.id, equipoId: silo104.id },
			{ procedimientoId: procCorrectivo.id, equipoId: mol01.id },
		],
	});

	const hoy = new Date();
	const ayer = new Date(hoy);
	ayer.setDate(ayer.getDate() - 1);

	const hace40Dias = new Date(hoy);
	hace40Dias.setDate(hace40Dias.getDate() - 40);
	const hace41Dias = new Date(hoy);
	hace41Dias.setDate(hace41Dias.getDate() - 41);

	const otPendiente = await prisma.ordenTrabajo.create({
		data: {
			id: '88888888-8888-8888-8888-888888888801',
			numero: 1001,
			sucursalId: virrey.id,
			ubicacionId: sectorLosa.id,
			equipoId: silo103.id,
			procedimientoId: procLubricacion.id,
			tipo: 'preventivo',
			estado: 'pendiente',
			tecnicoAsignadoId: tecnico?.id,
			creadorId: supervisor?.id,
			fechaProgramacion: hoy,
			prioridad: 'media',
			comentarios: 'Mantenimiento mensual programado',
			historialEstados: {
				create: [
					{
						estado: 'pendiente',
						usuarioId: supervisor?.id,
						comentario: 'OT emitida',
					},
				],
			},
		},
	});

	const otEnEjecucion = await prisma.ordenTrabajo.create({
		data: {
			id: '88888888-8888-8888-8888-888888888802',
			numero: 1002,
			sucursalId: virrey.id,
			ubicacionId: molienda.id,
			equipoId: mol01.id,
			procedimientoId: procCorrectivo.id,
			tipo: 'correctivo',
			estado: 'en_ejecucion',
			tecnicoAsignadoId: tecnico?.id,
			creadorId: supervisor?.id,
			fechaProgramacion: ayer,
			prioridad: 'alta',
			comentarios: 'Vibración detectada en turno noche',
			historialEstados: {
				create: [
					{
						estado: 'pendiente',
						usuarioId: supervisor?.id,
						comentario: 'OT emitida',
					},
					{
						estado: 'en_ejecucion',
						usuarioId: tecnico?.id,
						comentario: 'Técnico inició ejecución',
					},
				],
			},
		},
	});

	const hace5Dias = new Date(hoy);
	hace5Dias.setDate(hace5Dias.getDate() - 5);
	const hace3Dias = new Date(hoy);
	hace3Dias.setDate(hace3Dias.getDate() - 3);

	await prisma.ordenTrabajo.create({
		data: {
			id: '88888888-8888-8888-8888-888888888803',
			numero: 1003,
			sucursalId: virrey.id,
			ubicacionId: sectorLosa.id,
			equipoId: silo104.id,
			procedimientoId: procLubricacion.id,
			tipo: 'preventivo',
			estado: 'realizada',
			tecnicoAsignadoId: tecnico?.id,
			creadorId: supervisor?.id,
			fechaProgramacion: hace5Dias,
			fechaEjecucion: hace3Dias,
			prioridad: 'baja',
			firmaDigital: 'demo-firma-base64',
			historialEstados: {
				create: [
					{
						estado: 'pendiente',
						usuarioId: supervisor?.id,
						comentario: 'OT emitida',
					},
					{
						estado: 'en_ejecucion',
						usuarioId: tecnico?.id,
						comentario: 'Inicio de trabajo',
					},
					{
						estado: 'realizada',
						usuarioId: tecnico?.id,
						comentario: 'OT cerrada con firma',
					},
				],
			},
		},
	});

	await prisma.historialEquipo.createMany({
		data: [
			{
				equipoId: silo103.id,
				otId: otPendiente.id,
				tipoEvento: 'ot_emitida',
				descripcion: 'OT #1001 emitida',
				usuarioId: supervisor?.id,
			},
			{
				equipoId: mol01.id,
				otId: otEnEjecucion.id,
				tipoEvento: 'ot_emitida',
				descripcion: 'OT #1002 emitida',
				usuarioId: supervisor?.id,
			},
		],
	});

	await prisma.solicitudTrabajo.create({
		data: {
			id: '99999999-9999-9999-9999-999999999901',
			sucursalId: virrey.id,
			solicitante: 'Operador turno mañana',
			descripcion: 'Ruido anormal en cinta de alimentación del silo 103',
			urgente: true,
			estado: 'pendiente',
		},
	});

	await prisma.solicitudTrabajo.create({
		data: {
			id: '99999999-9999-9999-9999-999999999902',
			sucursalId: virrey.id,
			solicitante: 'Jefe de planta',
			descripcion: 'Revisión de filtros en molienda',
			urgente: false,
			estado: 'conformada',
		},
	});

	// Rosario vacío
	await prisma.historialEquipo.deleteMany({
		where: { equipo: { sucursalId: rosario.id } },
	});
	await prisma.otEstadoHistorial.deleteMany({
		where: { ot: { sucursalId: rosario.id } },
	});
	await prisma.solicitudTrabajo.deleteMany({ where: { sucursalId: rosario.id } });
	await prisma.ordenTrabajo.deleteMany({ where: { sucursalId: rosario.id } });
	await prisma.procedimientoEquipo.deleteMany({
		where: { procedimiento: { sucursalId: rosario.id } },
	});
	await prisma.procedimiento.deleteMany({ where: { sucursalId: rosario.id } });
	await prisma.lectura.deleteMany({
		where: { equipo: { sucursalId: rosario.id } },
	});
	await prisma.equipo.deleteMany({ where: { sucursalId: rosario.id } });
	await prisma.ubicacion.deleteMany({ where: { sucursalId: rosario.id } });

	console.log('Seed M1 + M2 + M3 completado');
	console.log(`Sucursales: ${virrey.codigo}, ${rosario.codigo}`);
	console.log('Usuarios demo (clave: Sika123!): admin, tecnico, panolero, supervisor, admin.virrey');
	console.log('Demo Virrey: Silos Externos → Sector Losa → SILO-103/104, Molienda → MOL-01');
	console.log('Demo OT: #1001 pendiente, #1002 en ejecución, #1003 realizada');
}

main()
	.catch((error) => {
		console.error(error);
		process.exit(1);
	})
	.finally(async () => {
		await prisma.$disconnect();
	});
