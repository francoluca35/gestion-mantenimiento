import { Injectable, ForbiddenException, Logger } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { OtService } from '../../mantenimiento/ot/ot.service';
import { EquiposService } from '../equipos/equipos.service';
import { CreateLecturaDto } from './dto/create-lectura.dto';
import { ReiniciarLecturaDto } from './dto/reiniciar-lectura.dto';

@Injectable()
export class LecturasService {
	private readonly logger = new Logger(LecturasService.name);

	constructor(
		private readonly prisma: PrismaService,
		private readonly equiposService: EquiposService,
		private readonly otService: OtService,
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
		const lectura = await this.prisma.lectura.create({
			data: {
				equipoId,
				usuarioId: currentUser.id,
				tipo: dto.tipo,
				valor: dto.valor,
				notas: dto.notas,
			},
		});

		try {
			const emitidas = await this.otService.emitirPorContadorEquipo(equipoId);
			if (emitidas.emitidas > 0) {
				this.logger.log(
					`Contador equipo ${equipoId}: emitidas ${emitidas.emitidas} OT automáticas`,
				);
			}
		} catch (error) {
			this.logger.warn(
				`No se pudo evaluar emisión por contador en ${equipoId}: ${
					error instanceof Error ? error.message : error
				}`,
			);
		}

		return lectura;
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
