import {
	BadRequestException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { OtService } from '../ot/ot.service';
import { assertSucursalAccess, resolveSucursalId } from '../mantenimiento.scope';
import { ConformidadSolicitudDto } from './dto/conformidad-solicitud.dto';
import { CreateSolicitudTrabajoDto } from './dto/create-solicitud-trabajo.dto';
import { EmitirOtDesdeSolicitudDto } from './dto/emitir-ot-desde-solicitud.dto';

@Injectable()
export class SolicitudesTrabajoService {
	constructor(
		private readonly prisma: PrismaService,
		private readonly otService: OtService,
	) {}

	async findAll(currentUser: AuthUser, sucursalIdQuery?: string) {
		const sucursalId = resolveSucursalId(currentUser, sucursalIdQuery);

		return this.prisma.solicitudTrabajo.findMany({
			where: { sucursalId },
			include: {
				otGenerada: {
					include: {
						equipo: true,
						tecnicoAsignado: {
							select: { id: true, nombreUsuario: true },
						},
					},
				},
			},
			orderBy: { createdAt: 'desc' },
		});
	}

	async create(dto: CreateSolicitudTrabajoDto, currentUser: AuthUser) {
		const sucursalId = resolveSucursalId(currentUser, dto.sucursalId);

		return this.prisma.solicitudTrabajo.create({
			data: {
				sucursalId,
				solicitante: dto.solicitante,
				descripcion: dto.descripcion,
				urgente: dto.urgente ?? false,
			},
		});
	}

	async darConformidad(
		id: string,
		dto: ConformidadSolicitudDto,
		currentUser: AuthUser,
	) {
		const solicitud = await this.findOneOrFail(id);
		assertSucursalAccess(currentUser, solicitud.sucursalId);

		if (solicitud.estado !== 'pendiente') {
			throw new BadRequestException('La solicitud ya fue procesada');
		}

		return this.prisma.solicitudTrabajo.update({
			where: { id },
			data: {
				estado: dto.conforme ? 'conformada' : 'rechazada',
				calificacion: dto.conforme ? dto.calificacion : null,
				observaciones: dto.observaciones,
			},
		});
	}

	async emitirOt(
		id: string,
		dto: EmitirOtDesdeSolicitudDto,
		currentUser: AuthUser,
	) {
		const solicitud = await this.findOneOrFail(id);
		assertSucursalAccess(currentUser, solicitud.sucursalId);

		if (solicitud.estado !== 'conformada') {
			throw new BadRequestException('La solicitud debe estar conformada');
		}

		if (solicitud.otGeneradaId) {
			throw new BadRequestException('La solicitud ya tiene OT generada');
		}

		const ot = await this.otService.emitir(
			{
				sucursalId: solicitud.sucursalId,
				equipoId: dto.equipoId,
				procedimientoId: dto.procedimientoId,
				tipo: dto.tipo,
				tecnicoAsignadoId: dto.tecnicoAsignadoId,
				fechaProgramacion: dto.fechaProgramacion,
				prioridad: dto.prioridad,
				comentarios: `Generada desde solicitud: ${solicitud.descripcion}`,
				notificarAsignacion: dto.notificarAsignacion,
			},
			currentUser,
		);

		await this.prisma.solicitudTrabajo.update({
			where: { id },
			data: { otGeneradaId: ot.id },
		});

		return ot;
	}

	private async findOneOrFail(id: string) {
		const solicitud = await this.prisma.solicitudTrabajo.findUnique({
			where: { id },
		});

		if (!solicitud) {
			throw new NotFoundException('Solicitud no encontrada');
		}

		return solicitud;
	}
}
