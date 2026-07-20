import { IsEnum, IsNumber, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';
import { TipoMovimientoStock } from '@prisma/client';

export class UpdateStockDto {
	@IsOptional()
	@IsNumber()
	@Min(0)
	cantidadMinima?: number;

	@IsOptional()
	@IsNumber()
	@Min(0)
	cantidadActual?: number;
}

export class CreateMovimientoDto {
	@IsUUID()
	panolId!: string;

	@IsUUID()
	materialId!: string;

	@IsEnum(TipoMovimientoStock)
	tipo!: TipoMovimientoStock;

	@IsNumber()
	@Min(0.01)
	cantidad!: number;

	@IsOptional()
	@IsUUID()
	otId?: string;

	@IsOptional()
	@IsString()
	@MaxLength(50)
	origen?: string;

	@IsOptional()
	@IsString()
	notas?: string;
}
