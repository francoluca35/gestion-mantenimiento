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
import { CreateUbicacionDto } from './dto/create-ubicacion.dto';
import { MoverUbicacionDto } from './dto/mover-ubicacion.dto';
import { UpdateUbicacionDto } from './dto/update-ubicacion.dto';
import { UbicacionesService } from './ubicaciones.service';

@Controller('ubicaciones')
export class UbicacionesController {
	constructor(private readonly ubicacionesService: UbicacionesService) {}

	@Get('tree')
	@RequiereDerecho('archivos.equipos.listar')
	getTree(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
	) {
		return this.ubicacionesService.getTree(user, sucursalId);
	}

	@Get('alcance/procedimientos')
	@RequiereDerecho('archivos.equipos.listar')
	getProcedimientosPorAlcance(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('ubicacionId') ubicacionId?: string,
		@Query('equipoId') equipoId?: string,
	) {
		return this.ubicacionesService.getProcedimientosPorAlcance(user, {
			sucursalId,
			ubicacionId,
			equipoId,
		});
	}

	@Post()
	@RequiereDerecho('archivos.ubicaciones.agregar_nodo')
	create(@Body() dto: CreateUbicacionDto, @CurrentUser() user: AuthUser) {
		return this.ubicacionesService.create(dto, user);
	}

	@Patch(':id')
	@RequiereDerecho('archivos.ubicaciones.modificar_nodo')
	update(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdateUbicacionDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.ubicacionesService.update(id, dto, user);
	}

	@Delete(':id')
	@RequiereDerecho('archivos.ubicaciones.borrar_nodo')
	remove(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
		return this.ubicacionesService.remove(id, user);
	}

	@Post(':id/mover')
	@RequiereDerecho('archivos.ubicaciones.mover_nodo')
	mover(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: MoverUbicacionDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.ubicacionesService.mover(id, dto, user);
	}
}
