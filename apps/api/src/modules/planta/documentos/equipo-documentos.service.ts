import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { assertSucursalAccess } from '../planta.scope';
import { CreateEquipoDocumentoDto } from './dto/create-equipo-documento.dto';

@Injectable()
export class EquipoDocumentosService {
	constructor(private readonly prisma: PrismaService) {}

	async findByEquipo(equipoId: string, currentUser: AuthUser) {
		const equipo = await this.prisma.equipo.findUnique({ where: { id: equipoId } });
		if (!equipo) {
			throw new NotFoundException('Equipo no encontrado');
		}
		assertSucursalAccess(currentUser, equipo.sucursalId);

		return this.prisma.equipoDocumento.findMany({
			where: { equipoId, activo: true },
			orderBy: { createdAt: 'desc' },
			select: {
				id: true,
				nombre: true,
				tipo: true,
				storageKey: true,
				contentType: true,
				tamano: true,
				createdAt: true,
			},
		});
	}

	async create(equipoId: string, dto: CreateEquipoDocumentoDto, currentUser: AuthUser) {
		const equipo = await this.prisma.equipo.findUnique({ where: { id: equipoId } });
		if (!equipo) {
			throw new NotFoundException('Equipo no encontrado');
		}
		assertSucursalAccess(currentUser, equipo.sucursalId);

		return this.prisma.equipoDocumento.create({
			data: {
				equipoId,
				sucursalId: equipo.sucursalId,
				nombre: dto.nombre,
				tipo: dto.tipo ?? 'otro',
				storageKey: dto.storageKey,
				contentType: dto.contentType,
				tamano: dto.tamano,
				creadorId: currentUser.id,
			},
		});
	}

	async remove(equipoId: string, documentoId: string, currentUser: AuthUser) {
		const documento = await this.prisma.equipoDocumento.findFirst({
			where: { id: documentoId, equipoId },
		});
		if (!documento) {
			throw new NotFoundException('Documento no encontrado');
		}
		assertSucursalAccess(currentUser, documento.sucursalId);

		return this.prisma.equipoDocumento.update({
			where: { id: documentoId },
			data: { activo: false },
		});
	}
}
