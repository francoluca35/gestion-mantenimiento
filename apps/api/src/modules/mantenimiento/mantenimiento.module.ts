import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { NotificacionesModule } from '../notificaciones/notificaciones.module';
import { PanolModule } from '../panol/panol.module';
import { MotivosOtPendienteController } from './motivos-ot-pendiente/motivos-ot-pendiente.controller';
import { MotivosOtPendienteService } from './motivos-ot-pendiente/motivos-ot-pendiente.service';
import { OtController } from './ot/ot.controller';
import { OtCronService } from './ot/ot-cron.service';
import { OtPdfBinaryService } from './ot/ot-pdf-binary.service';
import { OtService } from './ot/ot.service';
import { ProcedimientosController } from './procedimientos/procedimientos.controller';
import { ProcedimientosService } from './procedimientos/procedimientos.service';
import { SolicitudesTrabajoController } from './solicitudes-trabajo/solicitudes-trabajo.controller';
import { SolicitudesTrabajoService } from './solicitudes-trabajo/solicitudes-trabajo.service';

@Module({
	imports: [ScheduleModule.forRoot(), NotificacionesModule, PanolModule],
	controllers: [
		ProcedimientosController,
		OtController,
		MotivosOtPendienteController,
		SolicitudesTrabajoController,
	],
	providers: [
		ProcedimientosService,
		OtService,
		OtCronService,
		OtPdfBinaryService,
		SolicitudesTrabajoService,
		MotivosOtPendienteService,
	],
	exports: [OtService, ProcedimientosService, MotivosOtPendienteService],
})
export class MantenimientoModule {}
