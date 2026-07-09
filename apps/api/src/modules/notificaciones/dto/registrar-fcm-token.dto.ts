import { IsNotEmpty, IsString } from 'class-validator';

export class RegistrarFcmTokenDto {
	@IsString()
	@IsNotEmpty()
	token!: string;
}

