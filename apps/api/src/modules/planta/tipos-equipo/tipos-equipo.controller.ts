import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post } from '@nestjs/common';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import { CreateTipoEquipoDto } from './dto/create-tipo-equipo.dto';
import { UpdateTipoEquipoDto } from './dto/update-tipo-equipo.dto';
import { TiposEquipoService } from './tipos-equipo.service';

@Controller('tipos-equipo')
export class TiposEquipoController {
	constructor(private readonly tiposEquipoService: TiposEquipoService) {}

	@Get()
	@RequiereDerecho('archivos.equipos.listar')
	findAll() {
		return this.tiposEquipoService.findAll();
	}

	@Get(':id')
	@RequiereDerecho('archivos.equipos.listar')
	findOne(@Param('id', ParseUUIDPipe) id: string) {
		return this.tiposEquipoService.findOne(id);
	}

	@Post()
	@RequiereDerecho('archivos.tipos_equipo.agregar')
	create(@Body() dto: CreateTipoEquipoDto) {
		return this.tiposEquipoService.create(dto);
	}

	@Patch(':id')
	@RequiereDerecho('archivos.tipos_equipo.modificar')
	update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateTipoEquipoDto) {
		return this.tiposEquipoService.update(id, dto);
	}
}
