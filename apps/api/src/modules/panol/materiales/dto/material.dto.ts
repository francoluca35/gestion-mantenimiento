import {
	IsBoolean,
	IsNumber,
	IsOptional,
	IsString,
	IsUUID,
	MaxLength,
	Min,
} from 'class-validator';

export class CreateMaterialDto {
	@IsString()
	@MaxLength(50)
	codigo!: string;

	@IsString()
	@MaxLength(200)
	nombre!: string;

	@IsOptional()
	@IsString()
	@MaxLength(100)
	marca?: string;

	@IsOptional()
	@IsString()
	@MaxLength(50)
	uso?: string;

	@IsUUID()
	unidadId!: string;

	@IsOptional()
	@IsNumber()
	@Min(0)
	precioActual?: number;

	/** Si se informa, crea también el ítem de stock en ese pañol. */
	@IsOptional()
	@IsUUID()
	panolId?: string;

	@IsOptional()
	@IsNumber()
	@Min(0)
	cantidadActual?: number;

	@IsOptional()
	@IsNumber()
	@Min(0)
	cantidadMinima?: number;
}

export class UpdateMaterialDto {
	@IsOptional()
	@IsString()
	@MaxLength(50)
	codigo?: string;

	@IsOptional()
	@IsString()
	@MaxLength(200)
	nombre?: string;

	@IsOptional()
	@IsString()
	@MaxLength(100)
	marca?: string;

	@IsOptional()
	@IsString()
	@MaxLength(50)
	uso?: string;

	@IsOptional()
	@IsUUID()
	unidadId?: string;

	@IsOptional()
	@IsNumber()
	@Min(0)
	precioActual?: number;

	@IsOptional()
	@IsBoolean()
	activo?: boolean;
}
