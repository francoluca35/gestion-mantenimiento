import {
	Body,
	Controller,
	Delete,
	Get,
	Param,
	ParseUUIDPipe,
	Post,
} from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { CreateEquipoDocumentoDto } from './dto/create-equipo-documento.dto';
import { EquipoDocumentosService } from './equipo-documentos.service';

@Controller('equipos/:equipoId/documentos')
export class EquipoDocumentosController {
	constructor(private readonly documentosService: EquipoDocumentosService) {}

	@Get()
	@RequiereDerecho('archivos.equipos.listar')
	findAll(
		@Param('equipoId', ParseUUIDPipe) equipoId: string,
		@CurrentUser() user: AuthUser,
	) {
		return this.documentosService.findByEquipo(equipoId, user);
	}

	@Post()
	@RequiereDerecho('archivos.equipos.modificar')
	create(
		@Param('equipoId', ParseUUIDPipe) equipoId: string,
		@Body() dto: CreateEquipoDocumentoDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.documentosService.create(equipoId, dto, user);
	}

	@Delete(':id')
	@RequiereDerecho('archivos.equipos.modificar')
	remove(
		@Param('equipoId', ParseUUIDPipe) equipoId: string,
		@Param('id', ParseUUIDPipe) id: string,
		@CurrentUser() user: AuthUser,
	) {
		return this.documentosService.remove(equipoId, id, user);
	}
}
