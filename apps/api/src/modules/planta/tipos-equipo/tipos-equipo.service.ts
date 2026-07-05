import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import { CreateTipoEquipoDto } from './dto/create-tipo-equipo.dto';
import { UpdateTipoEquipoDto } from './dto/update-tipo-equipo.dto';

@Injectable()
export class TiposEquipoService {
	constructor(private readonly prisma: PrismaService) {}

	findAll() {
		return this.prisma.tipoEquipo.findMany({
			where: { activo: true },
			orderBy: { nombre: 'asc' },
			include: { _count: { select: { equipos: true } } },
		});
	}

	async findOne(id: string) {
		const tipo = await this.prisma.tipoEquipo.findUnique({ where: { id } });
		if (!tipo) {
			throw new NotFoundException('Tipo de equipo no encontrado');
		}
		return tipo;
	}

	create(dto: CreateTipoEquipoDto) {
		return this.prisma.tipoEquipo.create({
			data: {
				nombre: dto.nombre,
				camposDetalle: (dto.camposDetalle ?? []) as Prisma.InputJsonValue,
				camposLectura: (dto.camposLectura ?? []) as Prisma.InputJsonValue,
			},
		});
	}

	async update(id: string, dto: UpdateTipoEquipoDto) {
		await this.findOne(id);
		return this.prisma.tipoEquipo.update({
			where: { id },
			data: {
				nombre: dto.nombre,
				activo: dto.activo,
				camposDetalle:
					dto.camposDetalle === undefined
						? undefined
						: (dto.camposDetalle as Prisma.InputJsonValue),
				camposLectura:
					dto.camposLectura === undefined
						? undefined
						: (dto.camposLectura as Prisma.InputJsonValue),
			},
		});
	}
}
