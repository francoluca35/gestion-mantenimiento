import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { assertSucursalAccess } from '../planta.scope';
import { CreateComponenteDto } from './dto/create-componente.dto';
import { UpdateComponenteDto } from './dto/update-componente.dto';

@Injectable()
export class ComponentesService {
	constructor(private readonly prisma: PrismaService) {}

	private async assertEquipo(equipoId: string, currentUser: AuthUser) {
		const equipo = await this.prisma.equipo.findUnique({ where: { id: equipoId } });
		if (!equipo) {
			throw new NotFoundException('Equipo no encontrado');
		}
		assertSucursalAccess(currentUser, equipo.sucursalId);
		return equipo;
	}

	async findAll(equipoId: string, currentUser: AuthUser) {
		await this.assertEquipo(equipoId, currentUser);
		return this.prisma.componente.findMany({
			where: { equipoId, activo: true },
			orderBy: [{ nombre: 'asc' }],
		});
	}

	async create(equipoId: string, dto: CreateComponenteDto, currentUser: AuthUser) {
		await this.assertEquipo(equipoId, currentUser);
		return this.prisma.componente.create({
			data: {
				equipoId,
				nombre: dto.nombre,
				codigo: dto.codigo,
				detalle: (dto.detalle ?? {}) as Prisma.InputJsonValue,
			},
		});
	}

	async update(
		equipoId: string,
		componenteId: string,
		dto: UpdateComponenteDto,
		currentUser: AuthUser,
	) {
		await this.assertEquipo(equipoId, currentUser);
		const existing = await this.prisma.componente.findFirst({
			where: { id: componenteId, equipoId },
		});
		if (!existing) {
			throw new NotFoundException('Componente no encontrado');
		}

		return this.prisma.componente.update({
			where: { id: componenteId },
			data: {
				nombre: dto.nombre,
				codigo: dto.codigo,
				detalle:
					dto.detalle === undefined
						? undefined
						: (dto.detalle as Prisma.InputJsonValue),
			},
		});
	}

	async remove(equipoId: string, componenteId: string, currentUser: AuthUser) {
		await this.assertEquipo(equipoId, currentUser);
		const existing = await this.prisma.componente.findFirst({
			where: { id: componenteId, equipoId },
		});
		if (!existing) {
			throw new NotFoundException('Componente no encontrado');
		}

		return this.prisma.componente.update({
			where: { id: componenteId },
			data: { activo: false },
		});
	}
}
