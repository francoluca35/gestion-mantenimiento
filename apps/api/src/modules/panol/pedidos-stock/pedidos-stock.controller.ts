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
import { CreatePedidoStockDto, UpdatePedidoStockDto } from './dto/pedido-stock.dto';
import { PedidosStockService } from './pedidos-stock.service';

@Controller('pedidos-stock')
export class PedidosStockController {
	constructor(private readonly service: PedidosStockService) {}

	@Get()
	@RequiereDerecho('stock.materiales_en_stock.ver')
	findAll(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('panolId') panolId?: string,
		@Query('estado') estado?: string,
	) {
		return this.service.findAll(user, { sucursalId, panolId, estado });
	}

	@Post()
	@RequiereDerecho('stock.materiales_en_stock.modificar_valores_gestion')
	create(@Body() dto: CreatePedidoStockDto, @CurrentUser() user: AuthUser) {
		return this.service.create(dto, user);
	}

	@Patch(':id')
	@RequiereDerecho('stock.materiales_en_stock.modificar_valores_gestion')
	update(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdatePedidoStockDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.service.update(id, dto, user);
	}
}
