import {
	BadRequestException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { assertSucursalAccess, resolveSucursalId } from '../planta.scope';
import { CreateUbicacionDto } from './dto/create-ubicacion.dto';
import { MoverUbicacionDto } from './dto/mover-ubicacion.dto';
import { UpdateUbicacionDto } from './dto/update-ubicacion.dto';

@Injectable()
export class UbicacionesService {
	constructor(private readonly prisma: PrismaService) {}

	async getTree(currentUser: AuthUser, sucursalIdQuery?: string) {
		const sucursalId = resolveSucursalId(currentUser, sucursalIdQuery);
		const nodes = await this.prisma.ubicacion.findMany({
			where: { sucursalId, activa: true },
			orderBy: [{ orden: 'asc' }, { nombre: 'asc' }],
			include: {
				_count: { select: { equipos: true, children: true } },
			},
		});

		type TreeNode = (typeof nodes)[number] & { children: TreeNode[] };
		const map = new Map<string, TreeNode>();
		const roots: TreeNode[] = [];

		for (const node of nodes) {
			map.set(node.id, { ...node, children: [] });
		}

		for (const node of nodes) {
			const current = map.get(node.id)!;
			if (node.parentId && map.has(node.parentId)) {
				map.get(node.parentId)!.children.push(current);
			} else {
				roots.push(current);
			}
		}

		return roots;
	}

	async create(dto: CreateUbicacionDto, currentUser: AuthUser) {
		const sucursalId = resolveSucursalId(currentUser, dto.sucursalId);

		if (dto.parentId) {
			const parent = await this.prisma.ubicacion.findUnique({
				where: { id: dto.parentId },
			});
			if (!parent || parent.sucursalId !== sucursalId) {
				throw new BadRequestException('Ubicación padre inválida');
			}

			const equiposEnPadre = await this.prisma.equipo.count({
				where: { ubicacionId: dto.parentId, activo: true },
			});
			if (equiposEnPadre > 0) {
				throw new BadRequestException(
					'No se puede agregar un nodo bajo una ubicación que ya tiene equipos',
				);
			}
		}

		return this.prisma.ubicacion.create({
			data: {
				sucursalId,
				parentId: dto.parentId,
				nombre: dto.nombre,
				orden: dto.orden ?? 0,
			},
		});
	}

	async update(id: string, dto: UpdateUbicacionDto, currentUser: AuthUser) {
		const ubicacion = await this.findOneOrFail(id);
		assertSucursalAccess(currentUser, ubicacion.sucursalId);

		return this.prisma.ubicacion.update({
			where: { id },
			data: dto,
		});
	}

	async remove(id: string, currentUser: AuthUser) {
		const ubicacion = await this.findOneOrFail(id);
		assertSucursalAccess(currentUser, ubicacion.sucursalId);

		const children = await this.prisma.ubicacion.count({
			where: { parentId: id, activa: true },
		});
		if (children > 0) {
			throw new BadRequestException('La ubicación tiene nodos hijos');
		}

		const equipos = await this.prisma.equipo.count({
			where: { ubicacionId: id, activo: true },
		});
		if (equipos > 0) {
			throw new BadRequestException('La ubicación tiene equipos asignados');
		}

		return this.prisma.ubicacion.update({
			where: { id },
			data: { activa: false },
		});
	}

	async mover(id: string, dto: MoverUbicacionDto, currentUser: AuthUser) {
		const ubicacion = await this.findOneOrFail(id);
		assertSucursalAccess(currentUser, ubicacion.sucursalId);

		if (dto.parentId === id) {
			throw new BadRequestException('No se puede mover un nodo bajo sí mismo');
		}

		if (dto.parentId) {
			const parent = await this.findOneOrFail(dto.parentId);
			if (parent.sucursalId !== ubicacion.sucursalId) {
				throw new BadRequestException('El padre debe ser de la misma sucursal');
			}

			if (await this.isDescendant(dto.parentId, id)) {
				throw new BadRequestException('No se puede mover bajo un descendiente');
			}

			const equiposEnPadre = await this.prisma.equipo.count({
				where: { ubicacionId: dto.parentId, activo: true },
			});
			if (equiposEnPadre > 0) {
				throw new BadRequestException(
					'El destino tiene equipos; no puede ser padre',
				);
			}
		}

		return this.prisma.ubicacion.update({
			where: { id },
			data: {
				parentId: dto.parentId === undefined ? undefined : dto.parentId,
				orden: dto.orden,
			},
		});
	}

	async findOneOrFail(id: string) {
		const ubicacion = await this.prisma.ubicacion.findUnique({ where: { id } });
		if (!ubicacion) {
			throw new NotFoundException('Ubicación no encontrada');
		}
		return ubicacion;
	}

	async collectDescendantUbicacionIds(
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

	async getProcedimientosPorAlcance(
		currentUser: AuthUser,
		query: { sucursalId?: string; ubicacionId?: string; equipoId?: string },
	) {
		const sucursalId = resolveSucursalId(currentUser, query.sucursalId);

		if (query.equipoId) {
			const equipo = await this.prisma.equipo.findUnique({
				where: { id: query.equipoId },
			});
			if (!equipo || equipo.sucursalId !== sucursalId) {
				throw new NotFoundException('Equipo no encontrado');
			}

			return this.prisma.procedimientoEquipo.findMany({
				where: { equipoId: query.equipoId, estado: 'activo' },
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

		if (query.ubicacionId) {
			const ubicacion = await this.findOneOrFail(query.ubicacionId);
			assertSucursalAccess(currentUser, ubicacion.sucursalId);

			return this.prisma.procedimientoAlcance.findMany({
				where: {
					ubicacionId: query.ubicacionId,
					estado: 'activo',
					procedimiento: { sucursalId, activo: true },
				},
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
					ubicacion: { select: { id: true, nombre: true } },
				},
				orderBy: { procedimiento: { codigo: 'asc' } },
			});
		}

		return this.prisma.procedimientoAlcance.findMany({
			where: {
				sucursalAlcanceId: sucursalId,
				estado: 'activo',
				procedimiento: { activo: true },
			},
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
				sucursalAlcance: { select: { id: true, nombre: true } },
			},
			orderBy: { procedimiento: { codigo: 'asc' } },
		});
	}

	private async isDescendant(nodeId: string, ancestorId: string): Promise<boolean> {
		let current = await this.prisma.ubicacion.findUnique({ where: { id: nodeId } });
		while (current?.parentId) {
			if (current.parentId === ancestorId) {
				return true;
			}
			current = await this.prisma.ubicacion.findUnique({
				where: { id: current.parentId },
			});
		}
		return false;
	}
}
