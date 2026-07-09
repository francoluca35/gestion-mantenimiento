import { IsObject, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateComponenteDto {
	@IsString()
	@MinLength(1)
	nombre!: string;

	@IsOptional()
	@IsString()
	codigo?: string;

	@IsOptional()
	@IsObject()
	detalle?: Record<string, unknown>;
}
