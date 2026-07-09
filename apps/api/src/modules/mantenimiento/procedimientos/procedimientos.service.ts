import {
	BadRequestException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { CriterioProgramacion, PeriodicidadTipo, Prisma, TipoMantenimiento } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { assertSucursalAccess, resolveSucursalId } from '../mantenimiento.scope';
import { OtService } from '../ot/ot.service';
import { AsociarAlcanceDto } from './dto/asociar-alcance.dto';
import { AsociarEquipoDto } from './dto/asociar-equipo.dto';
import { DesasociarAlcanceDto } from './dto/desasociar-alcance.dto';
import { DesasociarEquipoDto } from './dto/desasociar-equipo.dto';
import { CreateProcedimientoDto } from './dto/create-procedimiento.dto';
import { UpdateProcedimientoDto } from './dto/update-procedimiento.dto';

const PROCEDIMIENTO_INCLUDE = {
	sectorResponsable: true,
	_count: { select: { equipos: true, ordenes: true } },
} as const;

@Injectable()
export class ProcedimientosService {
	constructor(
		private readonly prisma: PrismaService,
		private readonly otService: OtService,
	) {}

	async findAll(currentUser: AuthUser, sucursalIdQuery?: string) {
		const sucursalId = resolveSucursalId(currentUser, sucursalIdQuery);

		return this.prisma.procedimiento.findMany({
			where: { sucursalId, activo: true },
			include: PROCEDIMIENTO_INCLUDE,
			orderBy: { codigo: 'asc' },
		});
	}

	async findOne(id: string, currentUser: AuthUser) {
		const procedimiento = await this.prisma.procedimiento.findUnique({
			where: { id },
			include: {
				sectorResponsable: true,
				equipos: {
					include: {
						equipo: {
							include: { ubicacion: true, tipoEquipo: true },
						},
					},
				},
				alcances: {
					include: {
						ubicacion: true,
						sucursalAlcance: true,
					},
				},
			},
		});

		if (!procedimiento) {
			throw new NotFoundException('Procedimiento no encontrado');
		}

		assertSucursalAccess(currentUser, procedimiento.sucursalId);
		return procedimiento;
	}

	private resolvePeriodicidad(
		tipo: TipoMantenimiento,
		dto: {
			periodicidadTipo?: string | null;
			periodicidadValor?: number | null;
			criterioProgramacion?: string | null;
		},
		existing?: {
			periodicidadTipo: string | null;
			periodicidadValor: number | null;
			criterioProgramacion: string | null;
		},
	) {
		if (tipo === 'preventivo_no_periodico') {
			return {
				periodicidadTipo: null,
				periodicidadValor: null,
				criterioProgramacion: null,
			} satisfies {
				periodicidadTipo: PeriodicidadTipo | null;
				periodicidadValor: number | null;
				criterioProgramacion: CriterioProgramacion | null;
			};
		}

		const hasInput =
			dto.periodicidadTipo !== undefined ||
			dto.periodicidadValor !== undefined ||
			dto.criterioProgramacion !== undefined;

		if (!hasInput && existing) {
			return {
				periodicidadTipo: existing.periodicidadTipo as PeriodicidadTipo | null,
				periodicidadValor: existing.periodicidadValor,
				criterioProgramacion:
					existing.criterioProgramacion as CriterioProgramacion | null,
			};
		}

		if (!dto.periodicidadTipo || !dto.periodicidadValor) {
			return {
				periodicidadTipo: null,
				periodicidadValor: null,
				criterioProgramacion: null,
			};
		}

		return {
			periodicidadTipo: dto.periodicidadTipo as PeriodicidadTipo,
			periodicidadValor: dto.periodicidadValor,
			criterioProgramacion:
				(dto.criterioProgramacion as CriterioProgramacion | null) ?? null,
		};
	}

	async create(dto: CreateProcedimientoDto, currentUser: AuthUser) {
		const sucursalId = resolveSucursalId(currentUser, dto.sucursalId);
		await this.assertSectorResponsable(dto.sectorResponsableId, sucursalId);
		this.assertPeriodicidad(dto.tipo, dto);

		const nombre =
			dto.nombre?.trim() ||
			dto.descripcion.trim().slice(0, 200) ||
			'Procedimiento sin título';

		const periodicidad = this.resolvePeriodicidad(dto.tipo, dto);

		return this.prisma.procedimiento.create({
			data: {
				sucursalId,
				sectorResponsableId: dto.sectorResponsableId,
				nombre,
				tipo: dto.tipo,
				descripcion: dto.descripcion,
				planillaLecturas: (dto.planillaLecturas ?? []) as Prisma.InputJsonValue,
				observaciones: dto.observaciones,
				...periodicidad,
				tolerancia: dto.tolerancia ?? 0,
				duracionEstimada: dto.duracionEstimada,
				hsHombre: dto.hsHombre,
				cantOperarios: dto.cantOperarios,
				indisponibilidadEstimada: dto.indisponibilidadEstimada,
				costoEstimado: dto.costoEstimado,
			},
			include: PROCEDIMIENTO_INCLUDE,
		});
	}

	async update(id: string, dto: UpdateProcedimientoDto, currentUser: AuthUser) {
		const existing = await this.findOne(id, currentUser);
		const tipo = dto.tipo ?? existing.tipo;

		if (dto.sectorResponsableId !== undefined) {
			await this.assertSectorResponsable(
				dto.sectorResponsableId,
				existing.sucursalId,
			);
		}

		this.assertPeriodicidad(tipo, {
			...dto,
			periodicidadTipo:
				dto.periodicidadTipo ?? existing.periodicidadTipo ?? undefined,
			periodicidadValor:
				dto.periodicidadValor ?? existing.periodicidadValor ?? undefined,
			criterioProgramacion:
				dto.criterioProgramacion ??
				existing.criterioProgramacion ??
				undefined,
		});

		const periodicidad = this.resolvePeriodicidad(tipo, dto, existing);

		return this.prisma.procedimiento.update({
			where: { id: existing.id },
			data: {
				...(dto.sectorResponsableId !== undefined
					? { sectorResponsableId: dto.sectorResponsableId }
					: {}),
				nombre: dto.nombre,
				tipo: dto.tipo,
				descripcion: dto.descripcion,
				planillaLecturas: dto.planillaLecturas as Prisma.InputJsonValue | undefined,
				observaciones: dto.observaciones,
				...periodicidad,
				tolerancia: dto.tolerancia,
				duracionEstimada: dto.duracionEstimada,
				hsHombre: dto.hsHombre,
				cantOperarios: dto.cantOperarios,
				indisponibilidadEstimada: dto.indisponibilidadEstimada,
				costoEstimado: dto.costoEstimado,
				activo: dto.activo,
				versionActual:
					dto.planillaLecturas !== undefined
						? existing.versionActual + 1
						: undefined,
			},
			include: PROCEDIMIENTO_INCLUDE,
		});
	}

	async asociarEquipo(
		id: string,
		dto: AsociarEquipoDto,
		currentUser: AuthUser,
	) {
		const procedimiento = await this.findOne(id, currentUser);

		const equipo = await this.prisma.equipo.findUnique({
			where: { id: dto.equipoId },
		});

		if (!equipo || !equipo.activo) {
			throw new BadRequestException('Equipo inválido');
		}

		assertSucursalAccess(currentUser, equipo.sucursalId);

		if (equipo.sucursalId !== procedimiento.sucursalId) {
			throw new BadRequestException(
				'El equipo no pertenece a la misma sucursal del procedimiento',
			);
		}

		const asociacion = await this.prisma.procedimientoEquipo.upsert({
			where: {
				procedimientoId_equipoId: {
					procedimientoId: id,
					equipoId: dto.equipoId,
				},
			},
			update: { estado: 'activo' },
			create: {
				procedimientoId: id,
				equipoId: dto.equipoId,
			},
			include: {
				equipo: { include: { ubicacion: true } },
			},
		});

		if (
			dto.emitirPrimeraOt &&
			procedimiento.tipo === 'preventivo' &&
			procedimiento.periodicidadTipo &&
			procedimiento.periodicidadValor
		) {
			const fecha =
				dto.fechaProgramacion ?? new Date().toISOString().slice(0, 10);

			await this.otService.emitirPeriodica(
				{
					sucursalId: procedimiento.sucursalId,
					procedimientoId: id,
					equipoId: dto.equipoId,
					tecnicoAsignadoId: dto.tecnicoAsignadoId,
					fechaProgramacion: fecha,
					comentarios: `Primera OT periódica — ${procedimiento.nombre}`,
				},
				currentUser,
			);
		}

		return asociacion;
	}

	async desasociarEquipo(
		id: string,
		dto: DesasociarEquipoDto,
		currentUser: AuthUser,
	) {
		await this.findOne(id, currentUser);

		const asociacion = await this.prisma.procedimientoEquipo.findUnique({
			where: {
				procedimientoId_equipoId: {
					procedimientoId: id,
					equipoId: dto.equipoId,
				},
			},
		});

		if (!asociacion) {
			throw new NotFoundException('Asociación no encontrada');
		}

		return this.prisma.procedimientoEquipo.update({
			where: { id: asociacion.id },
			data: { estado: 'baja' },
		});
	}

	async asociarAlcance(
		id: string,
		dto: AsociarAlcanceDto,
		currentUser: AuthUser,
	) {
		const procedimiento = await this.findOne(id, currentUser);

		if (dto.tipo === 'ubicacion') {
			const ubicacion = await this.prisma.ubicacion.findUnique({
				where: { id: dto.targetId },
			});

			if (!ubicacion || !ubicacion.activa) {
				throw new BadRequestException('Ubicación inválida');
			}

			assertSucursalAccess(currentUser, ubicacion.sucursalId);

			if (ubicacion.sucursalId !== procedimiento.sucursalId) {
				throw new BadRequestException(
					'La ubicación no pertenece a la misma sucursal del procedimiento',
				);
			}

			const alcance = await this.prisma.procedimientoAlcance.upsert({
				where: {
					procedimientoId_ubicacionId: {
						procedimientoId: id,
						ubicacionId: dto.targetId,
					},
				},
				update: { estado: 'activo' },
				create: {
					procedimientoId: id,
					tipo: 'ubicacion',
					ubicacionId: dto.targetId,
				},
				include: {
					ubicacion: true,
					sucursalAlcance: true,
				},
			});

			await this.materializarEquiposPreventivos(procedimiento, {
				ubicacionId: dto.targetId,
			});

			return alcance;
		}

		const sucursal = await this.prisma.sucursal.findUnique({
			where: { id: dto.targetId },
		});

		if (!sucursal || !sucursal.activa) {
			throw new BadRequestException('Planta inválida');
		}

		assertSucursalAccess(currentUser, sucursal.id);

		if (sucursal.id !== procedimiento.sucursalId) {
			throw new BadRequestException(
				'La planta no coincide con la sucursal del procedimiento',
			);
		}

		const alcance = await this.prisma.procedimientoAlcance.upsert({
			where: {
				procedimientoId_sucursalAlcanceId: {
					procedimientoId: id,
					sucursalAlcanceId: dto.targetId,
				},
			},
			update: { estado: 'activo', tipo: 'planta' },
			create: {
				procedimientoId: id,
				tipo: 'planta',
				sucursalAlcanceId: dto.targetId,
			},
			include: {
				ubicacion: true,
				sucursalAlcance: true,
			},
		});

		await this.materializarEquiposPreventivos(procedimiento, {});

		return alcance;
	}

	async desasociarAlcance(
		id: string,
		dto: DesasociarAlcanceDto,
		currentUser: AuthUser,
	) {
		await this.findOne(id, currentUser);

		const asociacion = await this.prisma.procedimientoAlcance.findUnique({
			where: { id: dto.alcanceId },
		});

		if (!asociacion || asociacion.procedimientoId !== id) {
			throw new NotFoundException('Asociación no encontrada');
		}

		return this.prisma.procedimientoAlcance.update({
			where: { id: dto.alcanceId },
			data: { estado: 'baja' },
		});
	}

	private async materializarEquiposPreventivos(
		procedimiento: {
			id: string;
			sucursalId: string;
			tipo: TipoMantenimiento;
			periodicidadTipo: PeriodicidadTipo | null;
			periodicidadValor: number | null;
		},
		options: { ubicacionId?: string },
	) {
		if (
			procedimiento.tipo !== 'preventivo' ||
			procedimiento.periodicidadTipo !== 'tiempo' ||
			!procedimiento.periodicidadValor
		) {
			return;
		}

		const ubicacionIds = options.ubicacionId
			? await this.collectDescendantUbicacionIds(
					procedimiento.sucursalId,
					options.ubicacionId,
				)
			: undefined;

		const equipos = await this.prisma.equipo.findMany({
			where: {
				activo: true,
				fueraDeServicio: false,
				sucursalId: procedimiento.sucursalId,
				ubicacionId: ubicacionIds ? { in: ubicacionIds } : undefined,
			},
			select: { id: true },
		});

		for (const equipo of equipos) {
			await this.prisma.procedimientoEquipo.upsert({
				where: {
					procedimientoId_equipoId: {
						procedimientoId: procedimiento.id,
						equipoId: equipo.id,
					},
				},
				update: { estado: 'activo' },
				create: {
					procedimientoId: procedimiento.id,
					equipoId: equipo.id,
				},
			});
		}
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

	private async assertSectorResponsable(
		sectorResponsableId: string | null | undefined,
		sucursalId: string,
	) {
		if (!sectorResponsableId) return;

		const sector = await this.prisma.ubicacion.findUnique({
			where: { id: sectorResponsableId },
		});

		if (!sector || !sector.activa || sector.sucursalId !== sucursalId) {
			throw new BadRequestException('Sector responsable inválido');
		}
	}

	private assertPeriodicidad(
		tipo: TipoMantenimiento,
		dto: {
			periodicidadTipo?: string | null;
			periodicidadValor?: number | null;
			criterioProgramacion?: string | null;
		},
	) {
		if (tipo === 'preventivo_no_periodico') {
			if (dto.periodicidadTipo || dto.periodicidadValor) {
				throw new BadRequestException(
					'El preventivo no periódico no admite periodicidad',
				);
			}
			return;
		}

		if (tipo !== 'preventivo') return;

		if (!dto.periodicidadTipo || !dto.periodicidadValor) {
			throw new BadRequestException(
				'Los procedimientos preventivos requieren periodicidad en días',
			);
		}

		if (dto.periodicidadTipo !== 'tiempo') {
			throw new BadRequestException(
				'Por ahora solo se admite periodicidad por tiempo (días)',
			);
		}

		if (!dto.criterioProgramacion) {
			throw new BadRequestException(
				'Debe indicar el criterio de programación (inicio o finalización)',
			);
		}
	}
}
