import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdatePerfilDto {
	@IsOptional()
	@IsString()
	@MinLength(2)
	nombre?: string;

	@IsOptional()
	@IsString()
	descripcion?: string;

	@IsOptional()
	@IsBoolean()
	activo?: boolean;
}
