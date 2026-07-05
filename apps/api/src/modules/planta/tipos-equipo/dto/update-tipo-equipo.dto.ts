import { IsArray, IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateTipoEquipoDto {
	@IsOptional()
	@IsString()
	@MinLength(2)
	nombre?: string;

	@IsOptional()
	@IsArray()
	camposDetalle?: unknown[];

	@IsOptional()
	@IsArray()
	camposLectura?: unknown[];

	@IsOptional()
	@IsBoolean()
	activo?: boolean;
}
