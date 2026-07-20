import { IsEnum, IsNumber, IsOptional, IsString, IsUUID, Min } from 'class-validator';
import { EstadoPedidoStock } from '@prisma/client';

export class CreatePedidoStockDto {
	@IsUUID()
	panolId!: string;

	@IsUUID()
	materialId!: string;

	@IsNumber()
	@Min(0.01)
	cantidad!: number;

	@IsOptional()
	@IsString()
	notas?: string;
}

export class UpdatePedidoStockDto {
	@IsEnum(EstadoPedidoStock)
	estado!: EstadoPedidoStock;

	@IsOptional()
	@IsString()
	notas?: string;
}
