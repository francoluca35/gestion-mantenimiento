import { IsString, MinLength } from 'class-validator';

export class RestablecerClaveDto {
	@IsString()
	@MinLength(2)
	nombreUsuario!: string;

	@IsString()
	@MinLength(4)
	codigo!: string;

	@IsString()
	@MinLength(6)
	claveNueva!: string;
}
