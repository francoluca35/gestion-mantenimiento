import {
	Body,
	Controller,
	Delete,
	Get,
	Param,
	ParseUUIDPipe,
	Patch,
	Post,
	Put,
} from '@nestjs/common';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import { CreatePerfilDto } from './dto/create-perfil.dto';
import { UpdatePerfilDerechosDto } from './dto/update-perfil-derechos.dto';
import { UpdatePerfilDto } from './dto/update-perfil.dto';
import { PerfilesService } from './perfiles.service';

@Controller('perfiles')
export class PerfilesController {
	constructor(private readonly perfilesService: PerfilesService) {}

	@Get()
	@RequiereDerecho('configuracion.perfiles.listar')
	findAll() {
		return this.perfilesService.findAll();
	}

	@Get(':id')
	@RequiereDerecho('configuracion.perfiles.listar')
	findOne(@Param('id', ParseUUIDPipe) id: string) {
		return this.perfilesService.findOne(id);
	}

	@Post()
	@RequiereDerecho('configuracion.perfiles.agregar')
	create(@Body() dto: CreatePerfilDto) {
		return this.perfilesService.create(dto);
	}

	@Patch(':id')
	@RequiereDerecho('configuracion.perfiles.modificar')
	update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePerfilDto) {
		return this.perfilesService.update(id, dto);
	}

	@Delete(':id')
	@RequiereDerecho('configuracion.perfiles.borrar')
	remove(@Param('id', ParseUUIDPipe) id: string) {
		return this.perfilesService.remove(id);
	}

	@Get(':id/derechos')
	@RequiereDerecho('configuracion.perfiles.definir_derechos')
	getDerechos(@Param('id', ParseUUIDPipe) id: string) {
		return this.perfilesService.getDerechos(id);
	}

	@Put(':id/derechos')
	@RequiereDerecho('configuracion.perfiles.definir_derechos')
	updateDerechos(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdatePerfilDerechosDto,
	) {
		return this.perfilesService.updateDerechos(id, dto);
	}
}
