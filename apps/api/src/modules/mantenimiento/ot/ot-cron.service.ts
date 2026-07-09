import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../../database/prisma.service';
import { OtService } from './ot.service';

@Injectable()
export class OtCronService {
	private readonly logger = new Logger(OtCronService.name);

	constructor(
		private readonly otService: OtService,
		private readonly prisma: PrismaService,
	) {}

	@Cron(CronExpression.EVERY_DAY_AT_6AM)
	async emitirOtNecesariasDiarias() {
		if (process.env.OT_CRON_ENABLED === 'false') return;

		const sucursales = await this.prisma.sucursal.findMany({
			where: { activa: true },
			select: { id: true, codigo: true },
		});

		for (const sucursal of sucursales) {
			try {
				const resultado = await this.otService.emitirNecesariasAutomaticas(sucursal.id);
				if (resultado.emitidas > 0) {
					this.logger.log(
						`OT necesarias emitidas en ${sucursal.codigo}: ${resultado.emitidas}`,
					);
				}
			} catch (error) {
				this.logger.error(
					`Error cron OT en ${sucursal.codigo}: ${error}`,
				);
			}
		}
	}
}
