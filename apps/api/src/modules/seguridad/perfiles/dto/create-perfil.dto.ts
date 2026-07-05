import { IsOptional, IsString, MinLength } from 'class-validator';

export class CreatePerfilDto {
	@IsString()
	@MinLength(2)
	nombre!: string;

	@IsOptional()
	@IsString()
	descripcion?: string;
}
