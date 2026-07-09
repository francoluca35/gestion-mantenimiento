import {
	Body,
	Controller,
	Delete,
	Get,
	Param,
	ParseUUIDPipe,
	Patch,
	Post,
} from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { ComponentesService } from './componentes.service';
import { CreateComponenteDto } from './dto/create-componente.dto';
import { UpdateComponenteDto } from './dto/update-componente.dto';

@Controller('equipos/:equipoId/componentes')
export class ComponentesController {
	constructor(private readonly componentesService: ComponentesService) {}

	@Get()
	@RequiereDerecho('archivos.equipos.listar')
	findAll(
		@Param('equipoId', ParseUUIDPipe) equipoId: string,
		@CurrentUser() user: AuthUser,
	) {
		return this.componentesService.findAll(equipoId, user);
	}

	@Post()
	@RequiereDerecho('archivos.equipos.modificar')
	create(
		@Param('equipoId', ParseUUIDPipe) equipoId: string,
		@Body() dto: CreateComponenteDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.componentesService.create(equipoId, dto, user);
	}

	@Patch(':id')
	@RequiereDerecho('archivos.equipos.modificar')
	update(
		@Param('equipoId', ParseUUIDPipe) equipoId: string,
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdateComponenteDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.componentesService.update(equipoId, id, dto, user);
	}

	@Delete(':id')
	@RequiereDerecho('archivos.equipos.modificar')
	remove(
		@Param('equipoId', ParseUUIDPipe) equipoId: string,
		@Param('id', ParseUUIDPipe) id: string,
		@CurrentUser() user: AuthUser,
	) {
		return this.componentesService.remove(equipoId, id, user);
	}
}
