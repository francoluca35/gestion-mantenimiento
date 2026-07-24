import {
	BadRequestException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { EstadoPedidoStock, TipoMovimientoStock } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { resolveSucursalId } from '../../planta/planta.scope';
import { tryLiberarOtTrasPanol } from '../ot-panol-gate.util';
import { CreatePedidoStockDto, UpdatePedidoStockDto } from './dto/pedido-stock.dto';

@Injectable()
export class PedidosStockService {
	constructor(private readonly prisma: PrismaService) {}

	async findAll(
		currentUser: AuthUser,
		opts?: { panolId?: string; estado?: string; sucursalId?: string },
	) {
		const sucursalId = resolveSucursalId(currentUser, opts?.sucursalId);
		return this.prisma.pedidoStock.findMany({
			where: {
				panol: { sucursalId },
				...(opts?.panolId ? { panolId: opts.panolId } : {}),
				...(opts?.estado
					? { estado: opts.estado as EstadoPedidoStock }
					: {}),
			},
			include: {
				material: { include: { unidad: true } },
				panol: true,
				usuario: { select: { id: true, nombreUsuario: true } },
			},
			orderBy: { createdAt: 'desc' },
			take: 100,
		});
	}

	async create(dto: CreatePedidoStockDto, currentUser: AuthUser) {
		const panol = await this.prisma.panol.findUnique({
			where: { id: dto.panolId },
		});
		if (!panol || !panol.activo) {
			throw new NotFoundException('Pañol no encontrado');
		}
		resolveSucursalId(currentUser, panol.sucursalId);

		const material = await this.prisma.material.findUnique({
			where: { id: dto.materialId },
		});
		if (!material || !material.activo) {
			throw new NotFoundException('Material no encontrado');
		}

		return this.prisma.pedidoStock.create({
			data: {
				panolId: dto.panolId,
				materialId: dto.materialId,
				cantidad: dto.cantidad,
				usuarioId: currentUser.id,
				notas: dto.notas?.trim() || null,
			},
			include: {
				material: { include: { unidad: true } },
				panol: true,
				usuario: { select: { id: true, nombreUsuario: true } },
			},
		});
	}

	async update(
		id: string,
		dto: UpdatePedidoStockDto,
		currentUser: AuthUser,
	) {
		const pedido = await this.prisma.pedidoStock.findUnique({
			where: { id },
			include: { panol: true },
		});
		if (!pedido) throw new NotFoundException('Pedido no encontrado');
		resolveSucursalId(currentUser, pedido.panol.sucursalId);

		if (pedido.estado === EstadoPedidoStock.completado) {
			throw new BadRequestException('El pedido ya está completado');
		}

		const next = dto.estado;
		if (
			pedido.estado === EstadoPedidoStock.pendiente &&
			next !== EstadoPedidoStock.en_proceso &&
			next !== EstadoPedidoStock.completado
		) {
			throw new BadRequestException('Transición de estado inválida');
		}
		if (
			pedido.estado === EstadoPedidoStock.en_proceso &&
			next !== EstadoPedidoStock.completado
		) {
			throw new BadRequestException('Solo se puede completar desde en proceso');
		}

		if (next === EstadoPedidoStock.completado) {
			return this.prisma.$transaction(async (tx) => {
				let item = await tx.stockItem.findUnique({
					where: {
						panolId_materialId: {
							panolId: pedido.panolId,
							materialId: pedido.materialId,
						},
					},
				});
				if (!item) {
					item = await tx.stockItem.create({
						data: {
							panolId: pedido.panolId,
							materialId: pedido.materialId,
							cantidadActual: 0,
							cantidadMinima: 0,
							cantidadReservada: 0,
						},
					});
				}

				const qty = Number(pedido.cantidad);
				await tx.stockItem.update({
					where: { id: item.id },
					data: { cantidadActual: Number(item.cantidadActual) + qty },
				});

				await tx.movimientoStock.create({
					data: {
						panolId: pedido.panolId,
						materialId: pedido.materialId,
						tipo: TipoMovimientoStock.entrada,
						cantidad: qty,
						usuarioId: currentUser.id,
						origen: 'pedido_stock',
						notas: `Pedido PD-${String(pedido.numero).padStart(4, '0')}`,
						otId: pedido.otId ?? undefined,
					},
				});

				const updated = await tx.pedidoStock.update({
					where: { id },
					data: {
						estado: EstadoPedidoStock.completado,
						completadoAt: new Date(),
						notas:
							dto.notas === undefined
								? undefined
								: dto.notas.trim() || null,
					},
					include: {
						material: { include: { unidad: true } },
						panol: true,
						usuario: { select: { id: true, nombreUsuario: true } },
					},
				});

				if (pedido.otId) {
					await tryLiberarOtTrasPanol(
						tx,
						pedido.otId,
						currentUser.id,
						'Pañol completó reposición — OT lista para iniciar',
					);
				}

				return updated;
			});
		}

		return this.prisma.pedidoStock.update({
			where: { id },
			data: {
				estado: next,
				notas:
					dto.notas === undefined ? undefined : dto.notas.trim() || null,
			},
			include: {
				material: { include: { unidad: true } },
				panol: true,
				usuario: { select: { id: true, nombreUsuario: true } },
			},
		});
	}
}
