import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { CreateMovimientoDto, UpdateStockDto } from './dto/stock.dto';
import { StockService } from './stock.service';

@Controller('stock')
export class StockController {
	constructor(private readonly stockService: StockService) {}

	@Get()
	@RequiereDerecho('stock.materiales_en_stock.ver')
	findAll(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('panolId') panolId?: string,
		@Query('q') q?: string,
	) {
		return this.stockService.findAll(user, { sucursalId, panolId, q });
	}

	@Get('movimientos')
	@RequiereDerecho('stock.materiales_en_stock.ver')
	movimientos(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('panolId') panolId?: string,
		@Query('materialId') materialId?: string,
	) {
		return this.stockService.listMovimientos(user, {
			sucursalId,
			panolId,
			materialId,
		});
	}

	@Get('alertas')
	@RequiereDerecho('stock.pañol.alertas_stock_minimo.ver')
	alertas(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('panolId') panolId?: string,
	) {
		return this.stockService.listAlertas(user, { sucursalId, panolId });
	}

	@Patch(':id')
	@RequiereDerecho('stock.materiales_en_stock.modificar_valores_gestion')
	update(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdateStockDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.stockService.updateItem(id, dto, user);
	}

	@Post('movimientos')
	@RequiereDerecho('stock.materiales_en_stock.modificar_valores_gestion')
	movimiento(@Body() dto: CreateMovimientoDto, @CurrentUser() user: AuthUser) {
		return this.stockService.registrarMovimiento(dto, user);
	}
}
