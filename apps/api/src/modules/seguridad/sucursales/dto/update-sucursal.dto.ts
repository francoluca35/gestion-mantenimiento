import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateSucursalDto {
	@IsOptional()
	@IsString()
	@MinLength(2)
	nombre?: string;

	@IsOptional()
	@IsBoolean()
	activa?: boolean;
}
