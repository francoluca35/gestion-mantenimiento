import {
	BadRequestException,
	ConflictException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { assertSucursalAccess, resolveSucursalId } from '../planta.scope';
import { CreateEquipoDto } from './dto/create-equipo.dto';
import { DuplicarEquipoDto } from './dto/duplicar-equipo.dto';
import { MoverEquipoDto } from './dto/mover-equipo.dto';
import { PegarEquipoDto } from './dto/pegar-equipo.dto';
import { UpdateEquipoDto } from './dto/update-equipo.dto';

@Injectable()
export class EquiposService {
	constructor(private readonly prisma: PrismaService) {}

	async findAll(
		currentUser: AuthUser,
		filters: {
			sucursalId?: string;
			ubicacionId?: string;
			tipoEquipoId?: string;
			activo?: boolean;
		},
	) {
		const sucursalId = resolveSucursalId(currentUser, filters.sucursalId);

		return this.prisma.equipo.findMany({
			where: {
				sucursalId,
				ubicacionId: filters.ubicacionId,
				tipoEquipoId: filters.tipoEquipoId,
				activo: filters.activo ?? true,
			},
			include: {
				ubicacion: true,
				tipoEquipo: true,
			},
			orderBy: [{ codigo: 'asc' }],
		});
	}

	async findOne(id: string, currentUser: AuthUser) {
		const equipo = await this.prisma.equipo.findUnique({
			where: { id },
			include: {
				ubicacion: true,
				tipoEquipo: true,
				componentes: { where: { activo: true } },
				lecturas: {
					orderBy: { fecha: 'desc' },
					take: 10,
				},
			},
		});

		if (!equipo) {
			throw new NotFoundException('Equipo no encontrado');
		}

		assertSucursalAccess(currentUser, equipo.sucursalId);
		return equipo;
	}

	async create(dto: CreateEquipoDto, currentUser: AuthUser) {
		const ubicacion = await this.prisma.ubicacion.findUnique({
			where: { id: dto.ubicacionId },
			include: { _count: { select: { children: true } } },
		});

		if (!ubicacion || !ubicacion.activa) {
			throw new BadRequestException('Ubicación inválida');
		}

		assertSucursalAccess(currentUser, ubicacion.sucursalId);

		if (ubicacion._count.children > 0) {
			throw new BadRequestException(
				'El equipo solo puede colgarse de un nodo hoja (sin hijos)',
			);
		}

		const tipo = await this.prisma.tipoEquipo.findUnique({
			where: { id: dto.tipoEquipoId },
		});
		if (!tipo || !tipo.activo) {
			throw new BadRequestException('Tipo de equipo inválido');
		}

		const sucursalId = resolveSucursalId(currentUser, dto.sucursalId ?? ubicacion.sucursalId);
		if (sucursalId !== ubicacion.sucursalId) {
			throw new BadRequestException('La ubicación no pertenece a la sucursal');
		}

		try {
			return await this.prisma.equipo.create({
				data: {
					sucursalId,
					ubicacionId: dto.ubicacionId,
					tipoEquipoId: dto.tipoEquipoId,
					nombre: dto.nombre,
					codigo: dto.codigo,
					detalle: (dto.detalle ?? {}) as Prisma.InputJsonValue,
				},
				include: {
					ubicacion: true,
					tipoEquipo: true,
				},
			});
		} catch (error) {
			if (
				error instanceof Prisma.PrismaClientKnownRequestError &&
				error.code === 'P2002'
			) {
				throw new ConflictException('Ya existe un equipo con ese código en la sucursal');
			}
			throw error;
		}
	}

	async update(id: string, dto: UpdateEquipoDto, currentUser: AuthUser) {
		const existing = await this.findOne(id, currentUser);

		try {
			return await this.prisma.equipo.update({
				where: { id: existing.id },
				data: {
					nombre: dto.nombre,
					codigo: dto.codigo,
					activo: dto.activo,
					detalle:
						dto.detalle === undefined
							? undefined
							: (dto.detalle as Prisma.InputJsonValue),
				},
				include: {
					ubicacion: true,
					tipoEquipo: true,
				},
			});
		} catch (error) {
			if (
				error instanceof Prisma.PrismaClientKnownRequestError &&
				error.code === 'P2002'
			) {
				throw new ConflictException('Ya existe un equipo con ese código en la sucursal');
			}
			throw error;
		}
	}

	async remove(id: string, currentUser: AuthUser) {
		const equipo = await this.findOne(id, currentUser);

		const otCount = await this.prisma.ordenTrabajo.count({
			where: { equipoId: id },
		});

		if (otCount > 0) {
			throw new BadRequestException(
				'No se puede dar de baja: la máquina tiene órdenes de trabajo asociadas',
			);
		}

		return this.prisma.equipo.update({
			where: { id: equipo.id },
			data: { activo: false },
			include: {
				ubicacion: true,
				tipoEquipo: true,
			},
		});
	}

	async mover(id: string, dto: MoverEquipoDto, currentUser: AuthUser) {
		const equipo = await this.findOne(id, currentUser);
		const ubicacion = await this.prisma.ubicacion.findUnique({
			where: { id: dto.ubicacionId },
			include: { _count: { select: { children: true } } },
		});

		if (!ubicacion || ubicacion.sucursalId !== equipo.sucursalId) {
			throw new BadRequestException('Ubicación destino inválida');
		}

		if (ubicacion._count.children > 0) {
			throw new BadRequestException('El destino debe ser un nodo hoja');
		}

		return this.prisma.equipo.update({
			where: { id },
			data: { ubicacionId: dto.ubicacionId },
			include: {
				ubicacion: true,
				tipoEquipo: true,
			},
		});
	}

	async marcarFueraDeServicio(id: string, fuera: boolean, currentUser: AuthUser) {
		await this.findOne(id, currentUser);
		return this.prisma.equipo.update({
			where: { id },
			data: {
				fueraDeServicio: fuera,
				fechaBaja: fuera ? new Date() : null,
			},
			include: {
				ubicacion: true,
				tipoEquipo: true,
			},
		});
	}

	async getHistorial(id: string, currentUser: AuthUser) {
		await this.findOne(id, currentUser);

		return this.prisma.historialEquipo.findMany({
			where: { equipoId: id },
			include: {
				usuario: { select: { id: true, nombreUsuario: true } },
				ot: { select: { id: true, numero: true, estado: true } },
			},
			orderBy: { fecha: 'desc' },
			take: 50,
		});
	}

	async getProcedimientos(id: string, currentUser: AuthUser) {
		await this.findOne(id, currentUser);

		return this.prisma.procedimientoEquipo.findMany({
			where: { equipoId: id, estado: 'activo' },
			include: {
				procedimiento: {
					select: {
						id: true,
						codigo: true,
						nombre: true,
						tipo: true,
						periodicidadTipo: true,
						periodicidadValor: true,
					},
				},
			},
			orderBy: { procedimiento: { codigo: 'asc' } },
		});
	}

	private async generarCodigoDuplicado(codigo: string, sucursalId: string) {
		let candidate = `${codigo}-C`;
		let n = 1;
		while (
			await this.prisma.equipo.findFirst({
				where: { sucursalId, codigo: candidate },
			})
		) {
			n++;
			candidate = `${codigo}-C${n}`;
		}
		return candidate;
	}

	async duplicar(id: string, dto: DuplicarEquipoDto, currentUser: AuthUser) {
		const source = await this.findOne(id, currentUser);
		const ubicacionId = dto.ubicacionId ?? source.ubicacionId;

		const ubicacion = await this.prisma.ubicacion.findUnique({
			where: { id: ubicacionId },
			include: { _count: { select: { children: true } } },
		});

		if (!ubicacion || ubicacion.sucursalId !== source.sucursalId) {
			throw new BadRequestException('Ubicación destino inválida');
		}

		if (ubicacion._count.children > 0) {
			throw new BadRequestException('El destino debe ser un nodo hoja');
		}

		const nuevoCodigo = await this.generarCodigoDuplicado(source.codigo, source.sucursalId);

		const equipo = await this.prisma.equipo.create({
			data: {
				sucursalId: source.sucursalId,
				ubicacionId,
				tipoEquipoId: source.tipoEquipoId,
				nombre: `${source.nombre} (copia)`,
				codigo: nuevoCodigo,
				detalle: source.detalle as Prisma.InputJsonValue,
			},
			include: {
				ubicacion: true,
				tipoEquipo: true,
			},
		});

		if (source.componentes.length > 0) {
			await this.prisma.componente.createMany({
				data: source.componentes.map((componente) => ({
					equipoId: equipo.id,
					nombre: componente.nombre,
					codigo: componente.codigo,
					detalle: componente.detalle as Prisma.InputJsonValue,
				})),
			});
		}

		return equipo;
	}

	async pegarComoComponentes(
		targetEquipoId: string,
		dto: PegarEquipoDto,
		currentUser: AuthUser,
	) {
		const target = await this.findOne(targetEquipoId, currentUser);
		const source = await this.findOne(dto.sourceEquipoId, currentUser);

		if (target.id === source.id) {
			throw new BadRequestException('No se puede pegar un equipo sobre sí mismo');
		}

		if (target.sucursalId !== source.sucursalId) {
			throw new BadRequestException('Los equipos deben pertenecer a la misma planta');
		}

		const sourceDetalle =
			typeof source.detalle === 'object' && source.detalle !== null
				? (source.detalle as Record<string, unknown>)
				: {};

		await this.prisma.componente.createMany({
			data: [
				{
					equipoId: target.id,
					nombre: source.nombre,
					codigo: source.codigo,
					detalle: {
						...sourceDetalle,
						origenEquipoId: source.id,
					} as Prisma.InputJsonValue,
				},
				...source.componentes.map((componente) => ({
					equipoId: target.id,
					nombre: componente.nombre,
					codigo: componente.codigo,
					detalle: componente.detalle as Prisma.InputJsonValue,
				})),
			],
		});

		return this.findOne(target.id, currentUser);
	}
}
