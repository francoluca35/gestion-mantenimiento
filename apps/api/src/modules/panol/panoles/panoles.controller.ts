import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { CreatePanolDto, UpdatePanolDto } from './dto/panol.dto';
import { PanolesService } from './panoles.service';

@Controller('panoles')
export class PanolesController {
	constructor(private readonly panolesService: PanolesService) {}

	@Get()
	@RequiereDerecho('stock.materiales_en_stock.ver')
	findAll(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
	) {
		return this.panolesService.findAll(user, sucursalId);
	}

	@Post()
	@RequiereDerecho('stock.materiales_en_stock.modificar_valores_gestion')
	create(@Body() dto: CreatePanolDto, @CurrentUser() user: AuthUser) {
		return this.panolesService.create(dto, user);
	}

	@Patch(':id')
	@RequiereDerecho('stock.materiales_en_stock.modificar_valores_gestion')
	update(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdatePanolDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.panolesService.update(id, dto, user);
	}
}
