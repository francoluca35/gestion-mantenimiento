import {
	BadRequestException,
	ForbiddenException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { EstadoOt, Prisma, TipoMantenimiento } from '@prisma/client';
import admin from 'firebase-admin';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { assertSucursalAccess, resolveSucursalId } from '../mantenimiento.scope';
import { AnularOtDto } from './dto/anular-ot.dto';
import { AsignarOtDto } from './dto/asignar-ot.dto';
import { CambiarEstadoOtDto } from './dto/cambiar-estado-ot.dto';
import { CompletarChecklistDto } from './dto/completar-checklist.dto';
import { DerivarOtDto } from './dto/derivar-ot.dto';
import { EmitirOtDto } from './dto/emitir-ot.dto';
import { EmitirOtPeriodicaDto } from './dto/emitir-ot-periodica.dto';
import { EmitirOtNecesariasDto } from './dto/emitir-ot-necesarias.dto';
import { RegistrarFirmaDto } from './dto/registrar-firma.dto';
import { ReabrirOtDto } from './dto/reabrir-ot.dto';
import { renderOtPdfHtml, type OtPdfData } from './ot-pdf.template';

const TRANSICIONES: Record<EstadoOt, EstadoOt[]> = {
	necesaria_de_emitir: ['pendiente', 'anulada'],
	pendiente: ['en_ejecucion', 'pendiente_panol', 'anulada', 'realizada'],
	pendiente_panol: ['en_ejecucion', 'anulada'],
	en_ejecucion: ['realizada', 'anulada'],
	realizada: [],
	anulada: [],
};

@Injectable()
export class OtService {
	constructor(private readonly prisma: PrismaService) {}

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
					notificarAsignacion: item.notificarAsignacion,
				},
				currentUser,
			);

			emitidas.push(ot);
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

		const [pendientes, enEjecucion, realizadas, realizadasHoy, totalEquipos, totalPeriodo] =
			await Promise.all([
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
			]);

		return {
			pendientes,
			enEjecucion,
			realizadas,
			realizadasHoy,
			totalEquipos,
			totalPeriodo,
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
				await this.notificarAsignacion(ot.numero, dto.tecnicoAsignadoId);
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
			await this.notificarAsignacion(actualizada.numero, dto.tecnicoAsignadoId);
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
			},
			currentUser,
		);
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

	private async notificarAsignacion(otNumero: number, tecnicoId: string) {
		const tecnico = await this.prisma.usuario.findUnique({
			where: { id: tecnicoId },
			select: { nombreUsuario: true },
		});

		const dispositivos = await this.prisma.dispositivoFcm.findMany({
			where: { usuarioId: tecnicoId },
			select: { token: true },
		});

		if (dispositivos.length === 0) return;

		// Tipado flexible: firebase-admin tiene diferencias entre versiones/ESM.
		const firebase = admin as any;

		const projectId = process.env.FIREBASE_PROJECT_ID;
		const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
		const privateKeyRaw = process.env.FIREBASE_PRIVATE_KEY;

		// En dev, si no hay credenciales, degradamos a log.
		if (!projectId || !clientEmail || !privateKeyRaw) {
			console.log(
				`[push:disabled] OT #${otNumero} asignada a ${
					tecnico?.nombreUsuario ?? tecnicoId
				} (sin credenciales FCM)`,
			);
			return;
		}

		const privateKey = privateKeyRaw.replace(/\\n/g, '\n');

		if (firebase.apps.length === 0) {
			firebase.initializeApp({
				credential: firebase.credential.cert({
					projectId,
					clientEmail,
					privateKey,
				}),
			});
		}

		try {
			const tokens = dispositivos.map((d: { token: string }) => d.token);

			const title = `OT #${otNumero}`;
			const body = tecnico?.nombreUsuario
				? `Nueva orden asignada a ${tecnico.nombreUsuario}`
				: 'Nueva orden de trabajo asignada';

			const response = await firebase.messaging().sendMulticast({
				tokens,
				notification: { title, body },
				data: {
					type: 'ot.asignada',
					otNumero: String(otNumero),
				},
			});

			console.log(
				`[push] OT #${otNumero} enviada — ok: ${response.successCount} / ${response.failureCount}`,
			);
		} catch (error) {
			console.log(`[push:error] ${String(error)}`);
		}
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
