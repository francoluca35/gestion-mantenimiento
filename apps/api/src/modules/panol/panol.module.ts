import { Module } from '@nestjs/common';
import { NotificacionesModule } from '../notificaciones/notificaciones.module';
import { MaterialesController } from './materiales/materiales.controller';
import { MaterialesService } from './materiales/materiales.service';
import { PanolesController } from './panoles/panoles.controller';
import { PanolesService } from './panoles/panoles.service';
import { PedidosStockController } from './pedidos-stock/pedidos-stock.controller';
import { PedidosStockService } from './pedidos-stock/pedidos-stock.service';
import { SolicitudesMaterialesController } from './solicitudes-materiales/solicitudes-materiales.controller';
import { SolicitudesMaterialesService } from './solicitudes-materiales/solicitudes-materiales.service';
import { StockController } from './stock/stock.controller';
import { StockCronService } from './stock/stock-cron.service';
import { StockService } from './stock/stock.service';

@Module({
	imports: [NotificacionesModule],
	controllers: [
		PanolesController,
		MaterialesController,
		StockController,
		SolicitudesMaterialesController,
		PedidosStockController,
	],
	providers: [
		PanolesService,
		MaterialesService,
		StockService,
		StockCronService,
		SolicitudesMaterialesService,
		PedidosStockService,
	],
	exports: [StockService, SolicitudesMaterialesService],
})
export class PanolModule {}
