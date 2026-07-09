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
import { ConformidadSolicitudDto } from './dto/conformidad-solicitud.dto';
import { CreateSolicitudTrabajoDto } from './dto/create-solicitud-trabajo.dto';
import { EmitirOtDesdeSolicitudDto } from './dto/emitir-ot-desde-solicitud.dto';
import { SolicitudesTrabajoService } from './solicitudes-trabajo.service';

@Controller('solicitudes-trabajo')
export class SolicitudesTrabajoController {
	constructor(
		private readonly solicitudesTrabajoService: SolicitudesTrabajoService,
	) {}

	@Get()
	@RequiereDerecho('programacion.solicitudes_trabajo.listar')
	findAll(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
	) {
		return this.solicitudesTrabajoService.findAll(user, sucursalId);
	}

	@Post()
	@RequiereDerecho('programacion.solicitudes_trabajo.agregar')
	create(
		@Body() dto: CreateSolicitudTrabajoDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.solicitudesTrabajoService.create(dto, user);
	}

	@Patch(':id/conformidad')
	@RequiereDerecho('programacion.solicitudes_trabajo.dar_conformidad')
	darConformidad(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: ConformidadSolicitudDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.solicitudesTrabajoService.darConformidad(id, dto, user);
	}

	@Post(':id/emitir-ot')
	@RequiereDerecho('programacion.solicitudes_trabajo.emitir_ot_desde_solicitud')
	emitirOt(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: EmitirOtDesdeSolicitudDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.solicitudesTrabajoService.emitirOt(id, dto, user);
	}
}
