import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { resolveSucursalId } from '../../planta/planta.scope';
import { CreatePanolDto, UpdatePanolDto } from './dto/panol.dto';

@Injectable()
export class PanolesService {
	constructor(private readonly prisma: PrismaService) {}

	async findAll(currentUser: AuthUser, sucursalIdQuery?: string) {
		const sucursalId = resolveSucursalId(currentUser, sucursalIdQuery);
		return this.prisma.panol.findMany({
			where: { sucursalId, activo: true },
			orderBy: { nombre: 'asc' },
		});
	}

	async create(dto: CreatePanolDto, currentUser: AuthUser) {
		const sucursalId = resolveSucursalId(currentUser, dto.sucursalId);
		return this.prisma.panol.create({
			data: {
				sucursalId,
				nombre: dto.nombre.trim(),
			},
		});
	}

	async update(id: string, dto: UpdatePanolDto, currentUser: AuthUser) {
		const panol = await this.prisma.panol.findUnique({ where: { id } });
		if (!panol) throw new NotFoundException('Pañol no encontrado');
		resolveSucursalId(currentUser, panol.sucursalId);

		return this.prisma.panol.update({
			where: { id },
			data: {
				nombre: dto.nombre?.trim(),
				activo: dto.activo,
			},
		});
	}
}
