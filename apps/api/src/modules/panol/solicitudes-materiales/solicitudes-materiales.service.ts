import {
	BadRequestException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { EstadoOt, EstadoSolicitudMaterial } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import { PushService } from '../../notificaciones/push.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { resolveSucursalId } from '../../planta/planta.scope';
import { StockService } from '../stock/stock.service';
import {
	CreateSolicitudesMaterialesDto,
	RechazarSolicitudMaterialDto,
} from './dto/solicitud-material.dto';

@Injectable()
export class SolicitudesMaterialesService {
	constructor(
		private readonly prisma: PrismaService,
		private readonly stockService: StockService,
		private readonly pushService: PushService,
	) {}

	async findAll(
		currentUser: AuthUser,
		opts?: { estado?: string; otId?: string; sucursalId?: string },
	) {
		const sucursalId = resolveSucursalId(currentUser, opts?.sucursalId);
		return this.prisma.solicitudMaterial.findMany({
			where: {
				panol: { sucursalId },
				...(opts?.estado
					? { estado: opts.estado as EstadoSolicitudMaterial }
					: {}),
				...(opts?.otId ? { otId: opts.otId } : {}),
			},
			include: {
				material: { include: { unidad: true } },
				panol: true,
				ot: {
					select: {
						id: true,
						numero: true,
						estado: true,
						tecnicoAsignadoId: true,
						equipo: { select: { codigo: true, nombre: true } },
					},
				},
				solicitante: { select: { id: true, nombreUsuario: true } },
				panolero: { select: { id: true, nombreUsuario: true } },
			},
			orderBy: [{ estado: 'asc' }, { fechaSolicitud: 'desc' }],
		});
	}

	async crear(dto: CreateSolicitudesMaterialesDto, currentUser: AuthUser) {
		const ot = await this.prisma.ordenTrabajo.findUnique({
			where: { id: dto.otId },
			include: { tecnicoAsignado: true },
		});
		if (!ot) throw new NotFoundException('OT no encontrada');
		resolveSucursalId(currentUser, ot.sucursalId);

		if (!['pendiente', 'en_ejecucion', 'pendiente_panol'].includes(ot.estado)) {
			throw new BadRequestException(
				'Solo se pueden solicitar materiales en OT pendiente o en ejecución',
			);
		}

		const esTecnicoAsignado = ot.tecnicoAsignadoId === currentUser.id;
		const puedeGestionar =
			currentUser.esAdministrador ||
			currentUser.supervisaSucursales ||
			esTecnicoAsignado;
		if (!puedeGestionar) {
			throw new BadRequestException('No podés solicitar materiales para esta OT');
		}

		let panolId = dto.panolId;
		if (!panolId) {
			const panol = await this.prisma.panol.findFirst({
				where: { sucursalId: ot.sucursalId, activo: true },
				orderBy: { nombre: 'asc' },
			});
			if (!panol) {
				throw new BadRequestException('No hay pañol activo en la sucursal');
			}
			panolId = panol.id;
		} else {
			const panol = await this.prisma.panol.findFirst({
				where: { id: panolId, sucursalId: ot.sucursalId, activo: true },
			});
			if (!panol) throw new BadRequestException('Pañol inválido para la sucursal');
		}

		for (const item of dto.items) {
			const material = await this.prisma.material.findFirst({
				where: { id: item.materialId, activo: true },
			});
			if (!material) {
				throw new BadRequestException(`Material inválido: ${item.materialId}`);
			}
		}

		const created = await this.prisma.$transaction(async (tx) => {
			const rows = [];
			for (const item of dto.items) {
				rows.push(
					await tx.solicitudMaterial.create({
						data: {
							otId: ot.id,
							panolId: panolId!,
							materialId: item.materialId,
							cantidadSolicitada: item.cantidad,
							solicitanteId: currentUser.id,
							estado: EstadoSolicitudMaterial.pendiente,
						},
						include: {
							material: { include: { unidad: true } },
							panol: true,
						},
					}),
				);
			}

			if (ot.estado !== EstadoOt.pendiente_panol) {
				await tx.ordenTrabajo.update({
					where: { id: ot.id },
					data: { estado: EstadoOt.pendiente_panol },
				});
				await tx.otEstadoHistorial.create({
					data: {
						otId: ot.id,
						estado: EstadoOt.pendiente_panol,
						usuarioId: currentUser.id,
						comentario: `Solicitud de materiales (${dto.items.length} ítem/s)`,
					},
				});
			}

			return rows;
		});

		void this.notifyPanoleros(
			ot.sucursalId,
			ot.numero,
			dto.items.length,
		);

		return created;
	}

	async aprobar(id: string, currentUser: AuthUser) {
		const solicitud = await this.prisma.solicitudMaterial.findUnique({
			where: { id },
			include: {
				ot: true,
				material: true,
				panol: true,
			},
		});
		if (!solicitud) throw new NotFoundException('Solicitud no encontrada');
		resolveSucursalId(currentUser, solicitud.panol.sucursalId);

		if (solicitud.estado !== EstadoSolicitudMaterial.pendiente) {
			throw new BadRequestException('La solicitud ya fue resuelta');
		}

		const cantidad = Number(solicitud.cantidadSolicitada);

		const updated = await this.prisma.$transaction(async (tx) => {
			await this.stockService.reservarEnTx(tx, {
				panolId: solicitud.panolId,
				materialId: solicitud.materialId,
				cantidad,
				otId: solicitud.otId,
				usuarioId: currentUser.id,
			});

			return tx.solicitudMaterial.update({
				where: { id },
				data: {
					estado: EstadoSolicitudMaterial.aprobado,
					panoleroId: currentUser.id,
					fechaResolucion: new Date(),
				},
				include: {
					material: { include: { unidad: true } },
					panol: true,
					ot: { select: { id: true, numero: true, estado: true } },
				},
			});
		});

		return updated;
	}

	async rechazar(
		id: string,
		dto: RechazarSolicitudMaterialDto,
		currentUser: AuthUser,
	) {
		const motivo = dto.motivo.trim();
		if (!motivo) {
			throw new BadRequestException('El motivo de rechazo es obligatorio');
		}

		const solicitud = await this.prisma.solicitudMaterial.findUnique({
			where: { id },
			include: { panol: true, ot: true },
		});
		if (!solicitud) throw new NotFoundException('Solicitud no encontrada');
		resolveSucursalId(currentUser, solicitud.panol.sucursalId);

		if (solicitud.estado !== EstadoSolicitudMaterial.pendiente) {
			throw new BadRequestException('La solicitud ya fue resuelta');
		}

		const updated = await this.prisma.$transaction(async (tx) => {
			const row = await tx.solicitudMaterial.update({
				where: { id },
				data: {
					estado: EstadoSolicitudMaterial.rechazado,
					panoleroId: currentUser.id,
					fechaResolucion: new Date(),
					motivoRechazo: motivo,
				},
				include: {
					material: { include: { unidad: true } },
					panol: true,
					ot: {
						select: {
							id: true,
							numero: true,
							estado: true,
							tecnicoAsignadoId: true,
						},
					},
				},
			});

			const pendientes = await tx.solicitudMaterial.count({
				where: {
					otId: solicitud.otId,
					estado: EstadoSolicitudMaterial.pendiente,
				},
			});

			if (
				pendientes === 0 &&
				solicitud.ot.estado === EstadoOt.pendiente_panol
			) {
				await tx.ordenTrabajo.update({
					where: { id: solicitud.otId },
					data: { estado: EstadoOt.pendiente },
				});
				await tx.otEstadoHistorial.create({
					data: {
						otId: solicitud.otId,
						estado: EstadoOt.pendiente,
						usuarioId: currentUser.id,
						comentario: `Materiales rechazados: ${motivo}`,
					},
				});
			}

			return row;
		});

		if (solicitud.ot.tecnicoAsignadoId) {
			void this.pushService.notifyUsuario(
				solicitud.ot.tecnicoAsignadoId,
				{
					title: `OT #${solicitud.ot.numero}`,
					body: `Material rechazado: ${motivo}`,
					data: {
						type: 'material.rechazado',
						otNumero: String(solicitud.ot.numero),
					},
				},
			);
		}

		return updated;
	}

	private async notifyPanoleros(
		sucursalId: string,
		otNumero: number,
		itemCount: number,
	) {
		const panoleros = await this.prisma.usuario.findMany({
			where: {
				sucursalId,
				activo: true,
				OR: [
					{ esAdministrador: true },
					{
						perfil: {
							derechos: {
								some: {
									habilitado: true,
									derecho: {
										codigo: {
											in: [
												'stock.pañol.solicitudes_materiales.aprobar',
												'stock.pañol',
												'stock',
											],
										},
									},
								},
							},
						},
					},
				],
			},
			select: { id: true },
		});

		for (const p of panoleros) {
			void this.pushService.notifyUsuario(p.id, {
				title: `OT #${otNumero}`,
				body:
					itemCount === 1
						? 'Nueva solicitud de materiales pendiente'
						: `${itemCount} solicitudes de materiales pendientes`,
				data: {
					type: 'material.solicitud',
					otNumero: String(otNumero),
				},
			});
		}
	}
}
