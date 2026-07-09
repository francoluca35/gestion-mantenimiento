import {
	BadRequestException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { resolveSucursalId } from '../mantenimiento.scope';
import { PrismaService } from '../../../database/prisma.service';
import { CreateMotivoOtPendienteDto } from './dto/create-motivo-ot-pendiente.dto';
import { UpdateMotivoOtPendienteDto } from './dto/update-motivo-ot-pendiente.dto';

@Injectable()
export class MotivosOtPendienteService {
	constructor(private readonly prisma: PrismaService) {}

	async findAll(currentUser: AuthUser, sucursalIdQuery?: string) {
		const sucursalId = resolveSucursalId(currentUser, sucursalIdQuery);

		return this.prisma.motivoOtPendiente.findMany({
			where: { sucursalId, activo: true },
			orderBy: [{ orden: 'asc' }, { descripcion: 'asc' }],
		});
	}

	async create(
		dto: CreateMotivoOtPendienteDto,
		currentUser: AuthUser,
		sucursalIdQuery?: string,
	) {
		const sucursalId = resolveSucursalId(currentUser, sucursalIdQuery);

		return this.prisma.motivoOtPendiente.create({
			data: {
				sucursalId,
				codigo: dto.codigo.trim().toUpperCase(),
				descripcion: dto.descripcion.trim(),
				orden: dto.orden ?? 0,
			},
		});
	}

	async update(
		id: string,
		dto: UpdateMotivoOtPendienteDto,
		currentUser: AuthUser,
	) {
		const motivo = await this.prisma.motivoOtPendiente.findUnique({
			where: { id },
		});
		if (!motivo) {
			throw new NotFoundException('Motivo no encontrado');
		}

		resolveSucursalId(currentUser, motivo.sucursalId);

		return this.prisma.motivoOtPendiente.update({
			where: { id },
			data: {
				codigo: dto.codigo?.trim().toUpperCase(),
				descripcion: dto.descripcion?.trim(),
				activo: dto.activo,
				orden: dto.orden,
			},
		});
	}

	async remove(id: string, currentUser: AuthUser) {
		const motivo = await this.prisma.motivoOtPendiente.findUnique({
			where: { id },
			include: { _count: { select: { ordenesTrabajo: true } } },
		});
		if (!motivo) {
			throw new NotFoundException('Motivo no encontrado');
		}

		resolveSucursalId(currentUser, motivo.sucursalId);

		if (motivo._count.ordenesTrabajo > 0) {
			return this.prisma.motivoOtPendiente.update({
				where: { id },
				data: { activo: false },
			});
		}

		return this.prisma.motivoOtPendiente.delete({ where: { id } });
	}

	async assertMotivoDeSucursal(motivoId: string, sucursalId: string) {
		const motivo = await this.prisma.motivoOtPendiente.findFirst({
			where: { id: motivoId, sucursalId, activo: true },
		});
		if (!motivo) {
			throw new BadRequestException('Motivo de pendiente inválido');
		}
		return motivo;
	}
}
