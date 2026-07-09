import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { EquiposService } from '../equipos/equipos.service';
import { CreateLecturaDto } from './dto/create-lectura.dto';
import { ReiniciarLecturaDto } from './dto/reiniciar-lectura.dto';

@Injectable()
export class LecturasService {
	constructor(
		private readonly prisma: PrismaService,
		private readonly equiposService: EquiposService,
	) {}

	async findByEquipo(equipoId: string, currentUser: AuthUser) {
		await this.equiposService.findOne(equipoId, currentUser);
		return this.prisma.lectura.findMany({
			where: { equipoId },
			orderBy: { fecha: 'desc' },
			include: {
				usuario: {
					select: { id: true, nombreUsuario: true },
				},
			},
		});
	}

	async create(equipoId: string, dto: CreateLecturaDto, currentUser: AuthUser) {
		await this.equiposService.findOne(equipoId, currentUser);
		return this.prisma.lectura.create({
			data: {
				equipoId,
				usuarioId: currentUser.id,
				tipo: dto.tipo,
				valor: dto.valor,
				notas: dto.notas,
			},
		});
	}

	async reiniciar(
		equipoId: string,
		dto: ReiniciarLecturaDto,
		currentUser: AuthUser,
	) {
		if (!currentUser.esAdministrador) {
			throw new ForbiddenException('Solo administradores pueden reiniciar contadores');
		}

		await this.equiposService.findOne(equipoId, currentUser);
		return this.prisma.lectura.create({
			data: {
				equipoId,
				usuarioId: currentUser.id,
				tipo: dto.tipo,
				valor: dto.valor ?? 0,
				notas: dto.notas ?? 'REINICIO CONTADOR',
			},
		});
	}
}
