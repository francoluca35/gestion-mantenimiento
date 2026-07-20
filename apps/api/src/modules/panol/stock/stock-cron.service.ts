import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../../database/prisma.service';
import { PushService } from '../../notificaciones/push.service';

@Injectable()
export class StockCronService {
	private readonly logger = new Logger(StockCronService.name);

	constructor(
		private readonly prisma: PrismaService,
		private readonly push: PushService,
	) {}

	/** Diario 7:00 — avisa pañoleros si hay ítems bajo mínimo. */
	@Cron(CronExpression.EVERY_DAY_AT_7AM)
	async alertarStockMinimo() {
		if (process.env.STOCK_ALERT_CRON_ENABLED === 'false') return;

		const items = await this.prisma.stockItem.findMany({
			where: {
				material: { activo: true },
				panol: { activo: true },
			},
			include: {
				material: { select: { codigo: true, nombre: true } },
				panol: { select: { id: true, nombre: true, sucursalId: true } },
			},
		});

		const bajos = items.filter((item) => {
			const disponible =
				Number(item.cantidadActual) - Number(item.cantidadReservada);
			return disponible < Number(item.cantidadMinima);
		});

		if (bajos.length === 0) {
			this.logger.debug('Cron stock: sin ítems bajo mínimo');
			return;
		}

		const porSucursal = new Map<string, typeof bajos>();
		for (const item of bajos) {
			const sid = item.panol.sucursalId;
			const list = porSucursal.get(sid) ?? [];
			list.push(item);
			porSucursal.set(sid, list);
		}

		for (const [sucursalId, lista] of porSucursal) {
			const panoleros = await this.findPanoleros(sucursalId);
			const preview = lista
				.slice(0, 3)
				.map((i) => i.material.codigo)
				.join(', ');
			const body =
				lista.length === 1
					? `1 material bajo mínimo: ${preview}`
					: `${lista.length} materiales bajo mínimo (${preview}${lista.length > 3 ? '…' : ''})`;

			for (const p of panoleros) {
				void this.push.notifyUsuario(p.id, {
					title: 'Stock bajo mínimo',
					body,
					data: {
						type: 'stock.alerta_minimo',
						count: String(lista.length),
						click_route: '/panol/stock',
					},
				});
			}

			this.logger.log(
				`Cron stock: ${lista.length} bajo mínimo → ${panoleros.length} pañoleros (sucursal ${sucursalId})`,
			);
		}
	}

	private async findPanoleros(sucursalId: string) {
		return this.prisma.usuario.findMany({
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
												'stock.pañol.alertas_stock_minimo.ver',
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
	}
}
