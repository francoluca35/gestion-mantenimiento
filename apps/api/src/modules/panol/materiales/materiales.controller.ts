import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { CreateMaterialDto, UpdateMaterialDto } from './dto/material.dto';
import { MaterialesService } from './materiales.service';

@Controller('materiales')
export class MaterialesController {
	constructor(private readonly materialesService: MaterialesService) {}

	@Get('unidades')
	@RequiereDerecho('stock.materiales_en_stock.ver')
	unidades() {
		return this.materialesService.findUnidades();
	}

	@Get()
	@RequiereDerecho('stock.materiales_en_stock.ver')
	findAll(@Query('q') q?: string) {
		return this.materialesService.findAll(q);
	}

	@Post()
	@RequiereDerecho('stock.materiales_en_stock.modificar_valores_gestion')
	create(@Body() dto: CreateMaterialDto, @CurrentUser() user: AuthUser) {
		return this.materialesService.create(dto, user);
	}

	@Patch(':id')
	@RequiereDerecho('stock.materiales_en_stock.modificar_valores_gestion')
	update(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdateMaterialDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.materialesService.update(id, dto, user);
	}
}
