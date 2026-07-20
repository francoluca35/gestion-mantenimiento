import {
	Body,
	Controller,
	Get,
	Param,
	ParseUUIDPipe,
	Patch,
	Post,
	Query,
} from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import {
	CreateSolicitudesMaterialesDto,
	RechazarSolicitudMaterialDto,
} from './dto/solicitud-material.dto';
import { SolicitudesMaterialesService } from './solicitudes-materiales.service';

@Controller('solicitudes-materiales')
export class SolicitudesMaterialesController {
	constructor(private readonly service: SolicitudesMaterialesService) {}

	@Get()
	@RequiereDerecho('stock.pañol.solicitudes_materiales.ver_pendientes')
	findAll(
		@CurrentUser() user: AuthUser,
		@Query('estado') estado?: string,
		@Query('otId') otId?: string,
		@Query('sucursalId') sucursalId?: string,
	) {
		return this.service.findAll(user, { estado, otId, sucursalId });
	}

	@Post()
	@RequiereDerecho('stock.pañol.solicitudes_materiales.solicitar')
	crear(
		@Body() dto: CreateSolicitudesMaterialesDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.service.crear(dto, user);
	}

	@Patch(':id/aprobar')
	@RequiereDerecho('stock.pañol.solicitudes_materiales.aprobar')
	aprobar(
		@Param('id', ParseUUIDPipe) id: string,
		@CurrentUser() user: AuthUser,
	) {
		return this.service.aprobar(id, user);
	}

	@Patch(':id/rechazar')
	@RequiereDerecho('stock.pañol.solicitudes_materiales.rechazar')
	rechazar(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: RechazarSolicitudMaterialDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.service.rechazar(id, dto, user);
	}
}
