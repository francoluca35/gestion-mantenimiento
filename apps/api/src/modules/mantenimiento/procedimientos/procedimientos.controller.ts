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
import { AsociarAlcanceDto } from './dto/asociar-alcance.dto';
import { AsociarEquipoDto } from './dto/asociar-equipo.dto';
import { CambiarEstadoEquipoDto } from './dto/cambiar-estado-equipo.dto';
import { DesasociarAlcanceDto } from './dto/desasociar-alcance.dto';
import { DesasociarEquipoDto } from './dto/desasociar-equipo.dto';
import { CreateProcedimientoDto } from './dto/create-procedimiento.dto';
import { UpdateProcedimientoDto } from './dto/update-procedimiento.dto';
import { ProcedimientosService } from './procedimientos.service';

@Controller('procedimientos')
export class ProcedimientosController {
	constructor(private readonly procedimientosService: ProcedimientosService) {}

	@Get()
	@RequiereDerecho('archivos.procedimientos.listar')
	findAll(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('tipo') tipo?: string,
		@Query('sectorResponsableId') sectorResponsableId?: string,
		@Query('periodicidadTipo') periodicidadTipo?: string,
		@Query('tipoEquipoId') tipoEquipoId?: string,
		@Query('q') q?: string,
	) {
		return this.procedimientosService.findAll(user, {
			sucursalId,
			tipo,
			sectorResponsableId,
			periodicidadTipo,
			tipoEquipoId,
			q,
		});
	}

	@Get(':id')
	@RequiereDerecho('archivos.procedimientos.listar')
	findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
		return this.procedimientosService.findOne(id, user);
	}

	@Get(':id/versiones')
	@RequiereDerecho('archivos.procedimientos.listar')
	listarVersiones(
		@Param('id', ParseUUIDPipe) id: string,
		@CurrentUser() user: AuthUser,
	) {
		return this.procedimientosService.listarVersiones(id, user);
	}

	@Post()
	@RequiereDerecho('archivos.procedimientos.agregar')
	create(@Body() dto: CreateProcedimientoDto, @CurrentUser() user: AuthUser) {
		return this.procedimientosService.create(dto, user);
	}

	@Patch(':id')
	@RequiereDerecho('archivos.procedimientos.modificar')
	update(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdateProcedimientoDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.procedimientosService.update(id, dto, user);
	}

	@Delete(':id')
	@RequiereDerecho('archivos.procedimientos.borrar')
	remove(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
		return this.procedimientosService.remove(id, user);
	}

	@Patch(':id/estado-equipo')
	@RequiereDerecho('archivos.procedimientos.asociar_a_equipo')
	cambiarEstadoEquipo(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: CambiarEstadoEquipoDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.procedimientosService.cambiarEstadoEquipo(id, dto, user);
	}

	@Post(':id/asociar-equipo')
	@RequiereDerecho('archivos.procedimientos.asociar_a_equipo')
	asociarEquipo(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: AsociarEquipoDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.procedimientosService.asociarEquipo(id, dto, user);
	}

	@Post(':id/desasociar-equipo')
	@RequiereDerecho('archivos.procedimientos.asociar_a_equipo')
	desasociarEquipo(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: DesasociarEquipoDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.procedimientosService.desasociarEquipo(id, dto, user);
	}

	@Post(':id/asociar-alcance')
	@RequiereDerecho('archivos.procedimientos.asociar_a_equipo')
	asociarAlcance(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: AsociarAlcanceDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.procedimientosService.asociarAlcance(id, dto, user);
	}

	@Post(':id/desasociar-alcance')
	@RequiereDerecho('archivos.procedimientos.asociar_a_equipo')
	desasociarAlcance(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: DesasociarAlcanceDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.procedimientosService.desasociarAlcance(id, dto, user);
	}
}
