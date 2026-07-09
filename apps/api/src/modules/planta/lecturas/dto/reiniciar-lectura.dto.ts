import { IsNumber, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class ReiniciarLecturaDto {
	@IsString()
	@MinLength(1)
	tipo!: string;

	@IsOptional()
	@IsNumber()
	@Min(0)
	valor?: number;

	@IsOptional()
	@IsString()
	notas?: string;
}
