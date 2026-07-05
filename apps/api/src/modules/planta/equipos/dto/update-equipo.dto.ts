import { IsBoolean, IsObject, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateEquipoDto {
	@IsOptional()
	@IsString()
	@MinLength(2)
	nombre?: string;

	@IsOptional()
	@IsString()
	@MinLength(1)
	codigo?: string;

	@IsOptional()
	@IsObject()
	detalle?: Record<string, unknown>;

	@IsOptional()
	@IsBoolean()
	activo?: boolean;
}
