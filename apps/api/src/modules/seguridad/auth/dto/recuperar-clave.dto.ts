import { IsString, MinLength } from 'class-validator';

export class RecuperarClaveDto {
	@IsString()
	@MinLength(2)
	nombreUsuario!: string;
}
