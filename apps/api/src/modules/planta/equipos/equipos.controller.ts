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
import { CreateEquipoDto } from './dto/create-equipo.dto';
import { FueraServicioDto } from './dto/fuera-servicio.dto';
import { MoverEquipoDto } from './dto/mover-equipo.dto';
import { UpdateEquipoDto } from './dto/update-equipo.dto';
import { EquiposService } from './equipos.service';

@Controller('equipos')
export class EquiposController {
	constructor(private readonly equiposService: EquiposService) {}

	@Get()
	@RequiereDerecho('archivos.equipos.listar')
	findAll(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('ubicacionId') ubicacionId?: string,
		@Query('tipoEquipoId') tipoEquipoId?: string,
	) {
		return this.equiposService.findAll(user, {
			sucursalId,
			ubicacionId,
			tipoEquipoId,
		});
	}

	@Get(':id')
	@RequiereDerecho('archivos.equipos.listar')
	findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
		return this.equiposService.findOne(id, user);
	}

	@Post()
	@RequiereDerecho('archivos.equipos.agregar')
	create(@Body() dto: CreateEquipoDto, @CurrentUser() user: AuthUser) {
		return this.equiposService.create(dto, user);
	}

	@Patch(':id')
	@RequiereDerecho('archivos.equipos.modificar')
	update(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdateEquipoDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.equiposService.update(id, dto, user);
	}

	@Post(':id/mover')
	@RequiereDerecho('archivos.equipos.mover')
	mover(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: MoverEquipoDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.equiposService.mover(id, dto, user);
	}

	@Post(':id/fuera-de-servicio')
	@RequiereDerecho('archivos.equipos.marcar_fuera_de_servicio')
	fueraDeServicio(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: FueraServicioDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.equiposService.marcarFueraDeServicio(id, dto.fuera, user);
	}
}
