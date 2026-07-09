import { Module } from '@nestjs/common';
import { OtController } from './ot/ot.controller';
import { OtService } from './ot/ot.service';
import { ProcedimientosController } from './procedimientos/procedimientos.controller';
import { ProcedimientosService } from './procedimientos/procedimientos.service';
import { SolicitudesTrabajoController } from './solicitudes-trabajo/solicitudes-trabajo.controller';
import { SolicitudesTrabajoService } from './solicitudes-trabajo/solicitudes-trabajo.service';

@Module({
	controllers: [
		ProcedimientosController,
		OtController,
		SolicitudesTrabajoController,
	],
	providers: [ProcedimientosService, OtService, SolicitudesTrabajoService],
	exports: [OtService, ProcedimientosService],
})
export class MantenimientoModule {}
