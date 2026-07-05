import { IsObject, IsOptional, IsString, IsUUID, MinLength } from 'class-validator';

export class CreateEquipoDto {
	@IsOptional()
	@IsUUID()
	sucursalId?: string;

	@IsUUID()
	ubicacionId!: string;

	@IsUUID()
	tipoEquipoId!: string;

	@IsString()
	@MinLength(2)
	nombre!: string;

	@IsString()
	@MinLength(1)
	codigo!: string;

	@IsOptional()
	@IsObject()
	detalle?: Record<string, unknown>;
}
