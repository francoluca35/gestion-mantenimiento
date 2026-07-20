import { IsBoolean, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreatePanolDto {
	@IsString()
	@MaxLength(100)
	nombre!: string;

	@IsOptional()
	@IsUUID()
	sucursalId?: string;
}

export class UpdatePanolDto {
	@IsOptional()
	@IsString()
	@MaxLength(100)
	nombre?: string;

	@IsOptional()
	@IsBoolean()
	activo?: boolean;
}
