import { IsArray, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateTipoEquipoDto {
	@IsString()
	@MinLength(2)
	nombre!: string;

	@IsOptional()
	@IsArray()
	camposDetalle?: unknown[];

	@IsOptional()
	@IsArray()
	camposLectura?: unknown[];
}
