import {
	BadRequestException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { TipoMovimientoStock } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { resolveSucursalId } from '../../planta/planta.scope';
import { CreateMovimientoDto, UpdateStockDto } from './dto/stock.dto';

@Injectable()
export class StockService {
	constructor(private readonly prisma: PrismaService) {}

	async findAll(
		currentUser: AuthUser,
		opts?: { sucursalId?: string; panolId?: string; q?: string },
	) {
		const sucursalId = resolveSucursalId(currentUser, opts?.sucursalId);

		const items = await this.prisma.stockItem.findMany({
			where: {
				material: {
					activo: true,
					...(opts?.q?.trim()
						? {
								OR: [
									{ nombre: { contains: opts.q.trim(), mode: 'insensitive' } },
									{ codigo: { contains: opts.q.trim(), mode: 'insensitive' } },
								],
							}
						: {}),
				},
				panol: {
					sucursalId,
					activo: true,
					...(opts?.panolId ? { id: opts.panolId } : {}),
				},
			},
			include: {
				material: { include: { unidad: true } },
				panol: true,
			},
			orderBy: [{ material: { nombre: 'asc' } }],
		});

		return items.map((item) => {
			const actual = Number(item.cantidadActual);
			const reservada = Number(item.cantidadReservada);
			const minima = Number(item.cantidadMinima);
			const disponible = actual - reservada;
			return {
				...item,
				disponible,
				bajoMinimo: disponible < minima,
			};
		});
	}

	async updateItem(
		id: string,
		dto: UpdateStockDto,
		currentUser: AuthUser,
	) {
		const item = await this.prisma.stockItem.findUnique({
			where: { id },
			include: { panol: true },
		});
		if (!item) throw new NotFoundException('Ítem de stock no encontrado');
		resolveSucursalId(currentUser, item.panol.sucursalId);

		if (dto.cantidadActual !== undefined) {
			const reservada = Number(item.cantidadReservada);
			if (dto.cantidadActual < reservada) {
				throw new BadRequestException(
					`cantidadActual no puede ser menor a lo reservado (${reservada})`,
				);
			}
		}

		return this.prisma.stockItem.update({
			where: { id },
			data: {
				cantidadMinima: dto.cantidadMinima,
				cantidadActual: dto.cantidadActual,
			},
			include: {
				material: { include: { unidad: true } },
				panol: true,
			},
		});
	}

	async registrarMovimiento(dto: CreateMovimientoDto, currentUser: AuthUser) {
		const tiposManuales: TipoMovimientoStock[] = [
			TipoMovimientoStock.entrada,
			TipoMovimientoStock.salida,
			TipoMovimientoStock.devolucion,
		];
		if (!tiposManuales.includes(dto.tipo)) {
			throw new BadRequestException(
				'Solo se permiten movimientos manuales de entrada, salida o devolución',
			);
		}

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

		return this.prisma.$transaction(async (tx) => {
			let item = await tx.stockItem.findUnique({
				where: {
					panolId_materialId: {
						panolId: dto.panolId,
						materialId: dto.materialId,
					},
				},
			});

			if (!item) {
				item = await tx.stockItem.create({
					data: {
						panolId: dto.panolId,
						materialId: dto.materialId,
						cantidadActual: 0,
						cantidadMinima: 0,
						cantidadReservada: 0,
					},
				});
			}

			const delta =
				dto.tipo === TipoMovimientoStock.salida
					? -dto.cantidad
					: dto.cantidad;
			const nueva = Number(item.cantidadActual) + delta;
			const reservada = Number(item.cantidadReservada);

			if (nueva < reservada) {
				throw new BadRequestException(
					`Stock insuficiente (disponible ${Number(item.cantidadActual) - reservada})`,
				);
			}

			await tx.stockItem.update({
				where: { id: item.id },
				data: { cantidadActual: nueva },
			});

			return tx.movimientoStock.create({
				data: {
					panolId: dto.panolId,
					materialId: dto.materialId,
					tipo: dto.tipo,
					cantidad: dto.cantidad,
					otId: dto.otId,
					usuarioId: currentUser.id,
					origen: dto.origen ?? 'manual',
					notas: dto.notas?.trim() || null,
				},
				include: {
					material: { include: { unidad: true } },
					panol: true,
				},
			});
		});
	}

	async listMovimientos(
		currentUser: AuthUser,
		opts?: { panolId?: string; materialId?: string; sucursalId?: string },
	) {
		const sucursalId = resolveSucursalId(currentUser, opts?.sucursalId);
		return this.prisma.movimientoStock.findMany({
			where: {
				panol: { sucursalId },
				...(opts?.panolId ? { panolId: opts.panolId } : {}),
				...(opts?.materialId ? { materialId: opts.materialId } : {}),
			},
			include: {
				material: { include: { unidad: true } },
				panol: true,
				usuario: { select: { id: true, nombreUsuario: true } },
			},
			orderBy: { fecha: 'desc' },
			take: 200,
		});
	}

	/** Ítems con disponible por debajo del mínimo (para alertas / listado). */
	async listAlertas(
		currentUser: AuthUser,
		opts?: { sucursalId?: string; panolId?: string },
	) {
		const items = await this.findAll(currentUser, opts);
		return items.filter((item) => item.bajoMinimo);
	}

	/**
	 * Al cerrar OT (realizada): descuenta stock físico y libera la reserva
	 * de cada solicitud aprobada.
	 */
	async consumirReservasOt(otId: string, usuarioId: string) {
		const solicitudes = await this.prisma.solicitudMaterial.findMany({
			where: { otId, estado: 'aprobado' },
		});
		if (solicitudes.length === 0) return { consumidos: 0 };

		await this.prisma.$transaction(async (tx) => {
			for (const sol of solicitudes) {
				const item = await tx.stockItem.findUnique({
					where: {
						panolId_materialId: {
							panolId: sol.panolId,
							materialId: sol.materialId,
						},
					},
				});
				if (!item) continue;

				const pedida = Number(sol.cantidadSolicitada);
				const reservada = Number(item.cantidadReservada);
				const qty = Math.min(pedida, reservada);
				if (qty <= 0) continue;

				const actual = Number(item.cantidadActual);
				const nuevaActual = Math.max(0, actual - qty);
				const nuevaReservada = Math.max(0, reservada - qty);

				await tx.stockItem.update({
					where: { id: item.id },
					data: {
						cantidadActual: nuevaActual,
						cantidadReservada: nuevaReservada,
					},
				});

				await tx.movimientoStock.create({
					data: {
						panolId: sol.panolId,
						materialId: sol.materialId,
						tipo: TipoMovimientoStock.salida,
						cantidad: qty,
						otId,
						usuarioId,
						origen: 'ot_cierre',
						notas: `Consumo OT — solicitud ${sol.id.slice(0, 8)}`,
					},
				});
			}
		});

		return { consumidos: solicitudes.length };
	}

	/**
	 * Al anular OT: libera reservas de solicitudes aprobadas sin descontar físico.
	 */
	async liberarReservasOt(otId: string, usuarioId: string) {
		const solicitudes = await this.prisma.solicitudMaterial.findMany({
			where: { otId, estado: 'aprobado' },
		});
		if (solicitudes.length === 0) return { liberados: 0 };

		await this.prisma.$transaction(async (tx) => {
			for (const sol of solicitudes) {
				const item = await tx.stockItem.findUnique({
					where: {
						panolId_materialId: {
							panolId: sol.panolId,
							materialId: sol.materialId,
						},
					},
				});
				if (!item) continue;

				const pedida = Number(sol.cantidadSolicitada);
				const reservada = Number(item.cantidadReservada);
				const qty = Math.min(pedida, reservada);
				if (qty <= 0) continue;

				const nuevaReservada = Math.max(0, reservada - qty);

				await tx.stockItem.update({
					where: { id: item.id },
					data: { cantidadReservada: nuevaReservada },
				});

				await tx.movimientoStock.create({
					data: {
						panolId: sol.panolId,
						materialId: sol.materialId,
						tipo: TipoMovimientoStock.devolucion,
						cantidad: qty,
						otId,
						usuarioId,
						origen: 'ot_anulada',
						notas: 'Liberación de reserva por OT anulada',
					},
				});
			}
		});

		return { liberados: solicitudes.length };
	}

	/** Usado al aprobar solicitud: incrementa cantidadReservada. */
	async reservarEnTx(
		// Cliente de transacción Prisma (puede ser extended)
		// eslint-disable-next-line @typescript-eslint/no-explicit-any
		tx: any,
		params: {
			panolId: string;
			materialId: string;
			cantidad: number;
			otId: string;
			usuarioId: string;
		},
	) {
		const item = await tx.stockItem.findUnique({
			where: {
				panolId_materialId: {
					panolId: params.panolId,
					materialId: params.materialId,
				},
			},
		});
		if (!item) {
			throw new BadRequestException('Sin stock para el material en este pañol');
		}

		const disponible =
			Number(item.cantidadActual) - Number(item.cantidadReservada);
		if (disponible < params.cantidad) {
			throw new BadRequestException(
				`Stock insuficiente (disponible ${disponible}, solicitado ${params.cantidad})`,
			);
		}

		await tx.stockItem.update({
			where: { id: item.id },
			data: {
				cantidadReservada: Number(item.cantidadReservada) + params.cantidad,
			},
		});

		await tx.movimientoStock.create({
			data: {
				panolId: params.panolId,
				materialId: params.materialId,
				tipo: TipoMovimientoStock.reserva,
				cantidad: params.cantidad,
				otId: params.otId,
				usuarioId: params.usuarioId,
				origen: 'solicitud_material',
			},
		});
	}
}
