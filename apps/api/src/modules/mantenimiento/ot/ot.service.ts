import {
	BadRequestException,
	ForbiddenException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { EstadoOt, EstadoPedidoStock, EstadoSolicitudMaterial, Prisma, TipoMantenimiento } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { PushService } from '../../notificaciones/push.service';
import { StockService } from '../../panol/stock/stock.service';
import { assertSucursalAccess, resolveSucursalId } from '../mantenimiento.scope';
import { AnularOtDto } from './dto/anular-ot.dto';
import { AsignarOtDto } from './dto/asignar-ot.dto';
import { CambiarEstadoOtDto } from './dto/cambiar-estado-ot.dto';
import { CompletarChecklistDto } from './dto/completar-checklist.dto';
import { DerivarOtDto } from './dto/derivar-ot.dto';
import { EmitirOtDto } from './dto/emitir-ot.dto';
import { EmitirOtPeriodicaDto } from './dto/emitir-ot-periodica.dto';
import { EmitirOtNecesariasDto } from './dto/emitir-ot-necesarias.dto';
import {
	AnalizarMaterialesOtDto,
	ConfirmarMaterialesOtDto,
	DecidirSinMaterialesOtDto,
	RegistrarLecturaOtDto,
} from './dto/preparacion-ot.dto';
import { RegistrarFirmaDto } from './dto/registrar-firma.dto';
import { ReabrirOtDto } from './dto/reabrir-ot.dto';
import {
	AgrupadoGraficos,
	EjeXGraficos,
	EjeYGraficos,
	GraficosOtDto,
} from './dto/graficos-ot.dto';
import {
	matchMaterialesContraStock,
	type StockCandidate,
} from './material-match.util';
import { renderOtPdfHtml, type OtPdfData } from './ot-pdf.template';

const TRANSICIONES: Record<EstadoOt, EstadoOt[]> = {
	necesaria_de_emitir: ['pendiente', 'anulada'],
	pendiente: ['en_ejecucion', 'pendiente_panol', 'anulada', 'realizada'],
	// Solo el pañol (aprobar/completar) libera a pendiente; no saltar a ejecución.
	pendiente_panol: ['pendiente', 'anulada'],
	en_ejecucion: ['realizada', 'anulada'],
	realizada: [],
	anulada: [],
};

@Injectable()
export class OtService {
	constructor(
		private readonly prisma: PrismaService,
		private readonly push: PushService,
		private readonly stockService: StockService,
	) {}

	private otInclude() {
		return {
			equipo: { include: { ubicacion: true, tipoEquipo: true } },
			ubicacion: true,
			procedimiento: true,
			tecnicoAsignado: {
				select: {
					id: true,
					nombreUsuario: true,
					email: true,
				},
			},
			creador: {
				select: {
					id: true,
					nombreUsuario: true,
				},
			},
			historialEstados: {
				orderBy: { createdAt: 'asc' as const },
				include: {
					usuario: {
						select: { id: true, nombreUsuario: true },
					},
				},
			},
			motivoPendiente: {
				select: { id: true, codigo: true, descripcion: true },
			},
			otOrigen: {
				select: { id: true, numero: true, estado: true },
			},
			otsDerivadas: {
				select: { id: true, numero: true, estado: true, createdAt: true },
				orderBy: { numero: 'asc' as const },
			},
			lecturas: {
				orderBy: { fecha: 'desc' as const },
				take: 5,
				include: {
					usuario: { select: { id: true, nombreUsuario: true } },
				},
			},
		};
	}

	private puedeVerTodasLasOt(user: AuthUser) {
		return (
			user.esAdministrador ||
			user.supervisaSucursales ||
			user.derechos.includes('programacion.ordenes_trabajo.emitir_no_periodica') ||
			user.derechos.includes('programacion.ordenes_trabajo.emitir_periodica')
		);
	}

	private assertPuedeReabrir(user: AuthUser) {
		if (user.esAdministrador || user.supervisaSucursales) return;
		if (user.derechos.includes('programacion.ordenes_trabajo.reabrir')) return;
		throw new ForbiddenException('No tenés permiso para reabrir OT');
	}

	private assertPuedeOperarOt(ot: { tecnicoAsignadoId: string | null }, user: AuthUser) {
		if (this.puedeVerTodasLasOt(user)) return;

		if (ot.tecnicoAsignadoId !== user.id) {
			throw new ForbiddenException('Solo podés operar OT asignadas a vos');
		}
	}

	private assertPreparacionOt(ot: {
		lecturaRegistradaAt: Date | null;
		decisionMateriales: string;
	}) {
		if (!ot.lecturaRegistradaAt) {
			throw new BadRequestException(
				'Primero registrá la lectura del equipo antes de continuar la OT',
			);
		}
		if (ot.decisionMateriales === 'pendiente') {
			throw new BadRequestException(
				'Indicá si necesitás materiales o no antes de ejecutar la OT',
			);
		}
	}

	private startOfDay(date: Date): Date {
		const parsed = new Date(date);
		parsed.setHours(0, 0, 0, 0);
		return parsed;
	}

	private addDays(date: Date, days: number): Date {
		const parsed = this.startOfDay(date);
		parsed.setDate(parsed.getDate() + days);
		return parsed;
	}

	private toDateOnlyString(date: Date): string {
		return date.toISOString().slice(0, 10);
	}

	async listarNecesarias(
		currentUser: AuthUser,
		filters: {
			sucursalId?: string;
			necesariasAl?: string;
			equipoId?: string;
			sectorResponsableId?: string;
			tipoProcedimiento?: string;
			tipoEquipoId?: string;
		},
	) {
		const sucursalId = resolveSucursalId(currentUser, filters.sucursalId);
		const necesariasAl =
			this.parseFecha(filters.necesariasAl, true) ?? this.startOfDay(new Date());

		const asociacionesTiempo = await this.prisma.procedimientoEquipo.findMany({
			where: {
				estado: 'activo',
				equipo: {
					activo: true,
					fueraDeServicio: false,
					sucursalId,
					id: filters.equipoId,
					tipoEquipoId: filters.tipoEquipoId,
				},
				procedimiento: {
					activo: true,
					tipo: 'preventivo',
					periodicidadTipo: 'tiempo',
					periodicidadValor: { not: null },
					sectorResponsableId: filters.sectorResponsableId,
				},
			},
			include: {
				procedimiento: { include: { sectorResponsable: true } },
				equipo: { include: { ubicacion: true, tipoEquipo: true } },
			},
			orderBy: [{ procedimiento: { codigo: 'asc' } }, { equipo: { codigo: 'asc' } }],
		});

		const asociacionesContador = await this.prisma.procedimientoEquipo.findMany({
			where: {
				estado: 'activo',
				equipo: {
					activo: true,
					fueraDeServicio: false,
					sucursalId,
					id: filters.equipoId,
					tipoEquipoId: filters.tipoEquipoId,
				},
				procedimiento: {
					activo: true,
					tipo: 'preventivo',
					periodicidadTipo: 'contador',
					periodicidadValor: { not: null },
					sectorResponsableId: filters.sectorResponsableId,
				},
			},
			include: {
				procedimiento: { include: { sectorResponsable: true } },
				equipo: { include: { ubicacion: true, tipoEquipo: true } },
			},
			orderBy: [{ procedimiento: { codigo: 'asc' } }, { equipo: { codigo: 'asc' } }],
		});

		const items = [];
		for (const asociacion of asociacionesTiempo) {
			const item = await this.evaluarOtNecesaria(asociacion, necesariasAl);
			if (item) items.push(item);
		}
		for (const asociacion of asociacionesContador) {
			const item = await this.evaluarOtNecesariaContador(asociacion);
			if (item) items.push(item);
		}

		return {
			necesariasAl: this.toDateOnlyString(necesariasAl),
			total: items.length,
			items,
		};
	}

	private async evaluarOtNecesaria(
		asociacion: {
			id: string;
			fechaAsociacion: Date;
			ultimaEmision: Date | null;
			procedimientoId: string;
			equipoId: string;
			procedimiento: {
				id: string;
				codigo: number;
				nombre: string;
				tipo: TipoMantenimiento;
				periodicidadValor: number | null;
				criterioProgramacion: string | null;
				tolerancia: number;
				sectorResponsable: { id: string; nombre: string } | null;
			};
			equipo: {
				id: string;
				nombre: string;
				codigo: string;
				ubicacion: { id: string; nombre: string };
				tipoEquipo: { id: string; nombre: string };
			};
		},
		necesariasAl: Date,
	) {
		const procedimiento = asociacion.procedimiento;
		const periodicidadValor = procedimiento.periodicidadValor;
		if (!periodicidadValor) return null;

		const otAbierta = await this.prisma.ordenTrabajo.findFirst({
			where: {
				procedimientoId: procedimiento.id,
				equipoId: asociacion.equipoId,
				estado: {
					in: [
						'necesaria_de_emitir',
						'pendiente',
						'pendiente_panol',
						'en_ejecucion',
					],
				},
			},
			select: { id: true, numero: true, estado: true },
		});

		if (otAbierta) return null;

		const historialOt = await this.prisma.ordenTrabajo.findFirst({
			where: {
				procedimientoId: procedimiento.id,
				equipoId: asociacion.equipoId,
				estado: { not: 'anulada' },
			},
			select: { id: true },
		});

		let fechaNecesaria: Date;

		if (!historialOt) {
			fechaNecesaria = this.startOfDay(asociacion.fechaAsociacion);
		} else {
			let fechaReferencia: Date;

			if (procedimiento.criterioProgramacion === 'fecha_finalizacion') {
				const ultimaRealizada = await this.prisma.ordenTrabajo.findFirst({
					where: {
						procedimientoId: procedimiento.id,
						equipoId: asociacion.equipoId,
						estado: 'realizada',
					},
					orderBy: { fechaEjecucion: 'desc' },
				});

				fechaReferencia = ultimaRealizada?.fechaEjecucion
					? this.startOfDay(ultimaRealizada.fechaEjecucion)
					: this.startOfDay(asociacion.fechaAsociacion);
			} else if (asociacion.ultimaEmision) {
				fechaReferencia = this.startOfDay(asociacion.ultimaEmision);
			} else {
				const ultimaEmitida = await this.prisma.ordenTrabajo.findFirst({
					where: {
						procedimientoId: procedimiento.id,
						equipoId: asociacion.equipoId,
						estado: { not: 'anulada' },
					},
					orderBy: { fechaProgramacion: 'desc' },
				});

				fechaReferencia = ultimaEmitida
					? this.startOfDay(ultimaEmitida.fechaProgramacion)
					: this.startOfDay(asociacion.fechaAsociacion);
			}

			fechaNecesaria = this.addDays(fechaReferencia, periodicidadValor);
		}
		if (fechaNecesaria > necesariasAl) return null;

		const diasAtraso = Math.max(
			0,
			Math.floor(
				(necesariasAl.getTime() - fechaNecesaria.getTime()) / 86_400_000,
			),
		);

		return {
			asociacionId: asociacion.id,
			procedimientoId: procedimiento.id,
			procedimientoCodigo: procedimiento.codigo,
			procedimientoNombre: procedimiento.nombre,
			procedimientoTipo: procedimiento.tipo,
			periodicidadDias: periodicidadValor,
			periodicidadTipo: 'tiempo',
			tolerancia: procedimiento.tolerancia,
			criterioProgramacion: procedimiento.criterioProgramacion,
			esPrimeraEmision: !historialOt,
			fechaNecesaria: this.toDateOnlyString(fechaNecesaria),
			diasAtraso,
			equipo: asociacion.equipo,
			sectorResponsable: procedimiento.sectorResponsable,
		};
	}

	private lecturaTipoFromProcedimiento(procedimiento: { planillaLecturas: unknown }): string {
		const planilla = procedimiento.planillaLecturas;
		if (Array.isArray(planilla) && planilla.length > 0) {
			const first = planilla[0] as { key?: string };
			if (first?.key) return first.key;
		}
		return 'horas';
	}

	private async evaluarOtNecesariaContador(
		asociacion: {
			id: string;
			equipoId: string;
			procedimiento: {
				id: string;
				codigo: number;
				nombre: string;
				tipo: TipoMantenimiento;
				periodicidadValor: number | null;
				tolerancia: number;
				planillaLecturas: unknown;
				sectorResponsable: { id: string; nombre: string } | null;
			};
			equipo: {
				id: string;
				nombre: string;
				codigo: string;
				ubicacion: { id: string; nombre: string };
				tipoEquipo: { id: string; nombre: string };
			};
		},
	) {
		const procedimiento = asociacion.procedimiento;
		const umbral = procedimiento.periodicidadValor;
		if (!umbral) return null;

		const otAbierta = await this.prisma.ordenTrabajo.findFirst({
			where: {
				procedimientoId: procedimiento.id,
				equipoId: asociacion.equipoId,
				estado: {
					in: [
						'necesaria_de_emitir',
						'pendiente',
						'pendiente_panol',
						'en_ejecucion',
					],
				},
			},
			select: { id: true },
		});
		if (otAbierta) return null;

		const tipoLectura = this.lecturaTipoFromProcedimiento(procedimiento);
		const ultimaLectura = await this.prisma.lectura.findFirst({
			where: { equipoId: asociacion.equipoId, tipo: tipoLectura },
			orderBy: { fecha: 'desc' },
		});
		if (!ultimaLectura) return null;

		const ultimaRealizada = await this.prisma.ordenTrabajo.findFirst({
			where: {
				procedimientoId: procedimiento.id,
				equipoId: asociacion.equipoId,
				estado: 'realizada',
			},
			orderBy: { fechaEjecucion: 'desc' },
		});

		let valorReferencia = 0;
		if (ultimaRealizada?.fechaEjecucion) {
			const lecturaRef = await this.prisma.lectura.findFirst({
				where: {
					equipoId: asociacion.equipoId,
					tipo: tipoLectura,
					fecha: { lte: ultimaRealizada.fechaEjecucion },
				},
				orderBy: { fecha: 'desc' },
			});
			valorReferencia = lecturaRef ? Number(lecturaRef.valor) : 0;
		}

		const actual = Number(ultimaLectura.valor);
		const delta = actual - valorReferencia;
		if (delta < umbral) return null;

		return {
			asociacionId: asociacion.id,
			procedimientoId: procedimiento.id,
			procedimientoCodigo: procedimiento.codigo,
			procedimientoNombre: procedimiento.nombre,
			procedimientoTipo: procedimiento.tipo,
			periodicidadDias: umbral,
			periodicidadTipo: 'contador',
			tolerancia: procedimiento.tolerancia,
			criterioProgramacion: null,
			esPrimeraEmision: !ultimaRealizada,
			fechaNecesaria: this.toDateOnlyString(new Date()),
			diasAtraso: 0,
			lecturaActual: actual,
			lecturaDelta: delta,
			lecturaUmbral: umbral,
			equipo: asociacion.equipo,
			sectorResponsable: procedimiento.sectorResponsable,
		};
	}

	async emitirNecesarias(dto: EmitirOtNecesariasDto, currentUser: AuthUser) {
		const sucursalId = resolveSucursalId(currentUser, dto.sucursalId);
		const emitidas = [];
		/** tecnicoId → números OT a notificar (resumen por técnico). */
		const pushPorTecnico = new Map<string, number[]>();

		for (const item of dto.items) {
			const necesarias = await this.listarNecesarias(currentUser, {
				sucursalId,
				necesariasAl: item.fechaProgramacion,
			});

			const valida = necesarias.items.find(
				(candidata) =>
					candidata.procedimientoId === item.procedimientoId &&
					candidata.equipo.id === item.equipoId,
			);

			if (!valida) {
				throw new BadRequestException(
					`La combinación procedimiento/equipo no está necesaria de emitir: ${item.procedimientoId}`,
				);
			}

			const ot = await this.emitirPeriodica(
				{
					sucursalId,
					procedimientoId: item.procedimientoId,
					equipoId: item.equipoId,
					tecnicoAsignadoId: item.tecnicoAsignadoId,
					fechaProgramacion: item.fechaProgramacion,
					prioridad: item.prioridad,
					comentarios: `OT necesaria — ${valida.procedimientoNombre}`,
					// Diferimos push al final del lote para no spamear
					notificarAsignacion: false,
				},
				currentUser,
			);

			emitidas.push(ot);

			if (
				item.tecnicoAsignadoId &&
				item.notificarAsignacion !== false &&
				typeof ot.numero === 'number'
			) {
				const list = pushPorTecnico.get(item.tecnicoAsignadoId) ?? [];
				list.push(ot.numero);
				pushPorTecnico.set(item.tecnicoAsignadoId, list);
			}
		}

		for (const [tecnicoId, numeros] of pushPorTecnico) {
			await this.push.notifyOtAsignadas(tecnicoId, numeros);
		}

		return {
			total: emitidas.length,
			ordenes: emitidas,
		};
	}

	private async actualizarUltimaEmision(
		procedimientoId: string | null | undefined,
		equipoId: string,
		fecha: Date,
	) {
		if (!procedimientoId) return;

		await this.prisma.procedimientoEquipo.updateMany({
			where: {
				procedimientoId,
				equipoId,
				estado: 'activo',
			},
			data: {
				ultimaEmision: this.startOfDay(fecha),
			},
		});
	}

	async getTecnicosDisponibles(currentUser: AuthUser, sucursalIdQuery?: string) {
		const sucursalId = resolveSucursalId(currentUser, sucursalIdQuery);

		return this.prisma.usuario.findMany({
			where: {
				sucursalId,
				activo: true,
				perfil: {
					derechos: {
						some: {
							habilitado: true,
							derecho: {
								codigo: 'programacion.ordenes_trabajo.buscar_y_actualizar',
							},
						},
					},
				},
			},
			select: {
				id: true,
				nombreUsuario: true,
				email: true,
			},
			orderBy: { nombreUsuario: 'asc' },
		});
	}

	private parseFecha(fecha?: string, finDeDia = false): Date | undefined {
		if (!fecha) return undefined;
		const parsed = new Date(fecha);
		if (Number.isNaN(parsed.getTime())) return undefined;
		if (finDeDia) {
			parsed.setHours(23, 59, 59, 999);
		} else {
			parsed.setHours(0, 0, 0, 0);
		}
		return parsed;
	}

	private rangoFechas(fechaDesde?: string, fechaHasta?: string) {
		const desde = this.parseFecha(fechaDesde);
		const hasta = this.parseFecha(fechaHasta, true);
		if (!desde && !hasta) return undefined;

		return {
			...(desde ? { gte: desde } : {}),
			...(hasta ? { lte: hasta } : {}),
		};
	}

	/** Incluye OT realizadas por fecha de cierre, no solo fecha programada. */
	private whereOtEnPeriodo(
		rango?: { gte?: Date; lte?: Date },
	): Prisma.OrdenTrabajoWhereInput | undefined {
		if (!rango) return undefined;
		return {
			OR: [{ fechaProgramacion: rango }, { fechaEjecucion: rango }],
		};
	}

	async findAll(
		currentUser: AuthUser,
		filters: {
			sucursalId?: string;
			estado?: string;
			tecnicoId?: string;
			equipoId?: string;
			ubicacionId?: string;
			tipo?: string;
			fechaDesde?: string;
			fechaHasta?: string;
			misOt?: boolean;
			prioridad?: string;
			numero?: string;
			sectorResponsableId?: string;
			motivoPendienteId?: string;
			tipoEquipoId?: string;
		},
	) {
		const sucursalId = resolveSucursalId(currentUser, filters.sucursalId);
		const estados = filters.estado
			?.split(',')
			.map((item) => item.trim())
			.filter(Boolean) as EstadoOt[] | undefined;

		const fechaProgramacion = this.rangoFechas(
			filters.fechaDesde,
			filters.fechaHasta,
		);
		const periodoWhere = this.whereOtEnPeriodo(fechaProgramacion);

		let equipoUbicacionFilter: Prisma.OrdenTrabajoWhereInput | undefined;
		if (filters.ubicacionId && !filters.equipoId) {
			const ubicacionIds = await this.collectDescendantUbicacionIds(
				sucursalId,
				filters.ubicacionId,
			);
			equipoUbicacionFilter = {
				equipo: { ubicacionId: { in: ubicacionIds } },
			};
		}

		const numeroOt = filters.numero ? Number.parseInt(filters.numero, 10) : undefined;

		const filtrosBase: Prisma.OrdenTrabajoWhereInput = {
			sucursalId,
			estado: estados?.length ? { in: estados } : undefined,
			tecnicoAsignadoId: filters.misOt
				? currentUser.id
				: filters.tecnicoId,
			equipoId: filters.equipoId,
			tipo: filters.tipo as Prisma.EnumTipoMantenimientoFilter | undefined,
			prioridad: filters.prioridad as Prisma.EnumPrioridadOtFilter | undefined,
			numero: Number.isFinite(numeroOt) ? numeroOt : undefined,
			procedimiento: filters.sectorResponsableId
				? { sectorResponsableId: filters.sectorResponsableId }
				: undefined,
			motivoPendienteId: filters.motivoPendienteId,
			equipo: filters.tipoEquipoId
				? { tipoEquipoId: filters.tipoEquipoId }
				: undefined,
		};

		return this.prisma.ordenTrabajo.findMany({
			where: {
				AND: [
					filtrosBase,
					...(periodoWhere ? [periodoWhere] : []),
					...(equipoUbicacionFilter ? [equipoUbicacionFilter] : []),
				],
			},
			include: {
				equipo: { include: { ubicacion: true } },
				procedimiento: true,
				tecnicoAsignado: {
					select: { id: true, nombreUsuario: true },
				},
				motivoPendiente: {
					select: { id: true, codigo: true, descripcion: true },
				},
			},
			orderBy: [{ fechaProgramacion: 'desc' }, { numero: 'desc' }],
		});
	}

	async getResumen(
		currentUser: AuthUser,
		sucursalIdQuery?: string,
		fechaDesde?: string,
		fechaHasta?: string,
	) {
		const sucursalId = resolveSucursalId(currentUser, sucursalIdQuery);
		const fechaProgramacion = this.rangoFechas(fechaDesde, fechaHasta);
		const periodoWhere = this.whereOtEnPeriodo(fechaProgramacion);
		const baseWhere: Prisma.OrdenTrabajoWhereInput = {
			sucursalId,
			...(periodoWhere ?? {}),
		};

		const hoy = new Date();
		hoy.setHours(0, 0, 0, 0);
		const manana = new Date(hoy);
		manana.setDate(manana.getDate() + 1);

		const inicioSemana = new Date(hoy);
		const day = inicioSemana.getDay(); // 0=domingo
		const diffToMonday = day === 0 ? -6 : 1 - day;
		inicioSemana.setDate(inicioSemana.getDate() + diffToMonday);
		inicioSemana.setHours(0, 0, 0, 0);

		const inicioMes = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
		const inicioAnio = new Date(hoy.getFullYear(), 0, 1);
		const finDia = new Date(hoy);
		finDia.setHours(23, 59, 59, 999);

		const [
			pendientes,
			enEjecucion,
			realizadas,
			realizadasHoy,
			totalEquipos,
			totalPeriodo,
			solicitudesPendientes,
			otSemana,
			otMes,
			otAnio,
		] = await Promise.all([
			this.prisma.ordenTrabajo.count({
				where: { ...baseWhere, estado: 'pendiente' },
			}),
			this.prisma.ordenTrabajo.count({
				where: { ...baseWhere, estado: 'en_ejecucion' },
			}),
			this.prisma.ordenTrabajo.count({
				where: { ...baseWhere, estado: 'realizada' },
			}),
			this.prisma.ordenTrabajo.count({
				where: {
					...baseWhere,
					estado: 'realizada',
					updatedAt: { gte: hoy, lt: manana },
				},
			}),
			this.prisma.equipo.count({
				where: { sucursalId, activo: true, fueraDeServicio: false },
			}),
			this.prisma.ordenTrabajo.count({ where: baseWhere }),
			this.prisma.solicitudTrabajo.count({
				where: { sucursalId, estado: 'pendiente' },
			}),
			this.prisma.ordenTrabajo.count({
				where: {
					sucursalId,
					estado: { not: 'anulada' },
					fechaProgramacion: { gte: inicioSemana, lte: finDia },
				},
			}),
			this.prisma.ordenTrabajo.count({
				where: {
					sucursalId,
					estado: { not: 'anulada' },
					fechaProgramacion: { gte: inicioMes, lte: finDia },
				},
			}),
			this.prisma.ordenTrabajo.count({
				where: {
					sucursalId,
					estado: { not: 'anulada' },
					fechaProgramacion: { gte: inicioAnio, lte: finDia },
				},
			}),
		]);

		return {
			pendientes,
			enEjecucion,
			realizadas,
			realizadasHoy,
			totalEquipos,
			totalPeriodo,
			solicitudesPendientes,
			otSemana,
			otMes,
			otAnio,
			cumplimientoPct:
				totalPeriodo > 0
					? Math.round((realizadas / totalPeriodo) * 100)
					: 0,
		};
	}

	async findOne(id: string, currentUser: AuthUser) {
		const ot = await this.prisma.ordenTrabajo.findUnique({
			where: { id },
			include: this.otInclude(),
		});

		if (!ot) {
			throw new NotFoundException('OT no encontrada');
		}

		assertSucursalAccess(currentUser, ot.sucursalId);

		return ot;
	}

	async emitir(dto: EmitirOtDto, currentUser: AuthUser) {
		const equipo = await this.prisma.equipo.findUnique({
			where: { id: dto.equipoId },
			include: { ubicacion: true },
		});

		if (!equipo || !equipo.activo) {
			throw new BadRequestException('Equipo inválido');
		}

		assertSucursalAccess(currentUser, equipo.sucursalId);
		const sucursalId = resolveSucursalId(
			currentUser,
			dto.sucursalId ?? equipo.sucursalId,
		);

		if (dto.procedimientoId) {
			const procedimiento = await this.prisma.procedimiento.findUnique({
				where: { id: dto.procedimientoId },
			});
			if (!procedimiento || procedimiento.sucursalId !== sucursalId) {
				throw new BadRequestException('Procedimiento inválido');
			}
		}

		if (dto.tecnicoAsignadoId) {
			const tecnico = await this.prisma.usuario.findUnique({
				where: { id: dto.tecnicoAsignadoId },
			});
			if (!tecnico || !tecnico.activo || tecnico.sucursalId !== sucursalId) {
				throw new BadRequestException('Técnico inválido para la sucursal');
			}
		}

		const estadoInicial: EstadoOt = dto.tecnicoAsignadoId ? 'pendiente' : 'pendiente';

		const ot = await this.prisma.ordenTrabajo.create({
			data: {
				sucursalId,
				ubicacionId: equipo.ubicacionId,
				equipoId: equipo.id,
				procedimientoId: dto.procedimientoId,
				tipo: dto.tipo,
				estado: estadoInicial,
				tecnicoAsignadoId: dto.tecnicoAsignadoId,
				creadorId: currentUser.id,
				fechaProgramacion: new Date(dto.fechaProgramacion),
				prioridad: dto.prioridad ?? 'media',
				tolerancia: dto.tolerancia ?? 0,
				comentarios: dto.comentarios,
				otOrigenId: dto.otOrigenId,
				historialEstados: {
					create: {
						estado: estadoInicial,
						usuarioId: currentUser.id,
						comentario: 'OT emitida',
					},
				},
			},
			include: this.otInclude(),
		});

		await this.registrarHistorialEquipo(
			equipo.id,
			ot.id,
			'ot_emitida',
			`OT #${ot.numero} emitida`,
			currentUser.id,
		);

		await this.actualizarUltimaEmision(
			dto.procedimientoId,
			equipo.id,
			new Date(dto.fechaProgramacion),
		);

		if (dto.tecnicoAsignadoId) {
			const debeNotificar = dto.notificarAsignacion !== false;
			if (debeNotificar) {
				await this.push.notifyOtAsignada(ot.numero, dto.tecnicoAsignadoId);
			}
		}

		return ot;
	}

	async emitirPeriodica(dto: EmitirOtPeriodicaDto, currentUser: AuthUser) {
		const procedimiento = await this.prisma.procedimiento.findUnique({
			where: { id: dto.procedimientoId },
			include: {
				equipos: {
					where: { equipoId: dto.equipoId, estado: 'activo' },
				},
			},
		});

		if (!procedimiento || !procedimiento.activo) {
			throw new BadRequestException('Procedimiento inválido');
		}

		if (!procedimiento.periodicidadTipo || !procedimiento.periodicidadValor) {
			throw new BadRequestException(
				'El procedimiento no tiene periodicidad configurada',
			);
		}

		if (procedimiento.tipo !== 'preventivo') {
			throw new BadRequestException(
				'Solo procedimientos preventivos periódicos pueden emitir OT periódica',
			);
		}

		if (procedimiento.equipos.length === 0) {
			throw new BadRequestException(
				'El procedimiento no está asociado al equipo seleccionado',
			);
		}

		return this.emitir(
			{
				sucursalId: dto.sucursalId ?? procedimiento.sucursalId,
				equipoId: dto.equipoId,
				procedimientoId: dto.procedimientoId,
				tipo: procedimiento.tipo,
				tecnicoAsignadoId: dto.tecnicoAsignadoId,
				fechaProgramacion: dto.fechaProgramacion,
				prioridad: dto.prioridad,
				comentarios:
					dto.comentarios ??
					`OT periódica — ${procedimiento.nombre}`,
				notificarAsignacion: dto.notificarAsignacion,
			},
			currentUser,
		);
	}

	async asignar(id: string, dto: AsignarOtDto, currentUser: AuthUser) {
		const ot = await this.findOne(id, currentUser);

		if (!['pendiente', 'necesaria_de_emitir'].includes(ot.estado)) {
			throw new BadRequestException('La OT no admite asignación en este estado');
		}

		const tecnico = await this.prisma.usuario.findUnique({
			where: { id: dto.tecnicoAsignadoId },
		});

		if (!tecnico || !tecnico.activo || tecnico.sucursalId !== ot.sucursalId) {
			throw new BadRequestException('Técnico inválido');
		}

		return this.cambiarEstadoInterno(
			ot,
			'pendiente',
			currentUser,
			dto.comentario ?? `Asignada a ${tecnico.nombreUsuario}`,
			{
				tecnicoAsignado: { connect: { id: dto.tecnicoAsignadoId } },
			},
		).then(async (actualizada) => {
			await this.push.notifyOtAsignada(actualizada.numero, dto.tecnicoAsignadoId);
			return actualizada;
		});
	}

	async asignarMotivoPendiente(
		id: string,
		motivoPendienteId: string | null | undefined,
		currentUser: AuthUser,
	) {
		const ot = await this.findOne(id, currentUser);

		if (!['pendiente', 'en_ejecucion', 'pendiente_panol'].includes(ot.estado)) {
			throw new BadRequestException(
				'Solo se puede asignar motivo a OT pendiente o en ejecución',
			);
		}

		if (motivoPendienteId) {
			const motivo = await this.prisma.motivoOtPendiente.findFirst({
				where: {
					id: motivoPendienteId,
					sucursalId: ot.sucursalId,
					activo: true,
				},
			});
			if (!motivo) {
				throw new BadRequestException('Motivo de pendiente inválido');
			}
		}

		return this.prisma.ordenTrabajo.update({
			where: { id },
			data: {
				motivoPendienteId: motivoPendienteId ?? null,
				historialEstados: motivoPendienteId
					? {
							create: {
								estado: ot.estado,
								usuarioId: currentUser.id,
								comentario: 'Motivo de pendiente actualizado',
							},
						}
					: undefined,
			},
			include: this.otInclude(),
		});
	}

	private async buildUbicacionPath(ubicacionId: string): Promise<string[]> {
		const path: string[] = [];
		let currentId: string | null = ubicacionId;

		while (currentId) {
			const ubicacion: {
				id: string;
				nombre: string;
				parentId: string | null;
			} | null = await this.prisma.ubicacion.findUnique({
				where: { id: currentId },
				select: { id: true, nombre: true, parentId: true },
			});
			if (!ubicacion) break;
			path.unshift(ubicacion.nombre);
			currentId = ubicacion.parentId;
		}

		return path;
	}

	async getPdfHtml(id: string, currentUser: AuthUser) {
		await this.findOne(id, currentUser);

		const ot = await this.prisma.ordenTrabajo.findUnique({
			where: { id },
			include: {
				sucursal: true,
				ubicacion: true,
				equipo: { include: { ubicacion: true, tipoEquipo: true } },
				procedimiento: { include: { sectorResponsable: true } },
				tecnicoAsignado: { select: { nombreUsuario: true } },
				creador: { select: { nombreUsuario: true } },
				historialEstados: {
					orderBy: { createdAt: 'asc' },
					include: { usuario: { select: { nombreUsuario: true } } },
				},
				lecturas: {
					orderBy: { fecha: 'asc' },
					include: { usuario: { select: { nombreUsuario: true } } },
				},
			},
		});

		if (!ot) {
			throw new NotFoundException('OT no encontrada');
		}

		const ubicacionPath = [
			ot.sucursal.nombre,
			...(await this.buildUbicacionPath(ot.ubicacionId)),
		];

		const pdfData: OtPdfData = {
			numero: ot.numero,
			sucursalNombre: ot.sucursal.nombre,
			fechaProgramacion: ot.fechaProgramacion,
			fechaEjecucion: ot.fechaEjecucion,
			tipo: ot.tipo,
			estado: ot.estado,
			tolerancia: ot.tolerancia,
			prioridad: ot.prioridad,
			comentarios: ot.comentarios,
			novedadesFueraDePrograma: ot.novedadesFueraDePrograma,
			firmaDigital: ot.firmaDigital,
			equipo: ot.equipo,
			procedimiento: ot.procedimiento,
			tecnicoAsignado: ot.tecnicoAsignado,
			creador: ot.creador,
			ubicacionPath,
			checklistCompletado: ot.checklistCompletado,
			lecturas: ot.lecturas,
			historialEstados: ot.historialEstados,
		};

		const html = renderOtPdfHtml(pdfData);

		return { html, numero: ot.numero };
	}

	async cambiarEstado(id: string, dto: CambiarEstadoOtDto, currentUser: AuthUser) {
		const ot = await this.findOne(id, currentUser);
		this.assertPuedeOperarOt(ot, currentUser);
		this.validarTransicion(ot.estado, dto.estado);

		if (['en_ejecucion', 'realizada'].includes(dto.estado)) {
			this.assertPreparacionOt(ot);
			if (ot.estado === 'pendiente_panol') {
				throw new BadRequestException(
					'Pañol debe confirmar los materiales antes de iniciar la OT',
				);
			}
		}

		const extra: Prisma.OrdenTrabajoUpdateInput = {};

		if (dto.estado === 'realizada') {
			extra.fechaEjecucion = new Date();
		}

		return this.cambiarEstadoInterno(
			ot,
			dto.estado,
			currentUser,
			dto.comentario,
			extra,
		);
	}

	async completarChecklist(
		id: string,
		dto: CompletarChecklistDto,
		currentUser: AuthUser,
	) {
		return this.actualizarEjecucion(
			id,
			{ items: dto.items },
			currentUser,
		);
	}

	async actualizarEjecucion(
		id: string,
		dto: {
			items?: unknown[];
			novedadesFueraDePrograma?: string;
			comentarios?: string;
			fotos?: { key: string; url: string; nombre?: string; contentType?: string }[];
		},
		currentUser: AuthUser,
	) {
		const ot = await this.findOne(id, currentUser);
		this.assertPuedeOperarOt(ot, currentUser);
		this.assertPreparacionOt(ot);

		if (!['en_ejecucion', 'pendiente'].includes(ot.estado)) {
			throw new BadRequestException(
				'La OT no admite actualización de ejecución en este estado',
			);
		}

		const data: Prisma.OrdenTrabajoUpdateInput = {};

		if (dto.items !== undefined) {
			data.checklistCompletado = dto.items as Prisma.InputJsonValue;
		}
		if (dto.novedadesFueraDePrograma !== undefined) {
			data.novedadesFueraDePrograma = dto.novedadesFueraDePrograma;
		}
		if (dto.comentarios !== undefined) {
			data.comentarios = dto.comentarios;
		}
		if (dto.fotos !== undefined) {
			data.fotos = dto.fotos as Prisma.InputJsonValue;
		}

		return this.prisma.ordenTrabajo.update({
			where: { id },
			data,
			include: this.otInclude(),
		});
	}

	async registrarFirma(id: string, dto: RegistrarFirmaDto, currentUser: AuthUser) {
		const ot = await this.findOne(id, currentUser);
		this.assertPuedeOperarOt(ot, currentUser);
		this.assertPreparacionOt(ot);

		if (!['en_ejecucion', 'pendiente'].includes(ot.estado)) {
			throw new BadRequestException('La OT no admite firma en este estado');
		}

		const actualizada = await this.prisma.ordenTrabajo.update({
			where: { id },
			data: { firmaDigital: dto.firmaDigital },
			include: this.otInclude(),
		});

		return this.cambiarEstadoInterno(
			actualizada,
			'realizada',
			currentUser,
			'OT cerrada con firma',
			{ fechaEjecucion: new Date(), firmaDigital: dto.firmaDigital },
		);
	}

	async anular(id: string, dto: AnularOtDto, currentUser: AuthUser) {
		const ot = await this.findOne(id, currentUser);

		if (['realizada', 'anulada'].includes(ot.estado)) {
			throw new BadRequestException('La OT no puede anularse');
		}

		return this.cambiarEstadoInterno(
			ot,
			'anulada',
			currentUser,
			dto.comentario ?? 'OT anulada',
		);
	}

	async reabrir(id: string, dto: ReabrirOtDto, currentUser: AuthUser) {
		const ot = await this.findOne(id, currentUser);
		this.assertPuedeReabrir(currentUser);

		if (!['realizada', 'anulada'].includes(ot.estado)) {
			throw new BadRequestException(
				'Solo se pueden reabrir OT realizadas o anuladas',
			);
		}

		const destino = dto.estado ?? 'pendiente';
		if (!['pendiente', 'en_ejecucion'].includes(destino)) {
			throw new BadRequestException('Estado destino inválido para reapertura');
		}

		const comentario =
				dto.comentario?.trim() ||
				`OT reabierta desde ${ot.estado.replaceAll('_', ' ')}`;

		return this.prisma.ordenTrabajo.update({
			where: { id },
			data: {
				estado: destino,
				fechaEjecucion: null,
				firmaDigital: null,
				decisionMateriales: destino === 'pendiente' ? 'pendiente' : undefined,
				historialEstados: {
					create: {
						estado: destino,
						usuarioId: currentUser.id,
						comentario,
					},
				},
			},
			include: this.otInclude(),
		});
	}

	async registrarLecturaOt(
		id: string,
		dto: RegistrarLecturaOtDto,
		currentUser: AuthUser,
	) {
		const ot = await this.findOne(id, currentUser);
		this.assertPuedeOperarOt(ot, currentUser);

		if (['realizada', 'anulada'].includes(ot.estado)) {
			throw new BadRequestException('La OT no admite lectura en este estado');
		}

		const lectura = await this.prisma.lectura.create({
			data: {
				equipoId: ot.equipoId,
				otId: ot.id,
				usuarioId: currentUser.id,
				tipo: dto.tipo.trim(),
				valor: dto.valor,
				notas: dto.notas?.trim() || `Lectura OT #${ot.numero}`,
			},
		});

		const actualizada = await this.prisma.ordenTrabajo.update({
			where: { id: ot.id },
			data: { lecturaRegistradaAt: new Date() },
			include: this.otInclude(),
		});

		try {
			await this.emitirPorContadorEquipo(ot.equipoId);
		} catch {
			// no bloquear la preparación si falla emisión automática
		}

		return { lectura, ot: actualizada };
	}

	async analizarMaterialesOt(
		id: string,
		dto: AnalizarMaterialesOtDto,
		currentUser: AuthUser,
	) {
		const ot = await this.findOne(id, currentUser);
		this.assertPuedeOperarOt(ot, currentUser);
		if (!ot.lecturaRegistradaAt) {
			throw new BadRequestException('Registrá la lectura antes de pedir materiales');
		}

		const catalogo = await this.buildStockCatalog(ot.sucursalId, dto.panolId);
		const lineas = matchMaterialesContraStock(dto.texto, catalogo);
		const tieneFaltantes = lineas.some((l) => l.cantidadFaltante > 0);

		return {
			texto: dto.texto.trim(),
			lineas,
			tieneFaltantes,
			resumen: {
				total: lineas.length,
				ok: lineas.filter((l) => l.estado === 'ok').length,
				faltantes: lineas.filter((l) => l.cantidadFaltante > 0).length,
			},
		};
	}

	async decidirSinMateriales(
		id: string,
		dto: DecidirSinMaterialesOtDto,
		currentUser: AuthUser,
	) {
		const ot = await this.findOne(id, currentUser);
		this.assertPuedeOperarOt(ot, currentUser);
		if (!ot.lecturaRegistradaAt) {
			throw new BadRequestException('Registrá la lectura antes de continuar');
		}

		return this.prisma.ordenTrabajo.update({
			where: { id: ot.id },
			data: {
				decisionMateriales: 'no_necesita',
				materialesTextoLibre: dto.comentario?.trim() || null,
				historialEstados: {
					create: {
						estado: ot.estado,
						usuarioId: currentUser.id,
						comentario: 'Técnico indicó que no necesita materiales',
					},
				},
			},
			include: this.otInclude(),
		});
	}

	async confirmarMaterialesOt(
		id: string,
		dto: ConfirmarMaterialesOtDto,
		currentUser: AuthUser,
	) {
		const ot = await this.findOne(id, currentUser);
		this.assertPuedeOperarOt(ot, currentUser);
		if (!ot.lecturaRegistradaAt) {
			throw new BadRequestException('Registrá la lectura antes de pedir materiales');
		}

		const analisis = await this.analizarMaterialesOt(id, dto, currentUser);
		const tieneFaltantes = analisis.tieneFaltantes;
		if (tieneFaltantes && !dto.procederConFaltantes) {
			return {
				requiereConfirmacion: true,
				mensaje:
					'Hay materiales faltantes. Confirmá si igual realizás la OT; se generará pedido de lo faltante.',
				analisis,
			};
		}

		const panolDefault = await this.resolvePanol(ot.sucursalId, dto.panolId);
		const unidadDefault = await this.prisma.unidad.findFirst({
			orderBy: { nombre: 'asc' },
		});
		if (!unidadDefault) {
			throw new BadRequestException('No hay unidades de medida configuradas');
		}

		const solicitudes: string[] = [];
		const pedidos: string[] = [];

		await this.prisma.$transaction(async (tx) => {
			for (const linea of analisis.lineas) {
				if (linea.match && linea.cantidadDisponible > 0) {
					const sol = await tx.solicitudMaterial.create({
						data: {
							otId: ot.id,
							panolId: linea.match.panolId,
							materialId: linea.match.materialId,
							cantidadSolicitada: linea.cantidadDisponible,
							solicitanteId: currentUser.id,
							estado: EstadoSolicitudMaterial.pendiente,
						},
					});
					solicitudes.push(sol.id);
				}

				if (linea.cantidadFaltante > 0) {
					let materialId = linea.match?.materialId;
					let panolId = linea.match?.panolId ?? panolDefault.id;

					if (!materialId) {
						const codigo = `REQ-${Date.now().toString(36)}-${Math.floor(Math.random() * 999)}`.slice(0, 50);
						const material = await tx.material.create({
							data: {
								codigo,
								nombre: linea.descripcion.slice(0, 200),
								unidadId: unidadDefault.id,
								uso: 'Mantenimiento',
								activo: true,
							},
						});
						materialId = material.id;
					}

					const pedido = await tx.pedidoStock.create({
						data: {
							panolId,
							materialId,
							otId: ot.id,
							cantidad: linea.cantidadFaltante,
							usuarioId: currentUser.id,
							estado: EstadoPedidoStock.pendiente,
							notas: `Faltante OT #${ot.numero}: ${linea.raw}`,
						},
					});
					pedidos.push(pedido.id);
				}
			}

			await tx.ordenTrabajo.update({
				where: { id: ot.id },
				data: {
					decisionMateriales: 'necesita',
					materialesTextoLibre: dto.texto.trim(),
					estado: 'pendiente_panol',
					historialEstados: {
						create: {
							estado: 'pendiente_panol',
							usuarioId: currentUser.id,
							comentario: tieneFaltantes
								? `Materiales con faltantes: ${pedidos.length} pedido(s) generado(s)`
								: 'Solicitud de materiales enviada (stock disponible)',
						},
					},
				},
			});
		});

		const actualizada = await this.findOne(id, currentUser);
		return {
			requiereConfirmacion: false,
			analisis,
			solicitudesCreadas: solicitudes.length,
			pedidosCreados: pedidos.length,
			ot: actualizada,
		};
	}

	private async resolvePanol(sucursalId: string, panolId?: string) {
		if (panolId) {
			const panol = await this.prisma.panol.findFirst({
				where: { id: panolId, sucursalId, activo: true },
			});
			if (!panol) throw new BadRequestException('Pañol inválido');
			return panol;
		}
		const panol = await this.prisma.panol.findFirst({
			where: { sucursalId, activo: true },
			orderBy: { nombre: 'asc' },
		});
		if (!panol) throw new BadRequestException('No hay pañol activo en la sucursal');
		return panol;
	}

	private async buildStockCatalog(
		sucursalId: string,
		panolId?: string,
	): Promise<StockCandidate[]> {
		const items = await this.prisma.stockItem.findMany({
			where: {
				panol: {
					sucursalId,
					activo: true,
					...(panolId ? { id: panolId } : {}),
				},
				material: { activo: true },
			},
			include: {
				material: { include: { unidad: true } },
				panol: true,
			},
		});

		return items.map((item) => {
			const actual = Number(item.cantidadActual);
			const reservada = Number(item.cantidadReservada);
			return {
				materialId: item.materialId,
				codigo: item.material.codigo,
				nombre: item.material.nombre,
				disponible: Math.max(0, actual - reservada),
				panolId: item.panolId,
				panolNombre: item.panol.nombre,
				unidad: item.material.unidad?.nombre ?? null,
			};
		});
	}

	async derivar(id: string, dto: DerivarOtDto, currentUser: AuthUser) {
		const origen = await this.findOne(id, currentUser);
		const comentarios =
				dto.comentarios?.trim() ||
				`OT derivada de #${origen.numero}`;

		return this.emitir(
			{
				equipoId: origen.equipoId,
				procedimientoId: origen.procedimientoId ?? undefined,
				tipo: 'correctivo',
				fechaProgramacion: this.toDateOnlyString(new Date()),
				prioridad: origen.prioridad,
				comentarios,
				sucursalId: origen.sucursalId,
				otOrigenId: origen.id,
			},
			currentUser,
		);
	}

	async emitirPorContadorEquipo(equipoId: string) {
		const equipo = await this.prisma.equipo.findUnique({
			where: { id: equipoId },
			select: { id: true, sucursalId: true, activo: true },
		});
		if (!equipo?.activo) return { emitidas: 0 };

		const sistemaUser = {
			id: '00000000-0000-0000-0000-000000000001',
			nombreUsuario: 'sistema',
			esAdministrador: true,
			supervisaSucursales: true,
			sucursalId: equipo.sucursalId,
		} as AuthUser;

		const { items } = await this.listarNecesarias(sistemaUser, {
			sucursalId: equipo.sucursalId,
		});
		const delEquipo = items.filter((item) => item.equipo.id === equipoId);
		if (delEquipo.length === 0) return { emitidas: 0 };

		const hoy = this.toDateOnlyString(new Date());
		const resultado = await this.emitirNecesarias(
			{
				sucursalId: equipo.sucursalId,
				items: delEquipo.map((item) => ({
					procedimientoId: item.procedimientoId,
					equipoId: item.equipo.id,
					fechaProgramacion: item.fechaNecesaria ?? hoy,
				})),
			},
			sistemaUser,
		);
		return { emitidas: resultado.total };
	}

	async getGantt(
		currentUser: AuthUser,
		opts: {
			sucursalId?: string;
			fechaDesde?: string;
			fechaHasta?: string;
			agruparPor?: 'equipo' | 'sector';
			ubicacionId?: string;
			misOt?: boolean;
		},
	) {
		const sucursalId = resolveSucursalId(currentUser, opts.sucursalId);
		const agruparPor = opts.agruparPor === 'sector' ? 'sector' : 'equipo';
		const rango = this.rangoFechas(opts.fechaDesde, opts.fechaHasta);
		const periodoWhere = this.whereOtEnPeriodo(rango);

		let equipoUbicacionFilter: Prisma.OrdenTrabajoWhereInput | undefined;
		if (opts.ubicacionId) {
			const ubicacionIds = await this.collectDescendantUbicacionIds(
				sucursalId,
				opts.ubicacionId,
			);
			equipoUbicacionFilter = {
				equipo: { ubicacionId: { in: ubicacionIds } },
			};
		}

		const ots = await this.prisma.ordenTrabajo.findMany({
			where: {
				AND: [
					{
						sucursalId,
						estado: { not: 'anulada' },
						...(opts.misOt ? { tecnicoAsignadoId: currentUser.id } : {}),
					},
					...(periodoWhere ? [periodoWhere] : []),
					...(equipoUbicacionFilter ? [equipoUbicacionFilter] : []),
				],
			},
			select: {
				estado: true,
				fechaProgramacion: true,
				fechaEjecucion: true,
				equipo: {
					select: {
						id: true,
						codigo: true,
						nombre: true,
						ubicacion: { select: { id: true, nombre: true } },
					},
				},
			},
			take: 5000,
		});

		const desde =
			rango?.gte ??
			(ots.length
				? ots.reduce(
						(min, ot) => (ot.fechaProgramacion < min ? ot.fechaProgramacion : min),
						ots[0].fechaProgramacion,
					)
				: new Date());
		const hasta =
			rango?.lte ??
			(ots.length
				? ots.reduce(
						(max, ot) => (ot.fechaProgramacion > max ? ot.fechaProgramacion : max),
						ots[0].fechaProgramacion,
					)
				: new Date());

		const dias: string[] = [];
		const cursor = new Date(Date.UTC(desde.getUTCFullYear(), desde.getUTCMonth(), desde.getUTCDate()));
		const end = new Date(Date.UTC(hasta.getUTCFullYear(), hasta.getUTCMonth(), hasta.getUTCDate()));
		const maxDias = 93;
		while (cursor <= end && dias.length < maxDias) {
			dias.push(cursor.toISOString().slice(0, 10));
			cursor.setUTCDate(cursor.getUTCDate() + 1);
		}

		type Celda = {
			pendientes: number;
			enEjecucion: number;
			realizadas: number;
			total: number;
		};
		const emptyCelda = (): Celda => ({
			pendientes: 0,
			enEjecucion: 0,
			realizadas: 0,
			total: 0,
		});

		const filasMap = new Map<
			string,
			{ id: string; label: string; celdas: Map<string, Celda> }
		>();

		const bucketEstado = (estado: EstadoOt): keyof Celda | null => {
			if (estado === 'realizada') return 'realizadas';
			if (estado === 'en_ejecucion') return 'enEjecucion';
			if (
				estado === 'pendiente' ||
				estado === 'pendiente_panol' ||
				estado === 'necesaria_de_emitir'
			) {
				return 'pendientes';
			}
			return null;
		};

		for (const ot of ots) {
			const diaBase =
				ot.estado === 'realizada' && ot.fechaEjecucion
					? ot.fechaEjecucion
					: ot.fechaProgramacion;
			const dia = this.toDateOnlyString(diaBase);
			if (!dias.includes(dia)) continue;

			const rowId =
				agruparPor === 'sector'
					? ot.equipo.ubicacion?.id ?? 'sin-sector'
					: ot.equipo.id;
			const label =
				agruparPor === 'sector'
					? ot.equipo.ubicacion
						? ot.equipo.ubicacion.nombre
						: 'Sin sector'
					: `${ot.equipo.codigo} · ${ot.equipo.nombre}`;

			let fila = filasMap.get(rowId);
			if (!fila) {
				fila = { id: rowId, label, celdas: new Map() };
				filasMap.set(rowId, fila);
			}

			const bucket = bucketEstado(ot.estado);
			if (!bucket) continue;
			const celda = fila.celdas.get(dia) ?? emptyCelda();
			celda[bucket] += 1;
			celda.total += 1;
			fila.celdas.set(dia, celda);
		}

		const filas = [...filasMap.values()]
			.sort((a, b) => a.label.localeCompare(b.label, 'es'))
			.map((fila) => ({
				id: fila.id,
				label: fila.label,
				celdas: Object.fromEntries(
					dias.map((d) => [d, fila.celdas.get(d) ?? emptyCelda()]),
				),
				totales: dias.reduce(
					(acc, d) => {
						const c = fila.celdas.get(d) ?? emptyCelda();
						acc.pendientes += c.pendientes;
						acc.enEjecucion += c.enEjecucion;
						acc.realizadas += c.realizadas;
						acc.total += c.total;
						return acc;
					},
					emptyCelda(),
				),
			}));

		return {
			agruparPor,
			fechaDesde: this.toDateOnlyString(desde),
			fechaHasta: this.toDateOnlyString(hasta),
			dias,
			filas,
			totalesGenerales: filas.reduce(
				(acc, f) => {
					acc.pendientes += f.totales.pendientes;
					acc.enEjecucion += f.totales.enEjecucion;
					acc.realizadas += f.totales.realizadas;
					acc.total += f.totales.total;
					return acc;
				},
				emptyCelda(),
			),
		};
	}

	async getGraficos(currentUser: AuthUser, dto: GraficosOtDto) {
		const sucursalId = resolveSucursalId(currentUser, dto.sucursalId);
		const rango = this.rangoFechas(dto.fechaDesde, dto.fechaHasta);
		const periodoWhere = this.whereOtEnPeriodo(rango);

		let equipoUbicacionFilter: Prisma.OrdenTrabajoWhereInput | undefined;
		if (dto.ubicacionId) {
			const ubicacionIds = await this.collectDescendantUbicacionIds(
				sucursalId,
				dto.ubicacionId,
			);
			equipoUbicacionFilter = {
				equipo: { ubicacionId: { in: ubicacionIds } },
			};
		}

		const equipoIds =
			dto.plantaCompleta || !dto.equipoIds?.length ? undefined : dto.equipoIds;

		const equipoFilter: Prisma.EquipoWhereInput = {
			...(equipoIds ? { id: { in: equipoIds } } : {}),
			...(dto.tipoEquipoId ? { tipoEquipoId: dto.tipoEquipoId } : {}),
		};

		const ots = await this.prisma.ordenTrabajo.findMany({
			where: {
				AND: [
					{
						sucursalId,
						estado: { not: 'anulada' },
						tipo: dto.tipoProcedimiento,
						procedimiento: dto.sectorResponsableId
							? { sectorResponsableId: dto.sectorResponsableId }
							: undefined,
						...(Object.keys(equipoFilter).length
							? { equipo: equipoFilter }
							: {}),
					},
					...(periodoWhere ? [periodoWhere] : []),
					...(equipoUbicacionFilter ? [equipoUbicacionFilter] : []),
				],
			},
			select: {
				estado: true,
				tipo: true,
				fechaProgramacion: true,
				fechaEjecucion: true,
				equipo: { select: { id: true, codigo: true, nombre: true } },
				tecnicoAsignado: { select: { id: true, nombreUsuario: true } },
				procedimiento: {
					select: {
						hsHombre: true,
						costoEstimado: true,
						indisponibilidadEstimada: true,
						tipo: true,
					},
				},
			},
			take: 10000,
		});

		const metricOf = (ot: (typeof ots)[number]): number => {
			const proc = ot.procedimiento;
			switch (dto.ejeY) {
				case EjeYGraficos.horas_hombre:
					return Number(proc?.hsHombre ?? 0);
				case EjeYGraficos.costos:
					return Number(proc?.costoEstimado ?? 0);
				case EjeYGraficos.indisponibilidad:
					return Number(proc?.indisponibilidadEstimada ?? 0);
				case EjeYGraficos.cantidad_ot:
				default:
					return 1;
			}
		};

		const labelX = (ot: (typeof ots)[number]): string => {
			const fecha =
				ot.estado === 'realizada' && ot.fechaEjecucion
					? ot.fechaEjecucion
					: ot.fechaProgramacion;
			switch (dto.ejeX) {
				case EjeXGraficos.mes:
					return `${fecha.getUTCFullYear()}-${String(fecha.getUTCMonth() + 1).padStart(2, '0')}`;
				case EjeXGraficos.responsable:
					return ot.tecnicoAsignado?.nombreUsuario ?? 'Sin asignar';
				case EjeXGraficos.tipo_trabajo:
					return ot.tipo;
				case EjeXGraficos.equipos:
					return `${ot.equipo.codigo} · ${ot.equipo.nombre}`;
				default:
					return 'N/D';
			}
		};

		const labelGrupo = (ot: (typeof ots)[number]): string => {
			const fecha =
				ot.estado === 'realizada' && ot.fechaEjecucion
					? ot.fechaEjecucion
					: ot.fechaProgramacion;
			switch (dto.agrupado) {
				case AgrupadoGraficos.mes:
					return `${fecha.getUTCFullYear()}-${String(fecha.getUTCMonth() + 1).padStart(2, '0')}`;
				case AgrupadoGraficos.responsable:
					return ot.tecnicoAsignado?.nombreUsuario ?? 'Sin asignar';
				case AgrupadoGraficos.tipo_trabajo:
					return ot.tipo;
				case AgrupadoGraficos.ninguno:
				default:
					return 'Total';
			}
		};

		const buckets = new Map<string, Map<string, number>>();
		for (const ot of ots) {
			const x = labelX(ot);
			const g = labelGrupo(ot);
			if (!buckets.has(g)) buckets.set(g, new Map());
			const series = buckets.get(g)!;
			series.set(x, (series.get(x) ?? 0) + metricOf(ot));
		}

		const labelsSet = new Set<string>();
		for (const series of buckets.values()) {
			for (const key of series.keys()) labelsSet.add(key);
		}
		const labels = [...labelsSet].sort((a, b) => a.localeCompare(b, 'es'));

		const series = [...buckets.entries()]
			.sort(([a], [b]) => a.localeCompare(b, 'es'))
			.map(([name, points]) => ({
				name,
				points: labels.map((x) => ({
					x,
					y: Number((points.get(x) ?? 0).toFixed(2)),
				})),
			}));

		const total = series.reduce(
			(acc, s) => acc + s.points.reduce((a, p) => a + p.y, 0),
			0,
		);

		return {
			tipoGrafico: dto.tipoGrafico,
			ejeX: dto.ejeX,
			ejeY: dto.ejeY,
			agrupado: dto.agrupado,
			fechaDesde: dto.fechaDesde,
			fechaHasta: dto.fechaHasta,
			labels,
			series,
			total: Number(total.toFixed(2)),
			cantidadOt: ots.length,
		};
	}

	async emitirNecesariasAutomaticas(sucursalId: string) {
		const sistemaUser = {
			id: '00000000-0000-0000-0000-000000000001',
			nombreUsuario: 'sistema',
			esAdministrador: true,
			supervisaSucursales: true,
			sucursalId,
		} as AuthUser;

		const { items } = await this.listarNecesarias(sistemaUser, { sucursalId });
		if (items.length === 0) return { emitidas: 0 };

		const hoy = this.toDateOnlyString(new Date());
		const resultado = await this.emitirNecesarias(
			{
				sucursalId,
				items: items.map((item) => ({
					procedimientoId: item.procedimientoId,
					equipoId: item.equipo.id,
					fechaProgramacion: item.fechaNecesaria ?? hoy,
				})),
			},
			sistemaUser,
		);

		return { emitidas: resultado.total };
	}

	private async collectDescendantUbicacionIds(
		sucursalId: string,
		rootId: string,
	): Promise<string[]> {
		const nodes = await this.prisma.ubicacion.findMany({
			where: { sucursalId, activa: true },
			select: { id: true, parentId: true },
		});

		const childrenMap = new Map<string, string[]>();
		for (const node of nodes) {
			if (!node.parentId) continue;
			const list = childrenMap.get(node.parentId) ?? [];
			list.push(node.id);
			childrenMap.set(node.parentId, list);
		}

		const result = new Set<string>([rootId]);
		const stack = [rootId];
		while (stack.length > 0) {
			const current = stack.pop()!;
			for (const childId of childrenMap.get(current) ?? []) {
				if (!result.has(childId)) {
					result.add(childId);
					stack.push(childId);
				}
			}
		}

		return [...result];
	}

	private validarTransicion(actual: EstadoOt, siguiente: EstadoOt) {
		if (!TRANSICIONES[actual].includes(siguiente)) {
			throw new BadRequestException(
				`Transición inválida: ${actual} → ${siguiente}`,
			);
		}
	}

	private async cambiarEstadoInterno(
		ot: { id: string; estado: EstadoOt; equipoId: string; numero: number },
		estado: EstadoOt,
		currentUser: AuthUser,
		comentario?: string,
		extra: Prisma.OrdenTrabajoUpdateInput = {},
	) {
		if (estado !== ot.estado) {
			this.validarTransicion(ot.estado, estado);
		}

		const actualizada = await this.prisma.ordenTrabajo.update({
			where: { id: ot.id },
			data: {
				estado,
				...extra,
				historialEstados: {
					create: {
						estado,
						usuarioId: currentUser.id,
						comentario,
					},
				},
			},
			include: this.otInclude(),
		});

		if (estado === 'realizada') {
			await this.registrarHistorialEquipo(
				ot.equipoId,
				ot.id,
				'ot_realizada',
				`OT #${ot.numero} realizada`,
				currentUser.id,
			);
			await this.stockService.consumirReservasOt(ot.id, currentUser.id);
		}

		if (estado === 'anulada') {
			await this.stockService.liberarReservasOt(ot.id, currentUser.id);
		}

		return actualizada;
	}

	private async registrarHistorialEquipo(
		equipoId: string,
		otId: string,
		tipoEvento: string,
		descripcion: string,
		usuarioId: string,
	) {
		await this.prisma.historialEquipo.create({
			data: {
				equipoId,
				otId,
				tipoEvento,
				descripcion,
				usuarioId,
			},
		});
	}
}
