import { IsString, MinLength } from 'class-validator';

export class LoginDto {
	@IsString()
	@MinLength(2)
	nombreUsuario!: string;

	@IsString()
	@MinLength(4)
	clave!: string;
}
