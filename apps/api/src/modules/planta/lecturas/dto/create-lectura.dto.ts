import { IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateLecturaDto {
	@IsString()
	@MinLength(1)
	tipo!: string;

	@IsNumber()
	valor!: number;

	@IsOptional()
	@IsString()
	notas?: string;
}
