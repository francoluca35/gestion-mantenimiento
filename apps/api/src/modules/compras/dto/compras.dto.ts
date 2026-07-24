import { Type } from 'class-transformer';
import {
	ArrayMinSize,
	IsArray,
	IsNumber,
	IsOptional,
	IsString,
	IsUUID,
	Min,
	MinLength,
	ValidateNested,
} from 'class-validator';

export class CreateProveedorDto {
	@IsString()
	@MinLength(2)
	nombre!: string;

	@IsOptional()
	@IsString()
	cuit?: string;

	@IsOptional()
	@IsString()
	contacto?: string;

	@IsOptional()
	@IsString()
	telefono?: string;

	@IsOptional()
	@IsString()
	email?: string;

	@IsOptional()
	@IsUUID()
	sucursalId?: string;
}

export class UpdateProveedorDto {
	@IsOptional()
	@IsString()
	@MinLength(2)
	nombre?: string;

	@IsOptional()
	@IsString()
	cuit?: string;

	@IsOptional()
	@IsString()
	contacto?: string;

	@IsOptional()
	@IsString()
	telefono?: string;

	@IsOptional()
	@IsString()
	email?: string;

	@IsOptional()
	activo?: boolean;
}

export class OrdenCompraLineaDto {
	@IsUUID()
	materialId!: string;

	@IsNumber()
	@Min(0.01)
	cantidad!: number;

	@IsNumber()
	@Min(0)
	precioUnitario!: number;
}

export class CreateOrdenCompraDto {
	@IsUUID()
	proveedorId!: string;

	@IsOptional()
	@IsUUID()
	sucursalId?: string;

	@IsOptional()
	@IsString()
	notas?: string;

	@IsArray()
	@ArrayMinSize(1)
	@ValidateNested({ each: true })
	@Type(() => OrdenCompraLineaDto)
	lineas!: OrdenCompraLineaDto[];
}

export class CambiarEstadoOcDto {
	@IsString()
	estado!: 'autorizada' | 'no_autorizada' | 'anulada' | 'recibida';

	@IsOptional()
	@IsString()
	notas?: string;
}
