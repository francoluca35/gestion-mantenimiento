import { Module } from '@nestjs/common';
import { EquiposController } from './equipos/equipos.controller';
import { EquiposService } from './equipos/equipos.service';
import { LecturasController } from './lecturas/lecturas.controller';
import { LecturasService } from './lecturas/lecturas.service';
import { TiposEquipoController } from './tipos-equipo/tipos-equipo.controller';
import { TiposEquipoService } from './tipos-equipo/tipos-equipo.service';
import { UbicacionesController } from './ubicaciones/ubicaciones.controller';
import { UbicacionesService } from './ubicaciones/ubicaciones.service';

@Module({
	controllers: [
		UbicacionesController,
		TiposEquipoController,
		EquiposController,
		LecturasController,
	],
	providers: [
		UbicacionesService,
		TiposEquipoService,
		EquiposService,
		LecturasService,
	],
	exports: [UbicacionesService, EquiposService, TiposEquipoService],
})
export class PlantaModule {}
