import { IsString, Matches, MinLength } from 'class-validator';

export class CreateSucursalDto {
	@IsString()
	@MinLength(2)
	nombre!: string;

	@IsString()
	@Matches(/^[A-Z0-9_-]+$/)
	codigo!: string;
}
