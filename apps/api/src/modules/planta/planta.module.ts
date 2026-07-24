import { Module } from '@nestjs/common';
import { MantenimientoModule } from '../mantenimiento/mantenimiento.module';
import { ComponentesController } from './componentes/componentes.controller';
import { ComponentesService } from './componentes/componentes.service';
import { EquipoDocumentosController } from './documentos/equipo-documentos.controller';
import { EquipoDocumentosService } from './documentos/equipo-documentos.service';
import { EquiposController } from './equipos/equipos.controller';
import { EquiposService } from './equipos/equipos.service';
import { LecturasController } from './lecturas/lecturas.controller';
import { LecturasService } from './lecturas/lecturas.service';
import { TiposEquipoController } from './tipos-equipo/tipos-equipo.controller';
import { TiposEquipoService } from './tipos-equipo/tipos-equipo.service';
import { UbicacionesController } from './ubicaciones/ubicaciones.controller';
import { UbicacionesService } from './ubicaciones/ubicaciones.service';

@Module({
	imports: [MantenimientoModule],
	controllers: [
		UbicacionesController,
		TiposEquipoController,
		EquiposController,
		LecturasController,
		EquipoDocumentosController,
		ComponentesController,
	],
	providers: [
		UbicacionesService,
		TiposEquipoService,
		EquiposService,
		LecturasService,
		EquipoDocumentosService,
		ComponentesService,
	],
	exports: [UbicacionesService, EquiposService, TiposEquipoService],
})
export class PlantaModule {}
