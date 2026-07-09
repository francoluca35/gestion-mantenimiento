import { Body, Controller, Get, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { CreateLecturaDto } from './dto/create-lectura.dto';
import { LecturasService } from './lecturas.service';

@Controller('equipos/:equipoId/lecturas')
export class LecturasController {
	constructor(private readonly lecturasService: LecturasService) {}

	@Get()
	@RequiereDerecho('archivos.equipos.listar')
	findAll(
		@Param('equipoId', ParseUUIDPipe) equipoId: string,
		@CurrentUser() user: AuthUser,
	) {
		return this.lecturasService.findByEquipo(equipoId, user);
	}

	@Post()
	@RequiereDerecho('archivos.equipos.modificar')
	create(
		@Param('equipoId', ParseUUIDPipe) equipoId: string,
		@Body() dto: CreateLecturaDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.lecturasService.create(equipoId, dto, user);
	}
}
