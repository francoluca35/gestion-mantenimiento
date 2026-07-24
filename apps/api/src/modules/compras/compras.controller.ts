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
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../seguridad/auth/auth.types';
import { ComprasService } from './compras.service';
import {
	CambiarEstadoOcDto,
	CreateOrdenCompraDto,
	CreateProveedorDto,
	UpdateProveedorDto,
} from './dto/compras.dto';

@Controller()
export class ComprasController {
	constructor(private readonly compras: ComprasService) {}

	@Get('proveedores')
	@RequiereDerecho('stock.ordenes_compra.buscar_y_actualizar')
	listProveedores(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('q') q?: string,
	) {
		return this.compras.listProveedores(user, sucursalId, q);
	}

	@Post('proveedores')
	@RequiereDerecho('stock.ordenes_compra.emitir')
	createProveedor(
		@CurrentUser() user: AuthUser,
		@Body() dto: CreateProveedorDto,
	) {
		return this.compras.createProveedor(user, dto);
	}

	@Patch('proveedores/:id')
	@RequiereDerecho('stock.ordenes_compra.emitir')
	updateProveedor(
		@CurrentUser() user: AuthUser,
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdateProveedorDto,
	) {
		return this.compras.updateProveedor(user, id, dto);
	}

	@Get('ordenes-compra')
	@RequiereDerecho('stock.ordenes_compra.buscar_y_actualizar')
	listOc(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('estado') estado?: string,
	) {
		return this.compras.listOrdenes(user, { sucursalId, estado });
	}

	@Post('ordenes-compra')
	@RequiereDerecho('stock.ordenes_compra.emitir')
	createOc(@CurrentUser() user: AuthUser, @Body() dto: CreateOrdenCompraDto) {
		return this.compras.createOrden(user, dto);
	}

	@Patch('ordenes-compra/:id/estado')
	@RequiereDerecho('stock.ordenes_compra.buscar_y_actualizar')
	cambiarEstado(
		@CurrentUser() user: AuthUser,
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: CambiarEstadoOcDto,
	) {
		return this.compras.cambiarEstado(user, id, dto);
	}
}
