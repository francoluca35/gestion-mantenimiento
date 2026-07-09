import { IsString, MinLength } from 'class-validator';

export class CambiarClaveDto {
	@IsString()
	@MinLength(6)
	claveActual!: string;

	@IsString()
	@MinLength(6)
	claveNueva!: string;
}
