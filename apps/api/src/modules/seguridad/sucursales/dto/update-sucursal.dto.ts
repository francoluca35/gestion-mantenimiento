import { IsBoolean, IsOptional, IsString, MinLength, ValidateIf } from 'class-validator';

export class UpdateSucursalDto {
	@IsOptional()
	@IsString()
	@MinLength(2)
	nombre?: string;

	@IsOptional()
	@IsBoolean()
	activa?: boolean;

	@IsOptional()
	@ValidateIf((_, value) => value !== null)
	@IsString()
	logoKey?: string | null;

	@IsOptional()
	@ValidateIf((_, value) => value !== null)
	@IsString()
	logoUrl?: string | null;
}
