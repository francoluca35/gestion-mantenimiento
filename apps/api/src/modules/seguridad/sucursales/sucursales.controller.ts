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
import type { AuthUser } from '../auth/auth.types';
import { CreateSucursalDto } from './dto/create-sucursal.dto';
import { UpdateSucursalDto } from './dto/update-sucursal.dto';
import { SucursalesService } from './sucursales.service';

@Controller('sucursales')
export class SucursalesController {
	constructor(private readonly sucursalesService: SucursalesService) {}

	@Get()
	findAll(@CurrentUser() user: AuthUser) {
		return this.sucursalesService.findAll(user);
	}

	@Get(':id')
	findOne(@Param('id', ParseUUIDPipe) id: string) {
		return this.sucursalesService.findOne(id);
	}

	@Post()
	@RequiereDerecho('configuracion.sucursales.agregar')
	create(@Body() dto: CreateSucursalDto) {
		return this.sucursalesService.create(dto);
	}

	@Patch(':id')
	@RequiereDerecho('configuracion.sucursales.agregar')
	update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateSucursalDto) {
		return this.sucursalesService.update(id, dto);
	}

	@Delete(':id')
	@RequiereDerecho('configuracion.sucursales.borrar')
	remove(@Param('id', ParseUUIDPipe) id: string) {
		return this.sucursalesService.remove(id);
	}
}
