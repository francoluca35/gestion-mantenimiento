import {
	Body,
	Controller,
	Delete,
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
import { CreateMotivoOtPendienteDto } from './dto/create-motivo-ot-pendiente.dto';
import { UpdateMotivoOtPendienteDto } from './dto/update-motivo-ot-pendiente.dto';
import { MotivosOtPendienteService } from './motivos-ot-pendiente.service';

@Controller('motivos-ot-pendiente')
export class MotivosOtPendienteController {
	constructor(private readonly motivosService: MotivosOtPendienteService) {}

	@Get()
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	findAll(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
	) {
		return this.motivosService.findAll(user, sucursalId);
	}

	@Post()
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	create(
		@Body() dto: CreateMotivoOtPendienteDto,
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
	) {
		return this.motivosService.create(dto, user, sucursalId);
	}

	@Patch(':id')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	update(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdateMotivoOtPendienteDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.motivosService.update(id, dto, user);
	}

	@Delete(':id')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	remove(
		@Param('id', ParseUUIDPipe) id: string,
		@CurrentUser() user: AuthUser,
	) {
		return this.motivosService.remove(id, user);
	}
}
